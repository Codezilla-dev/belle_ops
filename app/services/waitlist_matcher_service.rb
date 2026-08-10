# frozen_string_literal: true

# Who could we put into this hole?
#
# Deliberately simple and explainable — the coordinator has to be able to look at
# a suggestion and see why it was made:
#
#   1. Rule out anyone whose stated preference doesn't fit the window. Sending a
#      CHW to someone who said "mornings only" at 3pm just books a second failure.
#   2. Reachable people first. Urgency can't beat geography: if the drive is
#      longer than the gap the CHW actually has, they won't make it, and booking
#      it wrecks the rest of the route. Unreachable candidates are still shown,
#      flagged, at the bottom — that's a judgement call for a human, not a
#      silent exclusion.
#   3. Then clinically urgent members. A clinician flagged them for a reason.
#   4. Then nearest to where the CHW already is, so the day's driving doesn't grow.
#   5. Then longest waiting, so nobody quietly rots on the list.
#
# There is no route optimisation here and it isn't pretending to be one.
class WaitlistMatcherService
  Candidate = Data.define(:request, :distance_km, :drive_minutes, :reachable, :reasons) do
    def member = request.member
  end

  def initialize(requests = RescheduleRequest.waiting_list.includes(:member))
    @requests = requests.to_a
  end

  # Best candidates for a slot, best first.
  def candidates_for(slot, limit: 3)
    eligible(slot).sort_by { |request| sort_key(request, slot) }
                  .first(limit)
                  .map { |request| build_candidate(request, slot) }
  end

  def best_for(slot)
    candidates_for(slot, limit: 1).first
  end

  # Slot suggestions for every open slot at once, keyed by slot id.
  def suggestions_for(slots)
    slots.index_by(&:id).transform_values { |slot| candidates_for(slot) }
  end

  private

  attr_reader :requests

  def eligible(slot)
    requests.select { |request| request.waiting? && request.accepts_timeframe?(slot.timeframe) }
  end

  def sort_key(request, slot)
    [
      reachable?(request, slot) ? 0 : 1,
      request.priority_high? ? 0 : 1,
      distance_km(request, slot) || Float::INFINITY,
      request.requested_at
    ]
  end

  def reachable?(request, slot)
    request.member.estimated_drive_minutes_to(slot.anchor) <= slot.slack_minutes
  end

  def build_candidate(request, slot)
    km = distance_km(request, slot)
    drive_minutes = request.member.estimated_drive_minutes_to(slot.anchor)
    reachable = drive_minutes <= slot.slack_minutes

    Candidate.new(
      request: request,
      distance_km: km&.round(1),
      drive_minutes: drive_minutes,
      reachable: reachable,
      reasons: reasons_for(request, slot, km, reachable)
    )
  end

  # Short human-readable justifications, shown next to the suggestion so the
  # coordinator isn't asked to trust a black box.
  def reasons_for(request, slot, km, reachable)
    reasons = []
    reasons << "Clinically urgent" if request.priority_high?
    reasons << "#{km.round(1)} km from the cancelled stop" if km
    reasons << "Waiting #{request.days_waiting} days" if request.days_waiting >= 2
    reasons << "Prefers #{request.preferred_timeframe}" unless request.prefers_any?
    unless reachable
      reasons << "Too far — needs #{request.member.estimated_drive_minutes_to(slot.anchor)} min " \
                 "but the CHW only has #{slot.slack_minutes} min of slack"
    end
    reasons
  end

  def distance_km(request, slot)
    request.member.distance_km_to(slot.anchor)
  end
end

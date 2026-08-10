# frozen_string_literal: true

# Who could we put into this hole?
#
# Deliberately simple and explainable — the coordinator has to be able to look at
# a suggestion and see why it was made:
#
#   1. People whose stated preference fits the window. Sending a CHW to someone
#      who said "mornings only" at 3pm just books a second failure.
#   2. Reachable people. Urgency can't beat geography: if the drive is longer
#      than the gap the CHW actually has, they won't make it, and booking it
#      wrecks the rest of the route.
#   3. Then clinically urgent members. A clinician flagged them for a reason.
#   4. Then nearest to where the CHW already is, so the day's driving doesn't grow.
#   5. Then longest waiting, so nobody quietly rots on the list.
#
# Nothing is ever filtered out — everyone still waiting is ranked and returned,
# with the reasons they're a poor fit spelled out. The coordinator knows things
# the data doesn't, so the tool's job is to order and explain, not to withhold.
#
# There is no route optimisation here and it isn't pretending to be one.
class WaitlistMatcherService
  Candidate = Data.define(
    :request, :distance_km, :drive_minutes, :reachable, :timeframe_match, :reasons, :warnings
  ) do
    def member = request.member

    # Something we'd actively put forward, as opposed to merely allow.
    def recommended = reachable && timeframe_match
  end

  def initialize(requests = RescheduleRequest.waiting_list.includes(:member))
    @requests = requests.to_a
  end

  # Everyone still waiting, ranked for this slot, best first. The coordinator
  # gets the whole list rather than a shortlist: they know things the data
  # doesn't ("her daughter's there on Tuesdays"), and a tool that only offers
  # three names forces them out to a spreadsheet to override it.
  def candidates_for(slot, limit: nil)
    ranked = waiting.sort_by { |request| sort_key(request, slot) }
                    .map { |request| build_candidate(request, slot) }

    limit ? ranked.first(limit) : ranked
  end

  # The one we'd put our name to — fits the window and is actually reachable.
  # Nil is a real answer: it means today has nothing for anybody.
  def best_for(slot)
    candidates_for(slot).find(&:recommended)
  end

  # Slot suggestions for every open slot at once, keyed by slot id.
  def suggestions_for(slots)
    slots.index_by(&:id).transform_values { |slot| candidates_for(slot) }
  end

  private

  attr_reader :requests

  def waiting
    requests.select(&:waiting?)
  end

  # Recommended candidates come first, then near-misses, so scanning the list
  # top-down still walks from best to worst.
  def sort_key(request, slot)
    [
      request.accepts_timeframe?(slot.timeframe) ? 0 : 1,
      reachable?(request, slot) ? 0 : 1,
      request.priority_high? ? 0 : 1,
      distance_km(request, slot) || Float::INFINITY,
      request.requested_at
    ]
  end

  def reachable?(request, slot)
    request.member.estimated_drive_minutes_to(slot.anchor) <= slot.drive_budget_minutes
  end

  def build_candidate(request, slot)
    km = distance_km(request, slot)
    drive_minutes = request.member.estimated_drive_minutes_to(slot.anchor)
    reachable = drive_minutes <= slot.drive_budget_minutes
    timeframe_match = request.accepts_timeframe?(slot.timeframe)

    Candidate.new(
      request: request,
      distance_km: km&.round(1),
      drive_minutes: drive_minutes,
      reachable: reachable,
      timeframe_match: timeframe_match,
      reasons: reasons_for(request, km),
      warnings: warnings_for(request, slot, drive_minutes, reachable, timeframe_match)
    )
  end

  # Short human-readable justifications, shown next to the suggestion so the
  # coordinator isn't asked to trust a black box.
  def reasons_for(request, km)
    reasons = []
    reasons << "Clinically urgent" if request.priority_high?
    reasons << "#{km.round(1)} km from the cancelled stop" if km
    reasons << "Waiting #{request.days_waiting} days" if request.days_waiting >= 2
    reasons << "Prefers #{request.preferred_timeframe}" unless request.prefers_any?
    reasons
  end

  # Why this would be a stretch. Stated plainly so overriding is a decision
  # rather than an accident.
  def warnings_for(request, slot, drive_minutes, reachable, timeframe_match)
    warnings = []

    unless timeframe_match
      warnings << "Asked for #{request.preferred_timeframe} — this slot is #{slot.timeframe}"
    end

    unless reachable
      warnings << "Roughly #{drive_minutes} min drive, and the CHW only has " \
                  "#{slot.drive_budget_minutes} min before they run late"
    end

    warnings << "#{request.member.prior_no_shows} prior no-shows" if request.member.no_show_risk?
    warnings
  end

  def distance_km(request, slot)
    request.member.distance_km_to(slot.anchor)
  end
end

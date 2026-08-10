# frozen_string_literal: true

# The waiting list, plus where each person could go today.
#
# The list is shared rather than split per CHW: a waiting member belongs to
# nobody until they are actually placed, and pretending otherwise would invent
# an assignment that doesn't exist. The per-CHW view of this data is the
# suggestion attached to each open slot on the calendar.
class WaitlistPresenter
  def initialize(requests: RescheduleRequest.waiting_list.includes(:member).by_urgency, slots: [])
    @requests = requests.to_a
    @slots = slots
    @matcher = WaitlistMatcherService.new(@requests)
  end

  def as_props
    requests.map { |request| request_props(request) }
  end

  private

  attr_reader :requests, :slots, :matcher

  def request_props(request)
    placement = best_placement(request)

    {
      id: request.id,
      request_id: request.request_id,
      member_name: request.member.name,
      member_age: request.member.age,
      prior_no_shows: request.member.prior_no_shows,
      no_show_risk: request.member.no_show_risk?,
      address: request.member.full_address,
      preferred_timeframe: request.preferred_timeframe,
      reason: request.reason,
      clinical_priority: request.clinical_priority,
      days_waiting: request.days_waiting,
      # Nil when nothing on today's board fits — that's the honest answer, and
      # it tells the coordinator this person needs a slot on another day.
      placement: placement
    }
  end

  # The single best open slot for this person today, if any: one they can be
  # driven to in the time available, nearest first.
  def best_placement(request)
    slot = slots.select { |s| request.accepts_timeframe?(s.timeframe) }
                .select { |s| request.member.estimated_drive_minutes_to(s.anchor) <= s.drive_budget_minutes }
                .min_by { |s| request.member.distance_km_to(s.anchor) || Float::INFINITY }
    return nil if slot.nil?

    {
      slot_id: slot.id,
      technician_name: slot.technician.name,
      time_label: slot.starts_at.in_time_zone(Belle::CURRENT_TIME.time_zone).strftime("%-l:%M %p"),
      distance_km: request.member.distance_km_to(slot.anchor)&.round(1)
    }
  end
end

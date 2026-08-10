# frozen_string_literal: true

# Shapes a single visit for the calendar and its detail modal.
#
# The React side does no date maths and no business logic: it gets pre-formatted
# times, a grid offset in minutes, and plain booleans.
class VisitPresenter
  def initialize(visit)
    @visit = visit
  end

  def as_props
    {
      id: visit.id,
      appointment_id: visit.appointment_id,
      member_name: visit.member.name,
      member_age: visit.member.age,
      prior_no_shows: visit.member.prior_no_shows,
      no_show_risk: visit.member.no_show_risk?,
      address: visit.member.full_address,
      household_shared: visit.member.household_members.exists?,
      visit_type: visit.visit_type,
      status: visit.status,
      confirmation_status: visit.confirmation_status,
      starts_at: local(visit.scheduled_start).iso8601,
      ends_at: local(visit.scheduled_end).iso8601,
      time_label: "#{time_of_day(visit.scheduled_start)} – #{time_of_day(visit.scheduled_end)}",
      # Grid geometry: minutes from the left edge of the calendar, and length.
      offset_minutes: offset_minutes,
      duration_minutes: visit.duration_minutes,
      drive_minutes: visit.drive_minutes_from_prev,
      drive_avoided: visit.drive_avoided?,
      past: visit.past?,
      backfill: visit.backfill?,
      reminder_sent_at: visit.reminder_sent_at && time_of_day(visit.reminder_sent_at),
      reminder_response: visit.reminder_response,
      cancellation: cancellation_props
    }
  end

  private

  attr_reader :visit

  def cancellation_props
    return nil unless visit.fell_through?

    {
      reason: visit.cancellation_reason,
      channel: visit.cancellation_channel,
      cancelled_by: visit.cancelled_by,
      cancelled_at: visit.cancelled_at && local(visit.cancelled_at).strftime("%-l:%M %p on %-m/%-d"),
      drive_avoided: visit.drive_avoided?,
      drive_minutes: visit.drive_minutes_from_prev
    }
  end

  def offset_minutes
    day_opens = local(visit.scheduled_start).change(hour: Belle::DAY_START_HOUR)
    ((local(visit.scheduled_start) - day_opens) / 60).round
  end

  def time_of_day(time)
    local(time).strftime("%-l:%M %p")
  end

  def local(time)
    time.in_time_zone(Belle::CURRENT_TIME.time_zone)
  end
end

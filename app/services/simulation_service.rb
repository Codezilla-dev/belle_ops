# frozen_string_literal: true

# Stands in for the feeds a real deployment would have — the SMS gateway, the
# IVR, the CHW's phone, the intake queue — so you can watch the board react to
# the day changing under you.
#
# Each call applies exactly one plausible event. Event types that have nothing
# to act on are skipped rather than faked, so the simulation can't invent a
# cancellation for a visit that already happened.
class SimulationService
  Event = Data.define(:type, :message)

  EVENT_TYPES = %i[member_confirms member_cancels_by_text no_show_at_the_door new_request].freeze

  # Names for members who "call in" during the simulation. Real intake would
  # bring a real person; this keeps the demo honest about where they came from.
  WALK_INS = [
    { name: "Odell J.", age: 78, lat: 32.845, lng: -83.640, line1: "18 Vineville Ave", zip: "31204" },
    { name: "Bessie L.", age: 84, lat: 32.910, lng: -83.700, line1: "44 Bass Rd", zip: "31210" },
    { name: "Horace W.", age: 81, lat: 32.800, lng: -83.670, line1: "91 Houston Ave", zip: "31206" },
    { name: "Lorraine D.", age: 87, lat: 32.930, lng: -83.725, line1: "7 Tucker Rd", zip: "31220" },
    { name: "Clyde M.", age: 75, lat: 32.600, lng: -83.655, line1: "12 Watson Blvd", zip: "31088" }
  ].freeze

  def self.next_event!(type: nil)
    new.next_event!(type: type)
  end

  # Applies one event and returns it, or nil if nothing could happen.
  def next_event!(type: nil)
    candidates = type ? [ type ] : EVENT_TYPES.shuffle

    candidates.each do |event_type|
      event = public_send("apply_#{event_type}")
      return event if event
    end

    nil
  end

  # A member finally answers the reminder we sent yesterday.
  def apply_member_confirms
    visit = upcoming.where(confirmation_status: %w[no_reply wants_reschedule]).order(:scheduled_start).first
    return nil if visit.nil?

    visit.update!(confirmation_status: "confirmed", reminder_response: "confirmed")
    Event.new(type: :member_confirms,
              message: "#{visit.member.name} confirmed their #{time_label(visit)} visit.")
  end

  # A text arrives well before the CHW would set off — the trip is saved, and a
  # hole opens in the day.
  def apply_member_cancels_by_text
    visit = upcoming.where("scheduled_start > ?", Belle::CURRENT_TIME + 1.hour).order(:scheduled_start).last
    return nil if visit.nil?

    visit.update!(
      status: "cancelled",
      cancellation_reason: "member_unavailable",
      cancellation_channel: "text",
      cancelled_by: "member",
      cancelled_at: Belle::CURRENT_TIME
    )
    Event.new(type: :member_cancels_by_text,
              message: "#{visit.member.name} cancelled their #{time_label(visit)} visit by text — " \
                       "#{visit.drive_minutes_from_prev} min drive saved.")
  end

  # The expensive kind: the CHW is already at the door.
  def apply_no_show_at_the_door
    visit = upcoming.where(scheduled_start: ..(Belle::CURRENT_TIME + 90.minutes))
                    .order(:scheduled_start).first
    return nil if visit.nil?

    visit.update!(
      status: "no_show",
      cancellation_reason: "no_answer",
      cancellation_channel: "on_site",
      cancelled_by: "technician",
      cancelled_at: visit.scheduled_start + 6.minutes
    )
    Event.new(type: :no_show_at_the_door,
              message: "#{visit.technician.name} got no answer at #{visit.member.name}'s — " \
                       "#{visit.drive_minutes_from_prev} min drive wasted.")
  end

  # Somebody rings the office asking to be seen.
  def apply_new_request
    walk_in = WALK_INS.find { |candidate| !Member.exists?(name: candidate[:name]) }
    return nil if walk_in.nil?

    member = Member.create!(
      name: walk_in[:name], age: walk_in[:age], prior_no_shows: 0,
      address_line1: walk_in[:line1], city: "Macon", state: "GA", zip: walk_in[:zip],
      lat: walk_in[:lat], lng: walk_in[:lng]
    )
    request = RescheduleRequest.create!(
      request_id: "req_sim_#{SecureRandom.hex(3)}",
      member: member,
      requested_at: Belle::CURRENT_DAY,
      preferred_timeframe: "afternoon",
      reason: "member_called",
      clinical_priority: "normal"
    )

    Event.new(type: :new_request,
              message: "#{request.member.name} called in asking for a visit.")
  end

  private

  # Visits we could still plausibly get news about: today, on the books, and not
  # already behind us.
  def upcoming
    Visit.on_day(Belle::CURRENT_DAY)
         .where(status: "scheduled")
         .where("scheduled_start > ?", Belle::CURRENT_TIME)
  end

  def time_label(visit)
    visit.scheduled_start.in_time_zone(Belle::CURRENT_TIME.time_zone).strftime("%-l:%M %p")
  end
end

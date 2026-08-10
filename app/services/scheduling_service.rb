# frozen_string_literal: true

# Puts a waiting member into a slot a cancellation left behind.
#
# The new visit inherits the vacated window and the CHW who was already going to
# be in that area, which is what makes the swap cheap.
class SchedulingService
  class SlotUnavailable < StandardError; end
  class RequestUnavailable < StandardError; end

  def initialize(request:, slot:)
    @request = request
    @slot = slot
  end

  def self.fill!(request:, slot:)
    new(request: request, slot: slot).call
  end

  def call
    raise SlotUnavailable, "That slot has already been filled" unless slot.visit.open_slot?
    raise RequestUnavailable, "#{request.member.name} is no longer waiting" unless request.waiting?

    ActiveRecord::Base.transaction do
      visit = create_visit
      slot.visit.update!(backfilled_by_visit: visit)
      request.update!(status: "scheduled")
      visit
    end
  end

  private

  attr_reader :request, :slot

  def create_visit
    Visit.create!(
      appointment_id: next_appointment_id,
      member: request.member,
      technician: slot.technician,
      scheduled_start: slot.starts_at,
      scheduled_end: slot.ends_at,
      visit_type: "foot_care",
      status: "scheduled",
      # Nobody has spoken to them about *this* window yet, so it starts unconfirmed
      # — it should show up on the coordinator's chase list like any other.
      confirmation_status: "no_reply",
      drive_minutes_from_prev: request.member.estimated_drive_minutes_to(slot.anchor),
      filled_from_request: request
    )
  end

  def next_appointment_id
    "appt_fill_#{SecureRandom.hex(3)}"
  end
end

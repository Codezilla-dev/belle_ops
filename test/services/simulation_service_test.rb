# frozen_string_literal: true

require "test_helper"

class SimulationServiceTest < ActiveSupport::TestCase
  setup do
    @technician = build_technician(name: "Sim CHW")
  end

  test "a confirmation moves an unanswered upcoming visit to confirmed" do
    visit = build_visit(technician: @technician, start_hour: 14, confirmation_status: "no_reply")

    event = SimulationService.next_event!(type: :member_confirms)

    assert_equal :member_confirms, event.type
    assert visit.reload.confirmed?
  end

  test "a text cancellation opens a slot and saves the drive" do
    visit = build_visit(technician: @technician, start_hour: 15, drive_minutes: 14)

    event = SimulationService.next_event!(type: :member_cancels_by_text)
    visit.reload

    assert_equal :member_cancels_by_text, event.type
    assert visit.cancelled?
    assert visit.drive_avoided?
    assert visit.open_slot?
    assert_match(/drive saved/, event.message)
  end

  test "a doorstep no-show opens a slot but spends the drive" do
    visit = build_visit(technician: @technician, start_hour: 13, drive_minutes: 16)

    event = SimulationService.next_event!(type: :no_show_at_the_door)
    visit.reload

    assert_equal :no_show_at_the_door, event.type
    assert visit.no_show?
    assert_not visit.drive_avoided?
    assert_equal 16, visit.drive_minutes_spent
  end

  test "a new request lands on the waitlist" do
    assert_difference [ "RescheduleRequest.count", "Member.count" ], 1 do
      SimulationService.next_event!(type: :new_request)
    end

    assert RescheduleRequest.last.waiting?
  end

  # The simulator must never invent an event it has nothing to apply to.
  test "returns nil when a chosen event type has nothing to act on" do
    assert_nil SimulationService.next_event!(type: :member_confirms)
  end

  test "visits already in the past are left alone" do
    past = build_visit(technician: @technician, start_hour: 9, confirmation_status: "no_reply")

    assert_nil SimulationService.next_event!(type: :member_confirms)
    assert past.reload.no_reply?
  end
end

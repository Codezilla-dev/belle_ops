# frozen_string_literal: true

require "test_helper"

class SchedulingServiceTest < ActiveSupport::TestCase
  setup do
    @technician = build_technician(name: "Fill CHW")
    @cancelled = build_visit(technician: @technician, start_hour: 15, status: "cancelled",
                             member: build_member(name: "Vacated V.", lat: 32.930, lng: -83.700),
                             channel: "text", cancelled_at: day_time(9))
    @slot = OpenSlotsService.new(@technician.visits).slots.first
    @request = build_request(member: build_member(name: "Waiting W.", lat: 32.931, lng: -83.701))
  end

  test "filling a slot books the member into the vacated window with the same CHW" do
    visit = SchedulingService.fill!(request: @request, slot: @slot)

    assert_equal "Waiting W.", visit.member.name
    assert_equal @technician, visit.technician
    assert_equal @cancelled.scheduled_start, visit.scheduled_start
    assert_equal @cancelled.scheduled_end, visit.scheduled_end
    assert visit.scheduled?
    # Nobody has spoken to them about this window yet.
    assert visit.no_reply?
    assert visit.backfill?
  end

  test "filling closes the slot and takes the member off the waitlist" do
    SchedulingService.fill!(request: @request, slot: @slot)

    assert @request.reload.scheduled?
    assert_not @cancelled.reload.open_slot?
    assert_empty OpenSlotsService.new(Visit.all).slots
  end

  test "the same slot cannot be filled twice" do
    SchedulingService.fill!(request: @request, slot: @slot)
    other = build_request(member: build_member(name: "Second S."))

    assert_raises(SchedulingService::SlotUnavailable) do
      SchedulingService.fill!(request: other, slot: @slot)
    end
  end

  test "a member already placed cannot be placed again" do
    SchedulingService.fill!(request: @request, slot: @slot)
    second_cancelled = build_visit(technician: @technician, start_hour: 16, status: "cancelled",
                                   channel: "text", cancelled_at: day_time(9))
    second_slot = OpenSlotsService.new([ second_cancelled ]).slots.first

    assert_raises(SchedulingService::RequestUnavailable) do
      SchedulingService.fill!(request: @request, slot: second_slot)
    end
  end
end

# frozen_string_literal: true

require "test_helper"

class CalendarDayPresenterTest < ActiveSupport::TestCase
  setup do
    @technician = build_technician(name: "Lane CHW")
  end

  def row_for(technician)
    CalendarDayPresenter.new.as_props[:technicians].find { |row| row[:id] == technician.id }
  end

  # An open slot sits in the window the cancelled visit vacated. Both have to be
  # on screen: drawing the slot over the visit makes the row read as though the
  # visit was never scheduled, which is exactly the confusion we're avoiding.
  test "a cancelled visit and the slot it opened get separate lanes" do
    cancelled = build_visit(technician: @technician, start_hour: 15, status: "cancelled",
                            channel: "text", cancelled_at: day_time(9))

    row = row_for(@technician)
    visit = row[:visits].sole
    slot = row[:open_slots].sole

    assert_equal cancelled.id, visit[:id]
    assert_not_equal visit[:lane], slot[:lane]
    assert_equal 2, row[:lane_count]
    # Same window, so they'd sit on top of each other in one lane.
    assert_equal visit[:offset_minutes], slot[:offset_minutes]
  end

  test "the original visit keeps the top lane and the slot goes underneath" do
    build_visit(technician: @technician, start_hour: 15, status: "cancelled",
                channel: "text", cancelled_at: day_time(9))

    row = row_for(@technician)

    assert_equal 0, row[:visits].sole[:lane]
    assert_equal 1, row[:open_slots].sole[:lane]
  end

  test "filling the slot leaves both visits visible and no slot" do
    cancelled = build_visit(technician: @technician, start_hour: 15, status: "cancelled",
                            member: build_member(name: "Gone G.", lat: 32.930, lng: -83.700),
                            channel: "text", cancelled_at: day_time(9))
    request = build_request(member: build_member(name: "Added A.", lat: 32.931, lng: -83.701))
    slot = OpenSlotsService.new([ cancelled ]).slots.sole
    SchedulingService.fill!(request: request, slot: slot)

    row = row_for(@technician)

    assert_empty row[:open_slots]
    assert_equal %w[Added\ A. Gone\ G.], row[:visits].map { |v| v[:member_name] }.sort
    assert_equal [ 0, 1 ], row[:visits].map { |v| v[:lane] }.sort
  end

  test "visits that do not overlap share a single lane" do
    build_visit(technician: @technician, start_hour: 9, status: "completed")
    build_visit(technician: @technician, start_hour: 11, status: "completed")

    assert_equal 1, row_for(@technician)[:lane_count]
  end
end

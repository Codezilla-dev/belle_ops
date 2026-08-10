# frozen_string_literal: true

require "test_helper"

class DriveCostServiceTest < ActiveSupport::TestCase
  setup do
    @technician = build_technician(name: "Cost CHW")
  end

  test "completed visits count their full drive" do
    build_visit(technician: @technician, start_hour: 9, drive_minutes: 12, status: "completed")
    build_visit(technician: @technician, start_hour: 10, drive_minutes: 8, status: "completed")

    cost = DriveCostService.new(@technician.visits).totals

    assert_equal 20, cost.spent_minutes
    assert_equal 0, cost.saved_minutes
    assert_equal 0, cost.wasted_minutes
  end

  test "an early cancellation saves its drive instead of spending it" do
    build_visit(technician: @technician, start_hour: 9, drive_minutes: 12, status: "completed")
    build_visit(technician: @technician, start_hour: 14, drive_minutes: 18, status: "cancelled",
                channel: "voice", cancelled_at: day_time(7, 50))

    cost = DriveCostService.new(@technician.visits).totals

    assert_equal 12, cost.spent_minutes
    assert_equal 18, cost.saved_minutes
    assert_equal 0, cost.wasted_minutes
  end

  test "a trip made for a visit that did not happen is counted as wasted" do
    build_visit(technician: @technician, start_hour: 10, drive_minutes: 22, status: "cancelled",
                channel: "on_site", cancelled_at: day_time(10, 4))

    cost = DriveCostService.new(@technician.visits).totals

    assert_equal 22, cost.spent_minutes
    assert_equal 22, cost.wasted_minutes
    assert_equal 0, cost.saved_minutes
  end

  test "costs are split per CHW" do
    other = build_technician(name: "Other CHW")
    build_visit(technician: @technician, drive_minutes: 10, status: "completed")
    build_visit(technician: other, drive_minutes: 30, status: "completed")

    costs = DriveCostService.new(Visit.all).by_technician

    assert_equal 10, costs[@technician.id].spent_minutes
    assert_equal 30, costs[other.id].spent_minutes
  end
end

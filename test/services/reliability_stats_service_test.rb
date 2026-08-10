# frozen_string_literal: true

require "test_helper"

class ReliabilityStatsServiceTest < ActiveSupport::TestCase
  test "a CHW is only flagged once enough of their day has gone wrong" do
    unlucky = build_technician(name: "Unlucky CHW")
    4.times { |i| build_visit(technician: unlucky, start_hour: 9 + i, status: "completed") }
    2.times do |i|
      build_visit(technician: unlucky, start_hour: 13 + i, status: "no_show",
                  channel: "on_site", cancelled_at: day_time(13 + i, 5))
    end

    stat = ReliabilityStatsService.new.technician_stats.find { |s| s.technician == unlucky }

    assert_equal 6, stat.visits
    assert_equal 2, stat.fell_through
    assert_in_delta 0.33, stat.fell_through_rate, 0.01
    assert_includes ReliabilityStatsService.new.flagged_technicians.map(&:technician), unlucky
  end

  test "a bad morning on a short day is not treated as a pattern" do
    quiet = build_technician(name: "Quiet CHW")
    build_visit(technician: quiet, start_hour: 9, status: "completed")
    build_visit(technician: quiet, start_hour: 10, status: "no_show",
                channel: "on_site", cancelled_at: day_time(10, 5))

    assert_empty ReliabilityStatsService.new.flagged_technicians.map(&:technician)
  end

  test "member rows describe how today actually went" do
    member = build_member(name: "Tracked T.", prior_no_shows: 3)
    build_visit(member: member, status: "no_show", channel: "on_site", cancelled_at: day_time(10, 5))

    stat = ReliabilityStatsService.new.member_stats.find { |s| s.member == member }

    assert_equal 1, stat.no_shows
    assert_equal 1, stat.fell_through
    assert stat.risk?
  end
end

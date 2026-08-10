# frozen_string_literal: true

require "test_helper"

class WaitlistMatcherServiceTest < ActiveSupport::TestCase
  setup do
    @technician = build_technician(name: "Match CHW")
    # An afternoon slot with plenty of slack: the CHW's previous stop ends at
    # 13:45 and the open window starts at 15:00.
    build_visit(technician: @technician, start_hour: 13, status: "completed")
    @cancelled = build_visit(technician: @technician, start_hour: 15, status: "cancelled",
                             member: build_member(name: "Vacated M.", lat: 32.930, lng: -83.700),
                             channel: "text", cancelled_at: day_time(9))
    @slot = OpenSlotsService.new(@technician.visits).slots.first
  end

  test "a member who only wants mornings is not offered an afternoon slot" do
    build_request(timeframe: "morning", member: build_member(name: "Morning Only", lat: 32.931, lng: -83.701))

    # Still offered — the coordinator may know better — but not recommended, and
    # the mismatch is spelled out rather than left for them to spot.
    candidate = WaitlistMatcherService.new.candidates_for(@slot).sole

    assert_equal "Morning Only", candidate.member.name
    assert_not candidate.recommended
    assert_not candidate.timeframe_match
    assert_match(/Asked for morning/, candidate.warnings.join(" "))
    assert_nil WaitlistMatcherService.new.best_for(@slot)
  end

  test "a good fit is recommended and ranked above anyone needing an override" do
    build_request(timeframe: "morning", member: build_member(name: "Wrong Window", lat: 32.9305, lng: -83.7005))
    build_request(timeframe: "afternoon", member: build_member(name: "Right Window", lat: 32.932, lng: -83.703))

    candidates = WaitlistMatcherService.new.candidates_for(@slot)

    assert_equal [ "Right Window", "Wrong Window" ], candidates.map { |c| c.member.name }
    assert candidates.first.recommended
    assert_not candidates.last.recommended
  end

  test "members who say any time are eligible" do
    build_request(timeframe: "any", member: build_member(name: "Anytime A.", lat: 32.931, lng: -83.701))

    assert_equal "Anytime A.", WaitlistMatcherService.new.best_for(@slot).member.name
  end

  test "a clinically urgent member outranks a nearer routine one" do
    build_request(timeframe: "afternoon", priority: "normal",
                  member: build_member(name: "Near N.", lat: 32.9305, lng: -83.7005))
    build_request(timeframe: "afternoon", priority: "high",
                  member: build_member(name: "Urgent U.", lat: 32.934, lng: -83.706))

    assert_equal "Urgent U.", WaitlistMatcherService.new.best_for(@slot).member.name
  end

  # Urgency should not send a CHW somewhere they cannot physically get to in the
  # gap they have — that would just wreck the rest of the route.
  test "an unreachable urgent member ranks below a reachable routine one" do
    build_request(timeframe: "afternoon", priority: "high",
                  member: build_member(name: "Far Urgent", lat: 32.589, lng: -83.661))
    build_request(timeframe: "afternoon", priority: "normal",
                  member: build_member(name: "Close Routine", lat: 32.9305, lng: -83.7005))

    candidates = WaitlistMatcherService.new.candidates_for(@slot)

    assert_equal "Close Routine", candidates.first.member.name
    assert candidates.first.reachable
    assert_not candidates.last.reachable
    assert_match(/only has \d+ min before they run late/, candidates.last.warnings.join(" "))
  end

  test "the nearest member wins among equals" do
    build_request(timeframe: "any", member: build_member(name: "Far F.", lat: 32.960, lng: -83.740))
    build_request(timeframe: "any", member: build_member(name: "Near N.", lat: 32.9305, lng: -83.7005))

    assert_equal "Near N.", WaitlistMatcherService.new.best_for(@slot).member.name
  end
end

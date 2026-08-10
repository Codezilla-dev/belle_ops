# frozen_string_literal: true

require "test_helper"

class VisitTest < ActiveSupport::TestCase
  # The drive-cost rule is the piece of judgment most worth pinning down: it
  # decides whether a fallen-through visit cost us a trip or not.
  test "an on-site cancellation never saves the drive" do
    visit = build_visit(status: "cancelled", start_hour: 10, drive_minutes: 20,
                        channel: "on_site", cancelled_at: day_time(10, 4))

    assert_not visit.drive_avoided?
    assert_equal 20, visit.drive_minutes_spent
  end

  test "a text that lands before the CHW sets off saves the drive" do
    visit = build_visit(status: "cancelled", start_hour: 10, drive_minutes: 20,
                        channel: "text", cancelled_at: day_time(8, 30))

    assert visit.drive_avoided?
    assert_equal 0, visit.drive_minutes_spent
    assert_equal 20, visit.drive_minutes_saved
  end

  test "a text that lands once the CHW is already driving does not save the drive" do
    # Due at 10:00 with a 20 minute drive, so they leave at 09:40.
    visit = build_visit(status: "cancelled", start_hour: 10, drive_minutes: 20,
                        channel: "text", cancelled_at: day_time(9, 50))

    assert_not visit.drive_avoided?
    assert_equal 20, visit.drive_minutes_spent
  end

  test "a no-show costs the full drive" do
    visit = build_visit(status: "no_show", drive_minutes: 16,
                        channel: "on_site", cancelled_at: day_time(11, 36))

    assert visit.fell_through?
    assert_equal 16, visit.drive_minutes_spent
  end

  test "a visit still on the books is not an open slot" do
    assert_not build_visit(status: "scheduled").open_slot?
    assert build_visit(status: "cancelled", channel: "text", cancelled_at: day_time(8)).open_slot?
  end

  test "timeframe splits at local noon" do
    assert_equal "morning", build_visit(start_hour: 11, start_min: 30).timeframe
    assert_equal "afternoon", build_visit(start_hour: 12).timeframe
  end
end

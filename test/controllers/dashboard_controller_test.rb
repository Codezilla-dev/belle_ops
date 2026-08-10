# frozen_string_literal: true

require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  test "the schedule page renders a row per CHW with their visits" do
    technician = build_technician(name: "Page CHW")
    build_visit(technician: technician, member: build_member(name: "Shown S."))

    get root_path

    assert_response :success
    assert_match "Page CHW", response.body
    assert_match "Shown S.", response.body
  end

  test "filling a slot books the member and confirms it to the coordinator" do
    technician = build_technician(name: "Fill CHW")
    build_visit(technician: technician, start_hour: 13, status: "completed")
    cancelled = build_visit(technician: technician, start_hour: 15, status: "cancelled",
                            member: build_member(name: "Gone G.", lat: 32.930, lng: -83.700),
                            channel: "text", cancelled_at: day_time(9))
    waiting = build_request(member: build_member(name: "Next N.", lat: 32.931, lng: -83.701))

    assert_difference "Visit.count", 1 do
      post slot_fills_path, params: { slot_id: cancelled.id, reschedule_request_id: waiting.id }
    end

    assert_redirected_to root_path
    assert_match "Next N.", flash[:notice]
    assert waiting.reload.scheduled?
  end

  test "filling a slot that has already gone tells the coordinator instead of failing" do
    technician = build_technician(name: "Race CHW")
    cancelled = build_visit(technician: technician, start_hour: 15, status: "cancelled",
                            channel: "text", cancelled_at: day_time(9))
    first = build_request(member: build_member(name: "First F."))
    second = build_request(member: build_member(name: "Second S."))

    post slot_fills_path, params: { slot_id: cancelled.id, reschedule_request_id: first.id }

    assert_no_difference "Visit.count" do
      post slot_fills_path, params: { slot_id: cancelled.id, reschedule_request_id: second.id }
    end
    assert_redirected_to root_path
    assert second.reload.waiting?
  end

  test "simulating an event changes the board" do
    technician = build_technician(name: "Sim CHW")
    build_visit(technician: technician, start_hour: 14, confirmation_status: "no_reply")

    post simulation_events_path

    assert_redirected_to root_path
    assert flash[:notice].present?
  end
end

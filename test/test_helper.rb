ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    parallelize(workers: :number_of_processors)

    fixtures :all

    # Small builders so tests can state only the fields they care about. Records
    # land on Belle::CURRENT_DAY by default, since that is the day the whole app
    # reasons about.
    def build_technician(name: "Test CHW")
      Technician.create!(name: name)
    end

    def build_member(name: nil, lat: 32.84, lng: -83.62, prior_no_shows: 0)
      Member.create!(
        name: name || "Member #{SecureRandom.hex(4)}",
        age: 80,
        prior_no_shows: prior_no_shows,
        address_line1: "1 Test St", city: "Macon", state: "GA", zip: "31201",
        lat: lat, lng: lng
      )
    end

    def build_visit(technician: nil, member: nil, start_hour: 10, start_min: 0,
                    drive_minutes: 10, status: "scheduled", confirmation_status: "no_reply",
                    channel: nil, cancelled_at: nil, **extra)
      zone = Belle::CURRENT_TIME.time_zone
      starts_at = zone.local(Belle::CURRENT_DAY.year, Belle::CURRENT_DAY.month,
                             Belle::CURRENT_DAY.day, start_hour, start_min)

      Visit.create!(
        appointment_id: "appt_#{SecureRandom.hex(4)}",
        member: member || build_member,
        technician: technician || build_technician(name: "CHW #{SecureRandom.hex(3)}"),
        scheduled_start: starts_at,
        scheduled_end: starts_at + 45.minutes,
        status: status,
        confirmation_status: confirmation_status,
        drive_minutes_from_prev: drive_minutes,
        cancellation_channel: channel,
        cancelled_at: cancelled_at,
        **extra
      )
    end

    def build_request(member: nil, timeframe: "any", priority: "normal", requested_at: nil)
      RescheduleRequest.create!(
        request_id: "req_#{SecureRandom.hex(4)}",
        member: member || build_member,
        requested_at: requested_at || Belle::CURRENT_DAY - 2,
        preferred_timeframe: timeframe,
        clinical_priority: priority,
        reason: "member_called"
      )
    end

    # A time on the pinned day, for readable assertions.
    def day_time(hour, minute = 0)
      Belle::CURRENT_TIME.time_zone.local(
        Belle::CURRENT_DAY.year, Belle::CURRENT_DAY.month, Belle::CURRENT_DAY.day, hour, minute
      )
    end
  end
end

# frozen_string_literal: true

# Loads the region snapshot in db/data into the database.
#
# Destructive on purpose: re-running `bin/rails db:seed` resets the day, which is
# how you undo a demo (or an over-enthusiastic run of the event simulator).

DATA_DIR = Rails.root.join("db/data")
ZONE = Time.find_zone!("America/New_York")

def read_json(filename)
  JSON.parse(DATA_DIR.join(filename).read)
end

def upsert_member(attrs, household_id: nil)
  member = Member.find_or_initialize_by(name: attrs.fetch("name"))
  address = attrs.fetch("address", {})

  member.update!(
    age: attrs["age"],
    prior_no_shows: attrs["prior_no_shows"] || 0,
    household_id: household_id || member.household_id,
    address_line1: address["line1"],
    city: address["city"],
    state: address["state"],
    zip: address["zip"],
    lat: address["lat"],
    lng: address["lng"],
    timezone: attrs["timezone"] || "America/New_York"
  )
  member
end

ActiveRecord::Base.transaction do
  # Order matters: visits reference requests, requests reference members.
  Visit.delete_all
  RescheduleRequest.delete_all
  Member.delete_all
  Technician.delete_all

  read_json("visits.json").each do |row|
    member = upsert_member(
      row.fetch("member").merge("address" => row["address"], "timezone" => row["timezone"]),
      household_id: row["household_id"]
    )
    technician = Technician.find_or_create_by!(name: row.dig("technician", "name"))
    cancellation = row["cancellation"] || {}

    Visit.create!(
      appointment_id: row.fetch("appointment_id"),
      member: member,
      technician: technician,
      scheduled_start: ZONE.parse(row.fetch("scheduled_start")),
      scheduled_end: ZONE.parse(row.fetch("scheduled_end")),
      visit_type: row.fetch("visit_type"),
      status: row.fetch("status"),
      confirmation_status: row.fetch("confirmation_status"),
      reminder_sent_at: row["reminder_sent_at"] && ZONE.parse(row["reminder_sent_at"]),
      reminder_response: row["reminder_response"],
      drive_minutes_from_prev: row["drive_minutes_from_prev"] || 0,
      cancellation_reason: cancellation["reason"],
      cancellation_channel: cancellation["channel"],
      cancelled_by: cancellation["cancelled_by"],
      cancelled_at: cancellation["cancelled_at"] && ZONE.parse(cancellation["cancelled_at"])
    )
  end

  read_json("reschedule_requests.json").each do |row|
    member = upsert_member(
      row.fetch("member").merge("address" => row["address"], "timezone" => row["timezone"])
    )

    RescheduleRequest.create!(
      request_id: row.fetch("request_id"),
      member: member,
      requested_at: Date.parse(row.fetch("requested_at")),
      preferred_timeframe: row.fetch("preferred_timeframe"),
      reason: row["reason"],
      clinical_priority: row.fetch("clinical_priority"),
      status: "waiting"
    )
  end
end

puts "Seeded #{Technician.count} CHWs, #{Member.count} members, " \
     "#{Visit.count} visits, #{RescheduleRequest.count} waitlist requests."

# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_08_10_001055) do
  create_table "members", force: :cascade do |t|
    t.string "address_line1"
    t.integer "age"
    t.string "city"
    t.datetime "created_at", null: false
    t.string "household_id"
    t.float "lat"
    t.float "lng"
    t.string "name", null: false
    t.integer "prior_no_shows", default: 0, null: false
    t.string "state"
    t.string "timezone", default: "America/New_York", null: false
    t.datetime "updated_at", null: false
    t.string "zip"
    t.index ["name"], name: "index_members_on_name", unique: true
  end

  create_table "reschedule_requests", force: :cascade do |t|
    t.string "clinical_priority", default: "normal", null: false
    t.datetime "created_at", null: false
    t.integer "member_id", null: false
    t.string "preferred_timeframe", default: "any", null: false
    t.string "reason"
    t.string "request_id", null: false
    t.date "requested_at"
    t.string "status", default: "waiting", null: false
    t.datetime "updated_at", null: false
    t.index ["member_id"], name: "index_reschedule_requests_on_member_id"
    t.index ["request_id"], name: "index_reschedule_requests_on_request_id", unique: true
  end

  create_table "technicians", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_technicians_on_name", unique: true
  end

  create_table "visits", force: :cascade do |t|
    t.string "appointment_id", null: false
    t.integer "backfilled_by_visit_id"
    t.string "cancellation_channel"
    t.string "cancellation_reason"
    t.datetime "cancelled_at"
    t.string "cancelled_by"
    t.string "confirmation_status", default: "no_reply", null: false
    t.datetime "created_at", null: false
    t.integer "drive_minutes_from_prev", default: 0, null: false
    t.integer "filled_from_request_id"
    t.integer "member_id", null: false
    t.string "reminder_response"
    t.datetime "reminder_sent_at"
    t.datetime "scheduled_end", null: false
    t.datetime "scheduled_start", null: false
    t.string "status", default: "scheduled", null: false
    t.integer "technician_id", null: false
    t.datetime "updated_at", null: false
    t.string "visit_type", default: "foot_care", null: false
    t.index ["appointment_id"], name: "index_visits_on_appointment_id", unique: true
    t.index ["backfilled_by_visit_id"], name: "index_visits_on_backfilled_by_visit_id"
    t.index ["filled_from_request_id"], name: "index_visits_on_filled_from_request_id"
    t.index ["member_id"], name: "index_visits_on_member_id"
    t.index ["scheduled_start"], name: "index_visits_on_scheduled_start"
    t.index ["technician_id"], name: "index_visits_on_technician_id"
  end

  add_foreign_key "reschedule_requests", "members"
  add_foreign_key "visits", "members"
  add_foreign_key "visits", "reschedule_requests", column: "filled_from_request_id"
  add_foreign_key "visits", "technicians"
  add_foreign_key "visits", "visits", column: "backfilled_by_visit_id"
end

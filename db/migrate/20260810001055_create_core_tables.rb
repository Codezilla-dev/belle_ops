class CreateCoreTables < ActiveRecord::Migration[8.1]
  def change
    create_table :technicians do |t|
      t.string :name, null: false
      t.timestamps
    end
    add_index :technicians, :name, unique: true

    create_table :members do |t|
      t.string :name, null: false
      t.integer :age
      t.integer :prior_no_shows, null: false, default: 0
      t.string :household_id
      t.string :address_line1
      t.string :city
      t.string :state
      t.string :zip
      t.float :lat
      t.float :lng
      t.string :timezone, null: false, default: "America/New_York"
      t.timestamps
    end
    add_index :members, :name, unique: true

    create_table :reschedule_requests do |t|
      t.string :request_id, null: false
      t.references :member, null: false, foreign_key: true
      t.date :requested_at
      t.string :preferred_timeframe, null: false, default: "any"
      t.string :reason
      t.string :clinical_priority, null: false, default: "normal"
      t.string :status, null: false, default: "waiting"
      t.timestamps
    end
    add_index :reschedule_requests, :request_id, unique: true

    create_table :visits do |t|
      t.string :appointment_id, null: false
      t.references :member, null: false, foreign_key: true
      t.references :technician, null: false, foreign_key: true
      t.datetime :scheduled_start, null: false
      t.datetime :scheduled_end, null: false
      t.string :visit_type, null: false, default: "foot_care"
      t.string :status, null: false, default: "scheduled"
      t.string :confirmation_status, null: false, default: "no_reply"
      t.datetime :reminder_sent_at
      t.string :reminder_response
      t.integer :drive_minutes_from_prev, null: false, default: 0

      # Flattened cancellation object — one-to-one with the visit, so a separate
      # table would buy nothing.
      t.string :cancellation_reason
      t.string :cancellation_channel
      t.string :cancelled_by
      t.datetime :cancelled_at

      # Backfill bookkeeping: a visit created off the waitlist points at the
      # request it came from, and the visit that fell through points at its
      # replacement (so we know that slot is no longer open).
      t.references :filled_from_request, foreign_key: { to_table: :reschedule_requests }
      t.references :backfilled_by_visit, foreign_key: { to_table: :visits }

      t.timestamps
    end
    add_index :visits, :appointment_id, unique: true
    add_index :visits, :scheduled_start
  end
end

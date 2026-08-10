# frozen_string_literal: true

class Visit < ApplicationRecord
  include Cancellable

  belongs_to :member
  belongs_to :technician
  belongs_to :filled_from_request, class_name: "RescheduleRequest", optional: true
  belongs_to :backfilled_by_visit, class_name: "Visit", optional: true

  enum :status, {
    scheduled: "scheduled",
    completed: "completed",
    cancelled: "cancelled",
    no_show: "no_show"
  }, validate: true

  enum :confirmation_status, {
    confirmed: "confirmed",
    no_reply: "no_reply",
    wants_reschedule: "wants_reschedule",
    declined: "declined"
  }, validate: true

  enum :visit_type, { foot_care: "foot_care", follow_up: "follow_up" }, validate: true

  validates :appointment_id, presence: true, uniqueness: true

  scope :on_day, ->(day) {
    zone = Belle::CURRENT_TIME.time_zone
    where(scheduled_start: zone.parse(day.to_s).all_day)
  }
  scope :chronological, -> { order(:scheduled_start) }

  # Visits that need the coordinator's attention right now: still on the books,
  # still ahead of us, and the member has not said they'll be there.
  scope :needs_attention, -> {
    where(status: "scheduled").where.not(confirmation_status: "confirmed")
  }

  def duration_minutes
    ((scheduled_end - scheduled_start) / 60).round
  end

  def past?
    scheduled_end <= Belle::CURRENT_TIME
  end

  # A visit created by filling an open slot from the waitlist.
  def backfill?
    filled_from_request_id.present?
  end
end

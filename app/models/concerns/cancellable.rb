# frozen_string_literal: true

# Everything about a visit falling through: whether it did, whether the drive was
# already spent when we found out, and whether the vacated window is still open.
module Cancellable
  extend ActiveSupport::Concern

  FELL_THROUGH_STATUSES = %w[cancelled no_show].freeze

  # Channels where we heard about it remotely, i.e. the CHW could still be
  # redirected. `on_site` means they were already standing at the door.
  REMOTE_CHANNELS = %w[text voice].freeze

  included do
    scope :fell_through, -> { where(status: FELL_THROUGH_STATUSES) }
  end

  def fell_through?
    FELL_THROUGH_STATUSES.include?(status)
  end

  # The window is still available to give to somebody else.
  def open_slot?
    fell_through? && backfilled_by_visit_id.nil?
  end

  # Did we save the drive?
  #
  # The drive is only saved if word reached us through a remote channel *and* it
  # reached us before the CHW would have set off — which is
  # `drive_minutes_from_prev` before the visit was due to start. A text that
  # lands while they're already in the car costs us the same as no text at all.
  def drive_avoided?
    return false unless fell_through?
    return false unless REMOTE_CHANNELS.include?(cancellation_channel)
    return false if cancelled_at.blank?

    cancelled_at <= departure_time
  end

  def departure_time
    scheduled_start - drive_minutes_from_prev.minutes
  end

  # Drive minutes actually burned on this visit.
  def drive_minutes_spent
    drive_avoided? ? 0 : drive_minutes_from_prev
  end

  def drive_minutes_saved
    drive_avoided? ? drive_minutes_from_prev : 0
  end

  # `morning` / `afternoon`, matching the vocabulary the waitlist uses for
  # member preferences. Split at local noon.
  def timeframe
    scheduled_start.in_time_zone(Belle::CURRENT_TIME.time_zone).hour < 12 ? "morning" : "afternoon"
  end
end

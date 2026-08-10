# frozen_string_literal: true

# The dataset we ship is a snapshot of a single day, so "today" and "now" are
# pinned rather than read off the wall clock. Everything in the app that needs a
# notion of the present (which visits are in the past, whether a cancellation
# arrived before the drive started, what the simulator is allowed to do) reads
# from here.
module Belle
  CURRENT_DAY = Date.new(2026, 6, 29)

  # Midday: the morning route is done, the afternoon is still ahead.
  CURRENT_TIME = Time.find_zone!("America/New_York").local(2026, 6, 29, 12, 0, 0)

  # A member with this many past no-shows gets flagged on the calendar.
  NO_SHOW_RISK_THRESHOLD = 2

  # Calendar grid bounds (hours, local time).
  DAY_START_HOUR = 8
  DAY_END_HOUR = 17
end

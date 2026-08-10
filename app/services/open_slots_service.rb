# frozen_string_literal: true

# The holes in the day: windows a CHW is now free because a visit fell through
# and nobody has been put in its place.
#
# We reuse the vacated visit's own window and location rather than inventing new
# ones — the CHW's route already had them driving to that neighbourhood at that
# hour, so it is the cheapest possible slot to fill.
class OpenSlotsService
  # How much driving we assume a CHW can absorb when there is no earlier stop to
  # measure from (first visit of the day, or a gap we can't compute).
  DEFAULT_SLACK_MINUTES = 30

  Slot = Data.define(:visit, :technician, :starts_at, :ends_at, :timeframe, :member, :slack_minutes) do
    def id = visit.id
    def duration_minutes = visit.duration_minutes

    # Where the CHW was already headed — the anchor we measure candidates from.
    def anchor = member
  end

  def initialize(visits)
    @visits = visits.to_a
  end

  def self.for_day(day = Belle::CURRENT_DAY)
    new(Visit.on_day(day).includes(:member, :technician))
  end

  attr_reader :visits

  # Minutes between the CHW's previous stop finishing and this window starting.
  # That gap is all the driving we can spend getting somebody new into the slot —
  # anyone further away than this can't actually be reached in time.
  def slack_before(visit)
    previous = visits.select { |other|
      other.technician_id == visit.technician_id &&
        other.id != visit.id &&
        !other.fell_through? &&
        other.scheduled_end <= visit.scheduled_start
    }.max_by(&:scheduled_end)

    return DEFAULT_SLACK_MINUTES if previous.nil?

    ((visit.scheduled_start - previous.scheduled_end) / 60).round
  end

  def slots
    @slots ||= visits.select(&:open_slot?).sort_by(&:scheduled_start).map do |visit|
      Slot.new(
        visit: visit,
        technician: visit.technician,
        starts_at: visit.scheduled_start,
        ends_at: visit.scheduled_end,
        timeframe: visit.timeframe,
        member: visit.member,
        slack_minutes: slack_before(visit)
      )
    end
  end

  # Only slots we can still act on. A window that has already passed is a lost
  # trip, not an opportunity, and offering it would just be noise.
  def fillable_slots
    slots.select { |slot| slot.starts_at > Belle::CURRENT_TIME }
  end
end

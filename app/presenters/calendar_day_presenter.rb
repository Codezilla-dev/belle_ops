# frozen_string_literal: true

# Everything the schedule page renders, in one payload: the hour ruler, a row per
# CHW with their visits, and the day's headline numbers.
class CalendarDayPresenter
  def initialize(day: Belle::CURRENT_DAY)
    @day = day
    @visits = Visit.on_day(day).includes(:member, :technician).chronological.to_a
    @costs = DriveCostService.new(@visits).by_technician
  end

  def as_props
    {
      day: day.to_s,
      day_label: day.strftime("%A, %B %-d, %Y"),
      now_offset_minutes: now_offset_minutes,
      now_label: local(Belle::CURRENT_TIME).strftime("%-l:%M %p"),
      hours: hours,
      minutes_in_day: (hours.length - 1) * 60,
      technicians: technician_rows,
      summary: summary
    }
  end

  private

  attr_reader :day, :visits, :costs

  def hours
    (Belle::DAY_START_HOUR..Belle::DAY_END_HOUR).map do |hour|
      { hour: hour, label: Time.zone.local(2000, 1, 1, hour).strftime("%-l %p") }
    end
  end

  def technician_rows
    by_technician = visits.group_by(&:technician)

    Technician.alphabetical.map do |technician|
      technician_visits = by_technician.fetch(technician, [])
      lanes = assign_lanes(technician_visits)

      {
        id: technician.id,
        name: technician.name,
        lane_count: lanes.values.max.to_i + 1,
        drive: drive_props(technician),
        visits: technician_visits.map do |visit|
          VisitPresenter.new(visit).as_props.merge(lane: lanes.fetch(visit.id, 0))
        end
      }
    end
  end

  def drive_props(technician)
    cost = costs[technician.id]
    return { spent_minutes: 0, saved_minutes: 0, wasted_minutes: 0 } if cost.nil?

    {
      spent_minutes: cost.spent_minutes,
      saved_minutes: cost.saved_minutes,
      wasted_minutes: cost.wasted_minutes
    }
  end

  # Visits at one address can overlap (a CHW sees both members of a household in
  # a single stop), so stack overlapping blocks into lanes instead of letting
  # them cover each other up.
  def assign_lanes(technician_visits)
    lane_ends = []

    technician_visits.sort_by(&:scheduled_start).each_with_object({}) do |visit, lanes|
      lane = lane_ends.index { |ends_at| ends_at <= visit.scheduled_start } || lane_ends.length
      lane_ends[lane] = visit.scheduled_end
      lanes[visit.id] = lane
    end
  end

  # The numbers the coordinator scans first: what still needs chasing, and how
  # much of the day has already gone sideways.
  def summary
    day_cost = DriveCostService.new(visits).totals

    {
      total: visits.length,
      drive_wasted_minutes: day_cost.wasted_minutes,
      drive_saved_minutes: day_cost.saved_minutes,
      completed: visits.count { |visit| visit.status == "completed" },
      fell_through: visits.count(&:fell_through?),
      unconfirmed: visits.count { |visit| visit.status == "scheduled" && !visit.confirmed? },
      at_risk: visits.count { |visit| visit.status == "scheduled" && !visit.past? && visit.member.no_show_risk? }
    }
  end

  def now_offset_minutes
    return nil unless local(Belle::CURRENT_TIME).to_date == day

    day_opens = local(Belle::CURRENT_TIME).change(hour: Belle::DAY_START_HOUR)
    ((local(Belle::CURRENT_TIME) - day_opens) / 60).round
  end

  def local(time)
    time.in_time_zone(Belle::CURRENT_TIME.time_zone)
  end
end

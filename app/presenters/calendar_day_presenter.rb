# frozen_string_literal: true

# Everything the schedule page renders, in one payload: the hour ruler, a row per
# CHW with their visits, and the day's headline numbers.
class CalendarDayPresenter
  def initialize(day: Belle::CURRENT_DAY)
    @day = day
    @visits = Visit.on_day(day).includes(:member, :technician).chronological.to_a
    @costs = DriveCostService.new(@visits).by_technician
    @open_slots = OpenSlotsService.new(@visits).fillable_slots
    @suggestions = WaitlistMatcherService.new.suggestions_for(@open_slots)
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
      waitlist: WaitlistPresenter.new(slots: open_slots).as_props,
      summary: summary
    }
  end

  private

  attr_reader :day, :visits, :costs, :open_slots, :suggestions

  def hours
    (Belle::DAY_START_HOUR..Belle::DAY_END_HOUR).map do |hour|
      { hour: hour, label: Time.zone.local(2000, 1, 1, hour).strftime("%-l %p") }
    end
  end

  def technician_rows
    by_technician = visits.group_by(&:technician)

    Technician.alphabetical.map do |technician|
      technician_visits = by_technician.fetch(technician, [])
      technician_slots = open_slots.select { |slot| slot.technician == technician }
      lanes = assign_lanes(technician_visits, technician_slots)

      {
        id: technician.id,
        name: technician.name,
        lane_count: lanes.values.max.to_i + 1,
        drive: drive_props(technician),
        visits: technician_visits.map do |visit|
          VisitPresenter.new(visit).as_props.merge(lane: lanes.fetch([ :visit, visit.id ], 0))
        end,
        open_slots: technician_slots.map { |slot| slot_props(slot, lanes) }
      }
    end
  end

  def slot_props(slot, lanes)
    candidates = suggestions.fetch(slot.id, [])

    {
      id: slot.id,
      time_label: local(slot.starts_at).strftime("%-l:%M %p"),
      offset_minutes: offset_minutes(slot.starts_at),
      duration_minutes: slot.duration_minutes,
      lane: lanes.fetch([ :slot, slot.id ], 0),
      vacated_by: slot.member.name,
      timeframe: slot.timeframe,
      slack_minutes: slot.drive_budget_minutes,
      # The name we put on the calendar block, if we have one worth putting there.
      # Everyone else is still one click away inside the slot.
      suggested_member_name: candidates.find(&:recommended)&.member&.name,
      candidates: candidates.map { |candidate| candidate_props(candidate) }
    }
  end

  def candidate_props(candidate)
    {
      request_id: candidate.request.id,
      member_name: candidate.member.name,
      member_age: candidate.member.age,
      clinical_priority: candidate.request.clinical_priority,
      distance_km: candidate.distance_km,
      drive_minutes: candidate.drive_minutes,
      reachable: candidate.reachable,
      timeframe_match: candidate.timeframe_match,
      recommended: candidate.recommended,
      preferred_timeframe: candidate.request.preferred_timeframe,
      days_waiting: candidate.request.days_waiting,
      reasons: candidate.reasons,
      warnings: candidate.warnings
    }
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

  # Stack anything sharing a window into its own lane instead of letting blocks
  # cover each other up. Two things cause overlap:
  #
  #   * a CHW seeing both members of a household in one stop, and
  #   * an open slot, which sits in the same window as the visit that vacated it.
  #     The cancelled visit has to stay visible — hiding it behind the slot makes
  #     the row read as though the visit was never there.
  #
  # Slots sort after visits at the same time so the original visit keeps the top
  # lane and the slot appears beneath it.
  def assign_lanes(technician_visits, technician_slots)
    blocks = technician_visits.map { |visit|
      { key: [ :visit, visit.id ], starts_at: visit.scheduled_start, ends_at: visit.scheduled_end, slot: false }
    } + technician_slots.map { |slot|
      { key: [ :slot, slot.id ], starts_at: slot.starts_at, ends_at: slot.ends_at, slot: true }
    }

    lane_ends = []

    blocks.sort_by { |block| [ block[:starts_at], block[:slot] ? 1 : 0 ] }.each_with_object({}) do |block, lanes|
      lane = lane_ends.index { |ends_at| ends_at <= block[:starts_at] } || lane_ends.length
      lane_ends[lane] = block[:ends_at]
      lanes[block[:key]] = lane
    end
  end

  # The numbers the coordinator scans first: what still needs chasing, and how
  # much of the day has already gone sideways.
  def summary
    day_cost = DriveCostService.new(visits).totals

    {
      total: visits.length,
      open_slots: open_slots.length,
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

    offset_minutes(Belle::CURRENT_TIME)
  end

  def offset_minutes(time)
    day_opens = local(time).change(hour: Belle::DAY_START_HOUR)
    ((local(time) - day_opens) / 60).round
  end

  def local(time)
    time.in_time_zone(Belle::CURRENT_TIME.time_zone)
  end
end

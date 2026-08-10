# frozen_string_literal: true

# Who keeps falling through, and is it always the same CHW?
#
# The dataset is one day, so these are patterns-so-far rather than long-run
# rates. The member view leans on `prior_no_shows`, which does carry history.
class ReliabilityStatsService
  MemberStat = Data.define(
    :member, :visits_today, :completed, :fell_through, :cancelled, :no_shows,
    :unconfirmed, :waitlisted, :last_outcome
  ) do
    def prior_no_shows = member.prior_no_shows
    def risk? = member.no_show_risk?
  end

  TechnicianStat = Data.define(
    :technician, :visits, :completed, :fell_through, :on_site_discoveries, :wasted_drive_minutes
  ) do
    def fell_through_rate = visits.zero? ? 0.0 : (fell_through.to_f / visits)
  end

  # Flag a CHW only once there is enough of a day to judge — otherwise one bad
  # morning looks like a pattern.
  MIN_VISITS_TO_FLAG = 4
  FLAG_RATE = 0.3

  def initialize(day: Belle::CURRENT_DAY)
    @visits = Visit.on_day(day).includes(:member, :technician).to_a
  end

  def member_stats
    Member.includes(:visits, :reschedule_requests).map { |member| stat_for(member) }
  end

  def technician_stats
    visits.group_by(&:technician).map { |technician, group| technician_stat(technician, group) }
  end

  # CHWs whose day is going badly enough to be worth a look. Framed as "worth
  # asking about", not "at fault" — most of these are the member's doing.
  def flagged_technicians
    technician_stats.select do |stat|
      stat.visits >= MIN_VISITS_TO_FLAG && stat.fell_through_rate >= FLAG_RATE
    end
  end

  private

  attr_reader :visits

  def stat_for(member)
    today = member.visits.select { |visit| visits.include?(visit) }

    MemberStat.new(
      member: member,
      visits_today: today.length,
      completed: today.count { |visit| visit.status == "completed" },
      fell_through: today.count(&:fell_through?),
      cancelled: today.count { |visit| visit.status == "cancelled" },
      no_shows: today.count { |visit| visit.status == "no_show" },
      unconfirmed: today.count { |visit| visit.status == "scheduled" && !visit.confirmed? },
      waitlisted: member.reschedule_requests.any? { |request| request.waiting? },
      last_outcome: today.max_by(&:scheduled_start)
    )
  end

  def technician_stat(technician, group)
    TechnicianStat.new(
      technician: technician,
      visits: group.length,
      completed: group.count { |visit| visit.status == "completed" },
      fell_through: group.count(&:fell_through?),
      # Trips that ended at a closed door: the expensive kind, and the kind a
      # confirmation call could have prevented.
      on_site_discoveries: group.count { |visit| visit.cancellation_channel == "on_site" },
      wasted_drive_minutes: group.select(&:fell_through?).sum(&:drive_minutes_spent)
    )
  end
end

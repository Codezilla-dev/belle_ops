# frozen_string_literal: true

# The members page: who is unreliable, who is waiting, and whether any CHW's day
# is going badly enough to ask about.
class MembersPresenter
  def initialize(stats: ReliabilityStatsService.new)
    @stats = stats
  end

  def as_props
    {
      members: member_rows,
      technicians: technician_rows,
      flagged_technician_ids: stats.flagged_technicians.map { |stat| stat.technician.id }
    }
  end

  private

  attr_reader :stats

  # Sorted so the people most likely to waste a trip are at the top — that's the
  # list the coordinator actually works from.
  def member_rows
    stats.member_stats
         .sort_by { |stat| [ -stat.prior_no_shows, -stat.fell_through, stat.member.name ] }
         .map { |stat| member_row(stat) }
  end

  def member_row(stat)
    {
      id: stat.member.id,
      name: stat.member.name,
      age: stat.member.age,
      address: stat.member.full_address,
      prior_no_shows: stat.prior_no_shows,
      risk: stat.risk?,
      visits_today: stat.visits_today,
      completed: stat.completed,
      cancelled: stat.cancelled,
      no_shows: stat.no_shows,
      unconfirmed: stat.unconfirmed,
      waitlisted: stat.waitlisted,
      today_status: today_status(stat)
    }
  end

  def today_status(stat)
    return "On the waitlist" if stat.visits_today.zero? && stat.waitlisted
    return "Not scheduled today" if stat.visits_today.zero?

    visit = stat.last_outcome
    case visit.status
    when "completed" then "Seen today"
    when "cancelled" then "Cancelled today"
    when "no_show" then "No-show today"
    else visit.confirmed? ? "Confirmed, still ahead" : "Unconfirmed, still ahead"
    end
  end

  def technician_rows
    stats.technician_stats.sort_by { |stat| -stat.fell_through_rate }.map do |stat|
      {
        id: stat.technician.id,
        name: stat.technician.name,
        visits: stat.visits,
        completed: stat.completed,
        fell_through: stat.fell_through,
        fell_through_pct: (stat.fell_through_rate * 100).round,
        on_site_discoveries: stat.on_site_discoveries,
        wasted_drive_minutes: stat.wasted_drive_minutes
      }
    end
  end
end

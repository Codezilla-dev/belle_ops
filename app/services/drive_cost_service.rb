# frozen_string_literal: true

# What the day's driving actually cost each CHW.
#
# Drive time is the real cost of a wasted trip, so we track two numbers per CHW:
# minutes actually spent behind the wheel, and minutes we didn't have to spend
# because a member called ahead. The second number is the one that shows whether
# chasing confirmations is paying off. See Cancellable#drive_avoided? for the
# rule that separates them.
class DriveCostService
  Cost = Data.define(:technician_id, :spent_minutes, :saved_minutes, :wasted_minutes) do
    def total_scheduled_minutes = spent_minutes + saved_minutes
  end

  def initialize(visits)
    @visits = visits.to_a
  end

  def self.for_day(day = Belle::CURRENT_DAY)
    new(Visit.on_day(day).includes(:technician))
  end

  # => { technician_id => Cost }
  def by_technician
    visits.group_by(&:technician_id).transform_values { |group| cost_for(group) }
  end

  def totals
    cost_for(visits)
  end

  private

  attr_reader :visits

  def cost_for(group)
    Cost.new(
      technician_id: group.first&.technician_id,
      spent_minutes: group.sum(&:drive_minutes_spent),
      saved_minutes: group.sum(&:drive_minutes_saved),
      # Drives we made for a visit that never happened — pure waste.
      wasted_minutes: group.select { |visit| visit.fell_through? }.sum(&:drive_minutes_spent)
    )
  end
end

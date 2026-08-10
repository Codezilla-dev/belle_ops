# frozen_string_literal: true

# A member who wants a visit but isn't on today's route: they called in, or a
# previous visit fell through. These are the candidates for an open slot.
class RescheduleRequest < ApplicationRecord
  belongs_to :member
  has_one :fulfilling_visit, class_name: "Visit", foreign_key: :filled_from_request_id,
                             dependent: :nullify, inverse_of: :filled_from_request

  enum :status, { waiting: "waiting", scheduled: "scheduled" }, validate: true
  enum :preferred_timeframe, { morning: "morning", afternoon: "afternoon", any: "any" },
       validate: true, prefix: :prefers
  enum :clinical_priority, { normal: "normal", high: "high" }, validate: true, prefix: :priority

  validates :request_id, presence: true, uniqueness: true

  scope :waiting_list, -> { where(status: "waiting") }

  # Longest-waiting, most urgent first — the order a coordinator would work
  # down the list if nothing else were known.
  scope :by_urgency, -> {
    order(Arel.sql("CASE clinical_priority WHEN 'high' THEN 0 ELSE 1 END"), :requested_at)
  }

  def accepts_timeframe?(timeframe)
    prefers_any? || preferred_timeframe == timeframe.to_s
  end

  def days_waiting
    (Belle::CURRENT_DAY - requested_at).to_i
  end
end

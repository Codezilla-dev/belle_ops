# frozen_string_literal: true

class Member < ApplicationRecord
  include GeoLocatable

  has_many :visits, dependent: :destroy
  has_many :reschedule_requests, dependent: :destroy

  validates :name, presence: true, uniqueness: true

  # Members at the same address (usually spouses) share a household, and a CHW
  # normally sees both in one stop.
  def household_members
    return Member.none if household_id.blank?

    Member.where(household_id: household_id).where.not(id: id)
  end

  def no_show_risk?
    prior_no_shows >= Belle::NO_SHOW_RISK_THRESHOLD
  end

  def full_address
    [ address_line1, city, state, zip ].compact_blank.join(", ")
  end
end

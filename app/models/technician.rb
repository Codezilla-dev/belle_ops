# frozen_string_literal: true

class Technician < ApplicationRecord
  has_many :visits, dependent: :destroy

  validates :name, presence: true, uniqueness: true

  scope :alphabetical, -> { order(:name) }

  def visits_on(day)
    visits.on_day(day).chronological
  end
end

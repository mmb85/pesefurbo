# ==============================================================================
# app/models/contract.rb
# ==============================================================================
class Contract < ApplicationRecord
  belongs_to :player
  belongs_to :club
  belongs_to :season

  enum :role, { starter: "starter", squad: "squad",
                reserve: "reserve", youth: "youth" }

  validates :starts_on, :expires_on, :weekly_wage, presence: true
  validates :weekly_wage, numericality: { greater_than: 0 }

  scope :active, -> { where(active: true) }

  def years_remaining(reference_date = Date.today)
    ((expires_on - reference_date) / 365.25).ceil
  end

  def expiring_soon?(months = 6)
    expires_on <= Date.today + months.months
  end
end

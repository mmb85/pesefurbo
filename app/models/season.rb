# ==============================================================================
# app/models/season.rb
# ==============================================================================
class Season < ApplicationRecord
  has_many :competition_seasons
  has_many :competitions, through: :competition_seasons
  has_many :contracts
  has_many :transfers
  has_many :transfer_windows

  validates :name, :year_start, :year_end, presence: true
  scope :current, -> { where(current: true) }
  def self.active = current.first
end

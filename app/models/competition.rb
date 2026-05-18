# ==============================================================================
# app/models/competition.rb
# ==============================================================================
class Competition < ApplicationRecord
  belongs_to :country, optional: true
  has_many :competition_seasons
  has_many :seasons, through: :competition_seasons

  enum :competition_type, {
    league: "league", cup: "cup",
    supercup: "supercup", international: "international"
  }

  validates :name, :short_name, :tier, presence: true
end

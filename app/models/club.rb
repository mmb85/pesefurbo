# ==============================================================================
# app/models/club.rb
# ==============================================================================
class Club < ApplicationRecord
  belongs_to :country
  belongs_to :stadium, optional: true
  has_many :club_seasons
  has_many :competition_seasons, through: :club_seasons
  has_many :contracts
  has_many :players, through: :contracts, source: :player
  has_many :home_matches, class_name: "Match", foreign_key: :home_club_id
  has_many :away_matches, class_name: "Match", foreign_key: :away_club_id
  has_many :transfers_out, class_name: "Transfer", foreign_key: :from_club_id
  has_many :transfers_in,  class_name: "Transfer", foreign_key: :to_club_id
  has_many :news_items

  validates :name, :short_name, :abbr, presence: true
  validates :abbr, uniqueness: true

  def matches
    Match.where("home_club_id = ? OR away_club_id = ?", id, id)
  end

  def active_contracts
    contracts.where(active: true).includes(:player)
  end

  def squad
    active_contracts.map(&:player)
  end

  def current_season(competition_season)
    club_seasons.find_by(competition_season: competition_season)
  end
end

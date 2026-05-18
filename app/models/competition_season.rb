# ==============================================================================
# app/models/competition_season.rb
# ==============================================================================
class CompetitionSeason < ApplicationRecord
  belongs_to :competition
  belongs_to :season
  has_many :club_seasons
  has_many :clubs, through: :club_seasons
  has_many :matches
  has_many :player_season_stats
  has_many :club_season_standings, through: :club_seasons

  validates :rounds_total, :teams_count, presence: true

  def standings
    club_season_standings.includes(club_season: :club)
                         .order(:position)
  end

  def round_matches(round_number)
    matches.where(round: round_number).includes(:home_club, :away_club)
  end
end

# == Schema Information ==
# Table name: player_season_stats
#
#  id                      :bigint           not null, primary key
#  player_id               :bigint           not null
#  club_id                 :bigint           not null
#  competition_season_id   :bigint           not null
#  appearances             :integer          default(0)
#  starts                  :integer          default(0)
#  goals                   :integer          default(0)
#  assists                 :integer          default(0)
#  shots                   :integer          default(0)
#  shots_on_target         :integer          default(0)
#  clean_sheets            :integer          default(0)
#  goals_conceded          :integer          default(0)
#  saves                   :integer          default(0)
#  yellow_cards            :integer          default(0)
#  red_cards               :integer          default(0)
#  minutes_played          :integer          default(0)
#  avg_rating              :decimal(3, 1)    default(0.0)
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#
# Indexes:
#  index_player_season_stats_on_player_id                                (player_id)
#  index_player_season_stats_on_club_id                                  (club_id)
#  index_player_season_stats_on_competition_season_id                    (competition_season_id)
#  index_player_season_stats_on_player_id_and_club_id_and_competition_season_id (player_id,club_id,competition_season_id) UNIQUE
#

class PlayerSeasonStat < ApplicationRecord
  # Associations
  belongs_to :player
  belongs_to :club
  belongs_to :competition_season

  # Validations
  validates :player_id, :club_id, :competition_season_id, presence: true
  validates :player_id, uniqueness: { scope: [:club_id, :competition_season_id], message: 'can only have one stats record per club per season' }
  validates :appearances, :starts, :goals, :assists, :shots, :shots_on_target, :clean_sheets, :goals_conceded, :saves, :yellow_cards, :red_cards, :minutes_played, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :avg_rating, numericality: { greater_than_or_equal_to: 0.0, less_than_or_equal_to: 10.0 }

  # Scopes
  scope :by_competition, ->(competition_id) { joins(:competition_season).where(competition_seasons: { competition_id: competition_id }) }
  scope :by_club, ->(club_id) { where(club_id: club_id) }
  scope :top_scorers, -> { order(goals: :desc) }
  scope :most_appearances, -> { order(appearances: :desc) }

  # Methods
  def competition
    competition_season.competition
  end

  def season
    competition_season.season
  end

  def matches_missed
    competition_season.rounds_total * 2 - appearances
  end

  def minutes_per_match
    appearances.positive? ? (minutes_played.to_f / appearances).round(1) : 0
  end

  def goals_per_match
    appearances.positive? ? (goals.to_f / appearances).round(2) : 0
  end

  def assists_per_match
    appearances.positive? ? (assists.to_f / appearances).round(2) : 0
  end

  def is_injured?
    player.player_fitnesses.exists?(club_season: club.club_seasons.find_by(competition_season: competition_season), injured: true)
  rescue
    false
  end
end

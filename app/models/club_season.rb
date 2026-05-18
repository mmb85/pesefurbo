# == Schema Information ==
# Table name: club_seasons
#
#  id                      :bigint           not null, primary key
#  club_id                 :bigint           not null
#  competition_season_id   :bigint           not null
#  board_confidence        :integer          default(70)
#  team_morale             :integer          default(60)
#  budget_total            :decimal(12, 2)   default(0.0)
#  budget_transfers        :decimal(12, 2)   default(0.0)
#  budget_wages            :decimal(12, 2)   default(0.0)
#  expected_position       :integer          default(10)
#  form                    :string           default("neutral")
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#
# Indexes:
#  index_club_seasons_on_club_id                              (club_id)
#  index_club_seasons_on_competition_season_id                (competition_season_id)
#  index_club_seasons_on_club_id_and_competition_season_id    (club_id,competition_season_id) UNIQUE
#

class ClubSeason < ApplicationRecord
  # Associations
  belongs_to :club
  belongs_to :competition_season
  has_many :club_season_standings, dependent: :destroy
  has_many :player_fitnesses, dependent: :destroy
  has_many :tactics, dependent: :destroy
  has_one :tactic, -> { where(active: true) }, class_name: 'Tactic', dependent: nil
  
  # Validations
  validates :club_id, :competition_season_id, presence: true
  validates :club_id, uniqueness: { scope: :competition_season_id, message: 'can only be in one league per season' }
  validates :board_confidence, :team_morale, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :budget_total, :budget_transfers, :budget_wages, numericality: { greater_than_or_equal_to: 0 }
  validates :expected_position, numericality: { greater_than_or_equal_to: 1 }

  # Scopes
  scope :active, -> { where(active: true) }
  scope :by_league, ->(competition_id) { joins(:competition_season).where(competition_seasons: { competition_id: competition_id }) }

  # Methods
  def competition
    competition_season.competition
  end

  def season
    competition_season.season
  end

  def league_name
    "#{club.name} in #{competition.name} #{season.name}"
  end

  def budget_remaining
    budget_total - budget_wages
  end

  def budget_used_percentage
    (budget_wages.to_f / budget_total.to_f * 100).round(2) if budget_total.positive?
  end
end

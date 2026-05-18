# == Schema Information ==
# Table name: player_fitnesses
#
#  id                      :bigint           not null, primary key
#  player_id               :bigint           not null
#  club_season_id          :bigint           not null
#  fitness                 :integer          default(100)
#  morale                  :integer          default(50)
#  injured                 :boolean          default(false)
#  suspended               :boolean          default(false)
#  suspension_matches_remaining :integer     default(0)
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#
# Indexes:
#  index_player_fitnesses_on_player_id                       (player_id)
#  index_player_fitnesses_on_club_season_id                  (club_season_id)
#  index_player_fitnesses_on_player_id_and_club_season_id    (player_id,club_season_id) UNIQUE
#

class PlayerFitness < ApplicationRecord
  # Associations
  belongs_to :player
  belongs_to :club_season

  # Validations
  validates :player_id, :club_season_id, presence: true
  validates :player_id, uniqueness: { scope: :club_season_id, message: 'can only have one fitness record per club season' }
  validates :fitness, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100, only_integer: true }
  validates :morale, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100, only_integer: true }
  validates :suspension_matches_remaining, numericality: { greater_than_or_equal_to: 0, only_integer: true }

  # Scopes
  scope :injured, -> { where(injured: true) }
  scope :suspended, -> { where(suspended: true) }
  scope :available, -> { where(injured: false, suspended: false) }
  scope :by_competition, ->(competition_id) { joins(:club_season).joins(:club_season => :competition_season).where(competition_seasons: { competition_id: competition_id }) }

  # Methods
  def available?
    !injured && !suspended && fitness > 0
  end

  def can_play?
    available? && fitness >= 50
  end

  def competition_season
    club_season.competition_season
  end

  def competition
    club_season.competition
  end

  def club
    club_season.club
  end

  def update_suspension
    if suspended && suspension_matches_remaining > 0
      self.suspension_matches_remaining -= 1
      self.suspended = false if suspension_matches_remaining.zero?
      save
    end
  end

  def clear_suspension
    update(suspended: false, suspension_matches_remaining: 0)
  end

  def update_fitness_after_match(minutes_played)
    new_fitness = if minutes_played >= 90
                    [fitness - 15, 0].max
                  elsif minutes_played > 0
                    [(fitness - (minutes_played.to_f / 90 * 15)).round, 0].max
                  else
                    fitness
                  end
    update(fitness: new_fitness)
  end

  def recover_fitness
    new_fitness = [(fitness + 10), 100].min
    update(fitness: new_fitness)
  end
end

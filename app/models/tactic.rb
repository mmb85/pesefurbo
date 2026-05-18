# == Schema Information ==
# Table name: tactics
#
#  id                      :bigint           not null, primary key
#  club_season_id          :bigint           not null
#  name                    :string           default("Default")
#  active                  :boolean          default(true)
#  formation               :string           default("4-4-2")
#  mentality               :string           default("balanced")
#  pressing                :string           default("medium")
#  passing_style           :string           default("mixed")
#  tempo                   :string           default("normal")
#  offside_trap            :boolean          default(false)
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#
# Indexes:
#  index_tactics_on_club_season_id                           (club_season_id)
#

class Tactic < ApplicationRecord
  FORMATIONS = %w[3-5-2 3-4-3 4-1-4-1 4-2-3-1 4-3-3 4-4-2 4-5-1 5-3-2 5-4-1].freeze
  MENTALITIES = %w[very_defensive defensive balanced attacking very_attacking].freeze
  PRESSINGS = %w[low medium high very_high].freeze
  PASSING_STYLES = %w[short_passing mixed long_passing].freeze
  TEMPOS = %w[slow normal fast very_fast].freeze

  # Associations
  belongs_to :club_season

  # Validations
  validates :club_season_id, presence: true
  validates :name, presence: true, length: { minimum: 1, maximum: 100 }
  validates :formation, inclusion: { in: FORMATIONS, message: "%{value} is not a valid formation" }
  validates :mentality, inclusion: { in: MENTALITIES, message: "%{value} is not a valid mentality" }
  validates :pressing, inclusion: { in: PRESSINGS, message: "%{value} is not a valid pressing style" }
  validates :passing_style, inclusion: { in: PASSING_STYLES, message: "%{value} is not a valid passing style" }
  validates :tempo, inclusion: { in: TEMPOS, message: "%{value} is not a valid tempo" }

  # Scopes
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }

  # Callbacks
  before_save :deactivate_other_tactics, if: :active_changed?

  # Methods
  def active_tactic?
    active
  end

  def formation_info
    formation
  end

  def club
    club_season.club
  end

  def competition
    club_season.competition
  end

  def season
    club_season.season
  end

  private

  def deactivate_other_tactics
    if active?
      club_season.tactics.where.not(id: id).update_all(active: false)
    end
  end
end

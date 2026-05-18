# == Schema Information ==
# Table name: lineups
#
#  id                      :bigint           not null, primary key
#  match_id                :bigint           not null
#  club_id                 :bigint           not null
#  player_id               :bigint           not null
#  status                  :string           default("starter")
#  shirt_number            :integer
#  formation_position      :string
#  minute_on               :integer
#  minute_off              :integer
#  rating                  :decimal(3, 1)
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#
# Indexes:
#  index_lineups_on_match_id                                 (match_id)
#  index_lineups_on_club_id                                  (club_id)
#  index_lineups_on_player_id                                (player_id)
#  index_lineups_on_match_id_and_club_id_and_player_id       (match_id,club_id,player_id) UNIQUE
#

class Lineup < ApplicationRecord
  STATUSES = %w[starter substitute bench].freeze
  POSITIONS = %w[GK CB LB RB LWB RWB DM CM CAM LM RM LW RW ST CF].freeze

  # Associations
  belongs_to :match
  belongs_to :club
  belongs_to :player

  # Validations
  validates :match_id, :club_id, :player_id, presence: true
  validates :player_id, uniqueness: { scope: [:match_id, :club_id], message: 'can only appear once per match per club' }
  validates :status, inclusion: { in: STATUSES, message: "%{value} is not a valid status" }
  validates :shirt_number, numericality: { greater_than_or_equal_to: 1, less_than_or_equal_to: 99, only_integer: true, allow_nil: true }
  validates :formation_position, inclusion: { in: POSITIONS, message: "%{value} is not a valid position", allow_nil: true }
  validates :rating, numericality: { greater_than_or_equal_to: 0.0, less_than_or_equal_to: 10.0, allow_nil: true }
  validates :minute_on, :minute_off, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 120, only_integer: true, allow_nil: true }

  # Scopes
  scope :starters, -> { where(status: 'starter') }
  scope :substitutes, -> { where(status: 'substitute') }
  scope :bench, -> { where(status: 'bench') }
  scope :played, -> { where('minute_on IS NOT NULL OR status = ?', 'starter') }
  scope :by_club, ->(club_id) { where(club_id: club_id) }
  scope :by_player, ->(player_id) { where(player_id: player_id) }

  # Methods
  def starter?
    status == 'starter'
  end

  def substitute?
    status == 'substitute'
  end

  def on_bench?
    status == 'bench'
  end

  def played?
    minute_off.present? || (starter? && match.finished?)
  end

  def minutes_played
    if starter? && minute_off.nil?
      match.finished? ? 90 : 0
    elsif minute_on.present? && minute_off.present?
      minute_off - minute_on
    elsif minute_on.present?
      0
    else
      0
    end
  end

  def came_on_as_substitute?
    minute_on.present?
  end

  def came_off_as_substitute?
    minute_off.present? && minute_on.present?
  end

  def home_lineup?
    club_id == match.home_club_id
  end

  def away_lineup?
    club_id == match.away_club_id
  end
end

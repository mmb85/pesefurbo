# == Schema Information ==
# Table name: injuries
#
#  id                      :bigint           not null, primary key
#  player_id               :bigint           not null
#  club_id                 :bigint           not null
#  competition_season_id   :bigint
#  match_id                :bigint
#  occurred_on             :date
#  injury_type             :string
#  severity                :string           default("moderate")
#  expected_return         :date
#  returned_on             :date
#  active                  :boolean          default(true)
#  matches_missed          :integer          default(0)
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#
# Indexes:
#  index_injuries_on_player_id                               (player_id)
#  index_injuries_on_club_id                                 (club_id)
#  index_injuries_on_competition_season_id                   (competition_season_id)
#  index_injuries_on_match_id                                (match_id)
#

class Injury < ApplicationRecord
  # Associations
  belongs_to :player
  belongs_to :club
  belongs_to :competition_season, optional: true
  belongs_to :match, optional: true

  # Enums
  enum :severity, {
    minor: "minor", moderate: "moderate",
    severe: "severe", career_ending: "career_ending"
  }

  # Validations
  validates :player_id, :club_id, presence: true
  validates :severity, inclusion: { in: severities.keys, message: "%{value} is not a valid severity" }
  validates :injury_type, length: { minimum: 1, maximum: 100, allow_nil: true }

  # Scopes
  scope :active, -> { where(active: true) }
  scope :recovered, -> { where(active: false) }
  scope :by_competition, ->(competition_id) { where(competition_season_id: CompetitionSeason.where(competition_id: competition_id)) }
  scope :recent, -> { order(occurred_on: :desc) }

  # Methods
  def active?
    active && (expected_return.nil? || expected_return > Time.zone.today)
  end

  def recovered?
    !active? || (returned_on.present? && returned_on <= Time.zone.today)
  end

  def mark_as_recovered
    update(active: false, returned_on: Time.zone.today)
  end

  def days_until_return
    return nil if expected_return.nil? || recovered?
    (expected_return - Time.zone.today).to_i
  end

  def competition
    competition_season&.competition
  end

  def season
    competition_season&.season
  end
end

# ==============================================================================
# app/models/match.rb
# ==============================================================================
class Match < ApplicationRecord
  belongs_to :competition_season
  belongs_to :week, optional: true
  belongs_to :home_club, class_name: "Club"
  belongs_to :away_club, class_name: "Club"
  belongs_to :stadium, optional: true
  has_many :match_events, dependent: :destroy
  has_many :lineups,      dependent: :destroy

  STATUSES = %w[scheduled simulating simulated live finished postponed cancelled].freeze

  validates :round, presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :finished,  -> { where(status: "finished") }
  scope :scheduled, -> { where(status: "scheduled") }
  scope :simulated, -> { where(status: "simulated") }

  def result_for(club)
    return nil unless finished?
    if (club == home_club && home_goals > away_goals) ||
       (club == away_club && away_goals > home_goals)
      :win
    elsif home_goals == away_goals
      :draw
    else
      :loss
    end
  end

  def goals_for(club)     = club == home_club ? home_goals : away_goals
  def goals_against(club) = club == home_club ? away_goals : home_goals
  def finished?           = status == "finished"
  def simulated?          = %w[simulated finished].include?(status)
  def score               = "#{home_goals} – #{away_goals}"

  # Returns all events as ordered array for Stimulus playback
  def events_payload
    match_events.order(:minute, :id).map do |e|
      {
        minute:      e.minute,
        added_time:  e.added_time,
        event_type:  e.event_type,
        team:        e.club_id == home_club_id ? "home" : "away",
        description: e.description,
        payload:     e.payload
      }
    end
  end
end

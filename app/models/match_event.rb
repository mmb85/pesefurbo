# ==============================================================================
# app/models/match_event.rb
# ==============================================================================
class MatchEvent < ApplicationRecord
  belongs_to :match
  belongs_to :club
  belongs_to :player,        optional: true
  belongs_to :assist_player, class_name: "Player", optional: true
  belongs_to :player_off,    class_name: "Player", optional: true

  TYPES = %w[
    goal own_goal penalty_goal penalty_miss
    yellow_card red_card yellow_red
    substitution injury
    shot_off corner save clearance
    transition possession foul
    long_shot_miss long_shot_save long_shot_post
    halftime fulltime
  ].freeze

  validates :minute, presence: true, numericality: { in: 0..120 }
  validates :event_type, inclusion: { in: TYPES }

  scope :goals,     -> { where(event_type: %w[goal penalty_goal own_goal]) }
  scope :cards,     -> { where(event_type: %w[yellow_card red_card yellow_red]) }
  scope :subs,      -> { where(event_type: "substitution") }
  scope :by_minute, -> { order(:minute, :id) }

  def goal?         = event_type.in?(%w[goal own_goal penalty_goal])
  def display_minute = added_time.positive? ? "#{minute}+#{added_time}'" : "#{minute}'"
end

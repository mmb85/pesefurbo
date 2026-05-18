# ==============================================================================
# app/models/player.rb
# ==============================================================================
class Player < ApplicationRecord
  belongs_to :nationality,        class_name: "Country"
  belongs_to :second_nationality, class_name: "Country", optional: true
  has_many :contracts
  has_many :clubs, through: :contracts
  has_many :transfers
  has_many :lineups
  has_many :player_season_stats
  has_many :player_fitnesses, dependent: :destroy
  has_many :injuries
  has_many :match_events
  has_many :scouting_reports

  POSITIONS = %w[GK SW CB LB RB DM CM AM LW RW ST SS].freeze
  FEET      = %w[left right both].freeze

  validates :first_name, :last_name, :known_as, presence: true
  validates :position, inclusion: { in: POSITIONS }
  validates :preferred_foot, inclusion: { in: FEET }
  validates :date_of_birth, presence: true

  scope :by_position, ->(pos) { where(position: pos) }
  scope :top_rated,   -> { order(overall_rating: :desc) }
  scope :goalkeepers, -> { where(position: "GK") }
  scope :outfield,    -> { where.not(position: "GK") }

  def age(reference_date = Date.today)
    ((reference_date - date_of_birth) / 365.25).floor
  end

  def full_name = "#{first_name} #{last_name}"

  def current_club
    contracts.find_by(active: true)&.club
  end

  def attacking_rating
    ((attr_shooting + attr_long_shot + attr_heading +
      attr_dribbling + attr_positioning) / 5.0).round
  end

  def defensive_rating
    ((attr_tackling + attr_marking + attr_interceptions +
      attr_strength + attr_positioning) / 5.0).round
  end

  def physical_rating
    ((attr_speed + attr_acceleration + attr_stamina + attr_strength) / 4.0).round
  end

  def technical_rating
    ((attr_passing + attr_crossing + attr_ball_control +
      attr_vision + attr_dribbling) / 5.0).round
  end

  def gk_rating
    ((attr_reflexes + attr_handling + attr_diving +
      attr_kicking + attr_command) / 5.0).round
  end

  def recalculate_overall!
    new_overall = if position == "GK"
      ((gk_rating * 0.6) + (physical_rating * 0.2) + (technical_rating * 0.2)).round
    else
      ((attacking_rating * 0.35) + (defensive_rating * 0.25) +
       (physical_rating * 0.20) + (technical_rating * 0.20)).round
    end
    update_column(:overall_rating, new_overall.clamp(1, 99))
  end
end

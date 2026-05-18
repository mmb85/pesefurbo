# ==============================================================================
# app/models/week.rb
# ==============================================================================
class Week < ApplicationRecord
  belongs_to :competition_season
  has_many :matches, dependent: :destroy

  validates :week_number, presence: true, uniqueness: { scope: :competition_season_id }
  validates :competition_season_id, presence: true

  scope :ordered, -> { order(:week_number) }

  def matches_count
    matches.count
  end

  def matches_finished_count
    matches.finished.count
  end

  def finished?
    matches.count > 0 && matches.finished.count == matches.count
  end
end

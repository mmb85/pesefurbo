# ==============================================================================
# app/models/stadium.rb
# ==============================================================================
class Stadium < ApplicationRecord
  belongs_to :country
  has_many :clubs
  has_many :matches

  enum :surface, { grass: "grass", artificial: "artificial", hybrid: "hybrid" }
  validates :name, :city, presence: true
end

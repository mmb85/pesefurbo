# ==============================================================================
# app/models/country.rb
# ==============================================================================
class Country < ApplicationRecord
  has_many :clubs
  has_many :competitions
  has_many :players, foreign_key: :nationality_id

  validates :name, :code, presence: true
  validates :code, uniqueness: true, length: { is: 3 }
end

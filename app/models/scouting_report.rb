# ==============================================================================
# app/models/scouting_report.rb
# ==============================================================================
class ScoutingReport < ApplicationRecord
  belongs_to :player
  belongs_to :club
  belongs_to :season
end

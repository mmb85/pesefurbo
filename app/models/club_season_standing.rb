# ==============================================================================
# app/models/club_season_standing.rb
# ==============================================================================
class ClubSeasonStanding < ApplicationRecord
  belongs_to :club_season

  def self.recalculate_for!(competition_season)
    competition_season.club_seasons.each do |cs|
      club = cs.club
      finished = competition_season.matches.finished

      home = finished.where(home_club: club)
      away = finished.where(away_club: club)

      won   = home.where("home_goals > away_goals").count +
              away.where("away_goals > home_goals").count
      drawn = home.where("home_goals = away_goals").count +
              away.where("home_goals = away_goals").count
      lost  = home.where("home_goals < away_goals").count +
              away.where("away_goals < home_goals").count

      gf = home.sum("home_goals") + away.sum("away_goals")
      ga = home.sum("away_goals") + away.sum("home_goals")

      standing = find_or_initialize_by(club_season: cs)
      standing.update!(
        played: won + drawn + lost,
        won: won, drawn: drawn, lost: lost,
        goals_for: gf, goals_against: ga,
        goal_difference: gf - ga,
        points: (won * 3) + drawn
      )
    end

    competition_season.club_season_standings
                      .order(points: :desc, goal_difference: :desc, goals_for: :desc)
                      .each_with_index do |s, idx|
      s.update_column(:position, idx + 1)
    end
  end
end

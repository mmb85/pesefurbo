# ==============================================================================
# app/controllers/clubs_controller.rb
# ==============================================================================
class ClubsController < ApplicationController
  before_action :ensure_game_mode_selected, only: [:index, :show]

  def index
    @competition_season = CompetitionSeason.includes(
      club_seasons: [:club, :club_season_standings]
    ).first
    @standings = @competition_season&.standings || []
  end

  def show
    @club = Club.includes(:stadium, :country).find(params[:id])
    @competition_season = CompetitionSeason.first
    @club_season  = @club.club_seasons.find_by(competition_season: @competition_season)
    @tactic       = @club_season&.tactics&.find_by(active: true)
    @squad        = @club.active_contracts.includes(:player).order("players.overall_rating DESC")
    @recent_matches = @club.matches.where(status: "finished")
                           .includes(:home_club, :away_club)
                           .order(updated_at: :desc).limit(5)
  end

  private

  def ensure_game_mode_selected
    return if game_mode_selected?

    redirect_to new_game_mode_path, alert: "Selecciona modo de juego y club para comenzar."
  end
end

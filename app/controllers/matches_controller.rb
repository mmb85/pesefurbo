# ==============================================================================
# app/controllers/matches_controller.rb
# ==============================================================================
class MatchesController < ApplicationController
  before_action :set_match, only: [:show, :simulate]

  def index
    @competition_season = current_competition_season
    @weeks = @competition_season&.weeks_with_matches || []
    @matches = @competition_season&.matches
                                  &.includes(:home_club, :away_club, :week)
                                  &.order(:kickoff_at) || Match.none
    @selected_week = params[:week_id].present? ? Week.find(params[:week_id]) : @weeks.first
  end

  def show
    # @events_json is a JSON array string consumed by the match-playback Stimulus controller.
    # events_payload is already an Array (stored as JSONB), so .to_json gives us the JS-ready string.
    @has_match_events = @match.match_events.exists?
    @events_json = @has_match_events ? @match.events_payload.to_json : "[]"
    @home_lineup = @match.lineups.where(club: @match.home_club).includes(:player).order(:shirt_number)
    @away_lineup = @match.lineups.where(club: @match.away_club).includes(:player).order(:shirt_number)

    respond_to do |format|
      format.html
      format.json { render json: @match.events_payload }
    end
  end

  def simulate
    if @match.status == "scheduled"
      MatchSimulationJob.perform_later(@match.id)
      redirect_to @match, notice: "Simulando partido..."
    else
      redirect_to @match, alert: "Este partido ya ha sido simulado."
    end
  end

  def simulate_all
    scheduled = Match.where(status: "scheduled")
    scheduled.each { |m| MatchSimulationJob.perform_later(m.id) }
    redirect_to matches_path, notice: "Simulando #{scheduled.count} partidos en background..."
  end

  private

  def set_match
    @match = Match.includes(:home_club, :away_club, :competition_season).find(params[:id])
  end

  def current_competition_season
    return nil unless @current_season
    @current_season.competition_seasons.includes(:competition).first
  end
end

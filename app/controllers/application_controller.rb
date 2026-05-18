# ==============================================================================
# app/controllers/application_controller.rb
# ==============================================================================
class ApplicationController < ActionController::Base
  before_action :set_current_season
  helper_method :current_game_mode, :current_club, :game_mode_selected?

  private

  def set_current_season
    @current_season = Season.active
  end

  def current_game_mode
    session[:game_mode]
  end

  def current_club
    @current_club ||= Club.find_by(id: session[:selected_club_id]) if session[:selected_club_id]
  end

  def game_mode_selected?
    current_game_mode.present? && current_club.present?
  end
end

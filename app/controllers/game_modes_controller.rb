# ==============================================================================
# app/controllers/game_modes_controller.rb
# ==============================================================================
class GameModesController < ApplicationController
  def new
    @clubs = Club.order(:short_name)
  end

  def create
    game_mode = params[:game_mode]&.to_s
    club = Club.find_by(id: params[:club_id])

    unless %w[single multi].include?(game_mode) && club
      flash.now[:alert] = "Selecciona un modo de juego y un club válidos."
      @clubs = Club.order(:short_name)
      render :new
      return
    end

    session[:game_mode] = game_mode
    session[:selected_club_id] = club.id
    redirect_to club_path(club), notice: "Modo #{game_mode == 'single' ? 'un jugador' : 'multijugador'} activado para #{club.name}."
  end

  def destroy
    session.delete(:game_mode)
    session.delete(:selected_club_id)
    redirect_to new_game_mode_path, notice: "Modo de juego reiniciado."
  end
end

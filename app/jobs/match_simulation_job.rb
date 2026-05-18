# ==============================================================================
# app/jobs/match_simulation_job.rb
# Runs via Solid Queue (Rails 8 native background jobs)
# ==============================================================================
class MatchSimulationJob < ApplicationJob
  queue_as :default

  retry_on StandardError, attempts: 3, wait: :polynomially_longer

  def perform(match_id)
    match = Match.find(match_id)
    return unless match.status == "scheduled"

    Rails.logger.info "[MatchSimulationJob] Simulating match ##{match.id}: " \
                      "#{match.home_club.short_name} vs #{match.away_club.short_name}"

    MatchEngine::Simulator.new(match).run!

    Rails.logger.info "[MatchSimulationJob] Done. Result: #{match.reload.score}"

    # Broadcast to any viewers that match is ready to watch
    broadcast_ready(match)
  rescue => e
    match&.update!(status: "scheduled")  # rollback status on failure
    raise e
  end

  private

  def broadcast_ready(match)
    Turbo::StreamsChannel.broadcast_replace_to(
      "match_#{match.id}_status",
      target: "match_status_#{match.id}",
      partial: "matches/status_badge",
      locals: { match: match }
    )
  end
end

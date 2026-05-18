# ==============================================================================
# app/services/match_engine/lineup_builder.rb
# ==============================================================================
module MatchEngine
  class LineupBuilder
    FORMATION_SLOTS = {
      "4-4-2" => [
        { role: :goalkeeper, count: 1 }, { role: :defender,   count: 4 },
        { role: :midfielder, count: 4 }, { role: :striker,    count: 2 }
      ],
      "4-3-3" => [
        { role: :goalkeeper, count: 1 }, { role: :defender,   count: 4 },
        { role: :midfielder, count: 3 }, { role: :striker,    count: 3 }
      ],
      "4-5-1" => [
        { role: :goalkeeper, count: 1 }, { role: :defender,   count: 4 },
        { role: :midfielder, count: 5 }, { role: :striker,    count: 1 }
      ],
      "3-5-2" => [
        { role: :goalkeeper, count: 1 }, { role: :defender,   count: 3 },
        { role: :midfielder, count: 5 }, { role: :striker,    count: 2 }
      ],
      "5-3-2" => [
        { role: :goalkeeper, count: 1 }, { role: :defender,   count: 5 },
        { role: :midfielder, count: 3 }, { role: :striker,    count: 2 }
      ]
    }.freeze

    POSITION_ROLE_MAP = {
      goalkeeper: %w[GK],
      defender:   %w[CB LB RB SW],
      midfielder: %w[DM CM AM LW RW],
      striker:    %w[ST SS]
    }.freeze

    def initialize(club_season_or_club)
      if club_season_or_club.is_a?(ClubSeason)
        @club    = club_season_or_club.club
        @tactic  = club_season_or_club.tactics.find_by(active: true)
      else
        @club    = club_season_or_club
        @tactic  = nil
      end
      @formation = @tactic&.formation || "4-4-2"
      @slots     = FORMATION_SLOTS[@formation] || FORMATION_SLOTS["4-4-2"]
      @pool      = @club.contracts.where(active: true)
                        .includes(:player)
                        .map(&:player)
                        .sort_by { |p| -p.overall_rating }
    end

    def build
      remaining = @pool.dup
      starters  = []

      @slots.each do |slot|
        slot[:count].times do
          candidate = best_available(remaining, slot[:role])
          if candidate
            starters  << candidate
            remaining.delete(candidate)
          end
        end
      end

      while starters.size < 11 && remaining.any?
        starters << remaining.shift
      end

      bench = build_bench(remaining, starters)
      { starters: starters.first(11), bench: bench }
    end

    private

    def best_available(pool, role)
      eligible = POSITION_ROLE_MAP[role] || []
      pool.find { |p| eligible.include?(p.position) }
    end

    def build_bench(remaining, starters)
      bench = []
      covered = starters.map { |p| player_role(p) }.tally
      [:goalkeeper, :striker, :defender, :midfielder].each do |role|
        next if bench.size >= 7 || covered[role].to_i >= 3
        candidate = remaining.find { |p| player_role(p) == role }
        next unless candidate
        bench << candidate
        remaining.delete(candidate)
      end
      while bench.size < 7 && remaining.any?
        bench << remaining.shift
      end
      bench.first(7)
    end

    def player_role(player)
      case player.position
      when "GK"                   then :goalkeeper
      when "CB", "LB", "RB", "SW" then :defender
      when "DM", "CM", "AM",
           "LW", "RW"             then :midfielder
      when "ST", "SS"             then :striker
      else                             :midfielder
      end
    end
  end
end

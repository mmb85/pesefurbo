# ==============================================================================
# app/services/match_engine/simulator.rb
#
# Arquitectura: Fake Live System (prompt maestro §2)
#
# El Simulator corre dentro de un Solid Queue Job.
# Calcula el partido COMPLETO en milisegundos y guarda todos los MatchEvent
# en la BD con su payload JSONB. El Frontend (Stimulus) luego los reproduce
# uno a uno con setTimeout para el efecto de "live".
#
# Usage:
#   MatchEngine::Simulator.new(match).run!
# ==============================================================================

module MatchEngine
  class Simulator
    HOME_ADVANTAGE      = 0.06
    MAX_SUBS            = 3
    FATIGUE_PER_MINUTE  = 0.30
    COMEBACK_MORALE_BOOST = 5
    COMEBACK_MORALE_HIT   = 8
    LONG_SHOT_MIN_ATTR    = 72

    BASE_YELLOW_PROB   = 0.055
    BASE_RED_PROB      = 0.004
    BASE_INJURY_PROB   = 0.008

    MENTALITY_ATTACK_MOD = {
      "all_out_attack" => +0.18, "attacking" => +0.10,
      "balanced" => 0.00, "defensive" => -0.10, "park_the_bus" => -0.18
    }.freeze

    MENTALITY_DEFENSE_MOD = {
      "all_out_attack" => -0.15, "attacking" => -0.08,
      "balanced" => 0.00, "defensive" => +0.10, "park_the_bus" => +0.18
    }.freeze

    FORMATION_ATTACK_BIAS = {
      "4-3-3" => +0.07, "3-5-2" => +0.03, "4-4-2" => 0.00,
      "4-5-1" => -0.06, "5-3-2" => -0.04, "5-4-1" => -0.10
    }.freeze

    FORMATION_DEFENSE_BIAS = {
      "4-3-3" => -0.05, "3-5-2" => +0.02, "4-4-2" => 0.00,
      "4-5-1" => +0.06, "5-3-2" => +0.05, "5-4-1" => +0.12
    }.freeze

    PRESSING_MOD = {
      "high"   => { fatigue: 1.30, interception: +0.06 },
      "medium" => { fatigue: 1.00, interception:  0.00 },
      "low"    => { fatigue: 0.70, interception: -0.04 }
    }.freeze

    # ── Boot ────────────────────────────────────────────────────────────────

    def initialize(match)
      @match   = match
      @minute  = 0
      @period  = :first_half

      @home    = build_team_state(match.home_club, match.competition_season, home: true)
      @away    = build_team_state(match.away_club, match.competition_season, home: false)

      @home_goals = 0
      @away_goals = 0
      @home_goals_ht = 0
      @away_goals_ht = 0

      @home_stats = blank_stats
      @away_stats = blank_stats

      @events  = []
      @scorers = []

      # Possession ball state
      @ball = { zone: :home_midfield, team: :home }
      @possession_ticks = { home: 0, away: 0 }
    end

    # ── Run ─────────────────────────────────────────────────────────────────

    def run!
      @match.update!(status: "simulating")

      simulate_period(:first_half,  from: 1,  to: 45)
      halftime!
      simulate_period(:second_half, from: 46, to: 90)
      finalize!
    end

    # ── Private ─────────────────────────────────────────────────────────────
    private

    def simulate_period(period, from:, to:)
      @period  = period
      @minute  = from - 1

      while @minute < to
        advance = rand(1..6)
        @minute = [@minute + advance, to].min

        apply_fatigue(advance)
        check_auto_substitutions

        action = sample_transition
        resolve_action(action)

        roll_discipline
        roll_injury

        @possession_ticks[@ball[:team]] += 1
      end
    end

    def halftime!
      @home_goals_ht = @home_goals
      @away_goals_ht = @away_goals
      emit_event(:halftime, team_for(:home), 45, "⏸ DESCANSO — Primer tiempo: #{@home_goals}–#{@away_goals}",
        { zone: "neutral", type: "halftime" })
      
      # Safely handle fatigue increase for starters and bench players
      [@home, @away].each do |t|
        # Combine starters and bench, handling potential nil cases
        players = [*(t[:starters] || []), *(t[:bench] || [])].compact
        
        players.each do |p| 
          # Ensure fatigue exists and is a number
          p[:fatigue] = (p[:fatigue] || 95.0).to_f
          p[:fatigue] = [p[:fatigue] + 15, 100].min 
        end
      end
    end

    def finalize!
      total = @possession_ticks.values.sum.nonzero? || 1
      home_poss = ((@possession_ticks[:home].to_f / total) * 100).round
      away_poss = 100 - home_poss

      emit_event(:fulltime, team_for(:home), 90, "⏱ ¡PITIDO FINAL! #{@home_goals}–#{@away_goals}",
        { zone: "neutral", type: "fulltime",
          home_goals: @home_goals, away_goals: @away_goals,
          home_possession: home_poss, away_possession: away_poss })

      ActiveRecord::Base.transaction do
        # Ensure idempotency: remove any previous events/lineups for this match
        # so re-running a simulation (due to retries) replaces prior partial results
        @match.match_events.delete_all
        @match.lineups.delete_all

        @match.update!(
          status:          "simulated",
          home_goals:      @home_goals,
          away_goals:      @away_goals,
          home_goals_ht:   @home_goals_ht,
          away_goals_ht:   @away_goals_ht,
          home_shots:      @home_stats[:shots].to_i,
          away_shots:      @away_stats[:shots].to_i,
          home_shots_on:   @home_stats[:shots_on_target].to_i,
          away_shots_on:   @away_stats[:shots_on_target].to_i,
          home_possession: home_poss,
          away_possession: away_poss,
          home_corners:    @home_stats[:corners].to_i,
          away_corners:    @away_stats[:corners].to_i,
          home_yellow_cards: @home_stats[:yellows].to_i,
          away_yellow_cards: @away_stats[:yellows].to_i,
          home_red_cards:    @home_stats[:reds].to_i,
          away_red_cards:    @away_stats[:reds].to_i
        )

        persist_events!
        persist_lineups!
        ClubSeasonStanding.recalculate_for!(@match.competition_season)
      end
    end

    # ── Possession machine ───────────────────────────────────────────────────

    TRANSITIONS = {
      home_defense: {
        build_up:  -> (s) { 0.55 },
        long_ball: -> (s) { 0.20 },
        gk_kick:   -> (s) { 0.15 },
        lose_ball: -> (s) { 0.10 }
      },
      home_midfield: {
        advance:   -> (s) { 0.38 },
        back_pass: -> (s) { 0.15 },
        lose_ball: -> (s) { 0.24 },
        foul_won:  -> (s) { 0.08 },
        hold_ball: -> (s) { 0.11 },
        long_shot: -> (s) {
          best = s.best_long_shot_candidate
          best ? [0.04 + (best[:attrs][:long_shot] - LONG_SHOT_MIN_ATTR) / 500.0, 0.0].max : 0.0
        }
      },
      home_attack: {
        shoot:     -> (s) { 0.30 },
        cross:     -> (s) { 0.22 },
        dribble:   -> (s) { 0.20 },
        lose_ball: -> (s) { 0.15 },
        back_pass: -> (s) { 0.13 }
      }
    }.freeze

    AWAY_TRANSITIONS = TRANSITIONS.each_with_object({}) do |(zone, actions), h|
      h[zone.to_s.sub("home_", "away_").to_sym] = actions
    end.freeze

    ALL_TRANSITIONS = TRANSITIONS.merge(AWAY_TRANSITIONS).freeze

    def sample_transition
      zone  = @ball[:zone]
      table = ALL_TRANSITIONS[zone]
      return :hold_ball unless table

      att   = @ball[:team] == :home ? @home : @away
      pairs = table.map { |k, fn| [k, [fn.call(att), 0.01].max] }
      total = pairs.sum { |_, w| w }
      roll  = rand * total
      cum   = 0.0
      pairs.each { |k, w| cum += w; return k if roll <= cum }
      pairs.last.first
    end

    def resolve_action(action)
      att = @ball[:team]
      def_ = att == :home ? :away : :home
      att_state  = @ball[:team] == :home ? @home : @away
      def_state  = @ball[:team] == :home ? @away : @home

      carrier  = @ball[:carrier] || pick_carrier_for_zone(att_state, @ball[:zone])
      tackler  = def_state.random_outfield
      keeper   = def_state.goalkeeper
      team_name = att_state[:club].short_name

      case action
      when :build_up
        advance_to_zone(att, mirror(:home_midfield, att))
        emit_narrative(:possession, att_state, carrier,
          NarrativeBuilder.build(:build_up, carrier: carrier[:known_as], team: team_name))

      when :long_ball, :gk_kick
        if rand < duel_win(att_state, def_state, :heading)
          advance_to_zone(att, mirror(:home_midfield, att))
          emit_narrative(:possession, att_state, carrier,
            NarrativeBuilder.build(action, carrier: carrier[:known_as]))
        else
          recv = def_state.random_outfield
          switch_possession(def_, mirror(:home_midfield, def_), recv)
          emit_narrative(:transition, def_state, recv,
            NarrativeBuilder.build(:lose_ball_interception,
              carrier: carrier[:known_as], tackler: recv&.dig(:known_as) || "—"))
        end

      when :advance
        advance_to_zone(att, mirror(:home_attack, att))
        emit_narrative(:possession, att_state, carrier,
          NarrativeBuilder.build(:advance, carrier: carrier[:known_as], team: team_name))

      when :back_pass
        advance_to_zone(att, mirror(:home_defense, att))
        # silent

      when :hold_ball
        # silent

      when :lose_ball
        types = [:lose_ball_tackle, :lose_ball_interception, :lose_ball_out]
        lt    = types.sample
        new_zone = lt == :lose_ball_out ? mirror(:home_defense, def_) :
                   @ball[:zone].to_s.include?("attack") ? mirror(:home_defense, def_) :
                   mirror(:home_midfield, def_)
        recv = def_state.random_outfield
        switch_possession(def_, new_zone, recv)
        emit_narrative(:transition, def_state, recv,
          NarrativeBuilder.build(lt, carrier: carrier[:known_as], tackler: recv&.dig(:known_as) || "—"))

      when :foul_won
        emit_narrative(:foul, att_state, carrier,
          NarrativeBuilder.build(:foul_won, carrier: carrier[:known_as], tackler: tackler&.dig(:known_as) || "—"))
        # Chance of free kick on goal
        if @ball[:zone].to_s.include?("attack") && rand < 0.30
          resolve_shot(att, att_state, def_state, carrier, keeper)
        end

      when :dribble
        if rand < duel_win(att_state, def_state, :dribbling)
          carrier[:rating_delta] = (carrier[:rating_delta] || 0) + 0.3
          emit_narrative(:possession, att_state, carrier,
            NarrativeBuilder.build(:dribble_success,
              carrier: carrier[:known_as], tackler: tackler&.dig(:known_as) || "el defensa"))
        else
          recv = def_state.random_outfield
          switch_possession(def_, mirror(:home_defense, def_), recv)
          emit_narrative(:transition, def_state, recv,
            NarrativeBuilder.build(:dribble_fail,
              carrier: carrier[:known_as], tackler: recv&.dig(:known_as) || "—"))
        end

      when :shoot
        resolve_shot(att, att_state, def_state, carrier, keeper)

      when :cross
        resolve_cross(att, att_state, def_state, carrier, keeper)

      when :long_shot
        resolve_long_shot(att, att_state, def_state, keeper)
      end
    end

    # ── Shot resolution ─────────────────────────────────────────────────────

    def resolve_shot(att, att_state, def_state, shooter, keeper)
      stats_for(att)[:shots] += 1

      on_target_prob = (0.45 + (shooter[:attrs][:shooting] - 60) / 200.0).clamp(0.20, 0.80)

      unless rand < on_target_prob
        switch_possession(opp(att), mirror(:home_defense, opp(att)), nil)
        return emit_narrative(:shot_off, att_state, shooter,
          NarrativeBuilder.build(:shot_off_target,
            carrier: shooter[:known_as], keeper: keeper&.dig(:known_as) || "el portero"))
      end

      stats_for(att)[:shots_on_target] += 1

      if rand < 0.08
        switch_possession(opp(att), mirror(:home_defense, opp(att)), nil)
        return emit_narrative(:miss, att_state, shooter,
          NarrativeBuilder.build(:big_chance_missed,
            carrier: shooter[:known_as], keeper: keeper&.dig(:known_as) || "el portero"))
      end

      sp = gk_save_prob(keeper, shooter)
      if rand < sp
        keeper&.tap { |k| k[:rating_delta] = (k[:rating_delta] || 0) + 0.4 }
        def_state[:stats][:saves] += 1
        corner = rand < 0.60
        if corner
          stats_for(att)[:corners] += 1
          advance_to_zone(att, mirror(:home_attack, att))
          emit_narrative(:corner, att_state, shooter,
            NarrativeBuilder.build(:shot_on_target,
              carrier: shooter[:known_as], keeper: keeper&.dig(:known_as) || "el portero") + " → Córner.")
        else
          switch_possession(opp(att), mirror(:home_defense, opp(att)), nil)
          emit_narrative(:save, def_state, keeper,
            NarrativeBuilder.build(:shot_on_target,
              carrier: shooter[:known_as], keeper: keeper&.dig(:known_as) || "el portero"))
        end
      else
        assister = pick_assister(att_state)
        score_goal(att, att_state, def_state, shooter, assister, keeper)
      end
    end

    def resolve_cross(att, att_state, def_state, crosser, keeper)
      header = pick_striker(att_state)
      return unless header

      stats_for(att)[:crosses] = (stats_for(att)[:crosses] || 0) + 1

      unless rand < duel_win(att_state, def_state, :heading)
        recv = def_state.random_outfield
        switch_possession(opp(att), mirror(:home_defense, opp(att)), recv)
        return emit_narrative(:clearance, def_state, recv,
          NarrativeBuilder.build(:cross_clearance,
            carrier: header[:known_as], assister: crosser[:known_as],
            tackler: recv&.dig(:known_as) || "la defensa"))
      end

      on_target = rand < (0.30 + (header[:attrs][:heading] - 60) / 200.0).clamp(0.10, 0.70)
      unless on_target
        switch_possession(opp(att), mirror(:home_defense, opp(att)), nil)
        return emit_narrative(:clearance, def_state, nil,
          "Centro de #{crosser[:known_as]}, remate de #{header[:known_as]} que se va fuera.")
      end

      sp = gk_save_prob(keeper, header)
      if rand < sp
        def_state[:stats][:saves] += 1
        switch_possession(opp(att), mirror(:home_defense, opp(att)), nil)
        emit_narrative(:save, def_state, keeper,
          NarrativeBuilder.build(:cross_saved,
            carrier: header[:known_as], keeper: keeper&.dig(:known_as) || "el portero",
            assister: crosser[:known_as]))
      else
        score_goal(att, att_state, def_state, header, crosser, keeper)
      end
    end

    def resolve_long_shot(att, att_state, def_state, keeper)
      shooter = att_state.best_long_shot_candidate
      return unless shooter

      # Narrative setup
      emit_narrative(:possession, att_state, shooter,
        NarrativeBuilder.build(:long_shot_spot,
          carrier: shooter[:known_as], keeper: keeper&.dig(:known_as) || "el portero"))

      stats_for(att)[:shots] += 1
      on_target = (0.25 + (shooter[:attrs][:long_shot] - LONG_SHOT_MIN_ATTR) / 270.0).clamp(0.10, 0.55)

      unless rand < on_target
        switch_possession(opp(att), mirror(:home_defense, opp(att)), nil)
        return emit_narrative(:long_shot_miss, att_state, shooter,
          NarrativeBuilder.build(:long_shot_off_target,
            carrier: shooter[:known_as], keeper: keeper&.dig(:known_as) || "el portero"))
      end

      stats_for(att)[:shots_on_target] += 1

      if rand < 0.08
        switch_possession(opp(att), mirror(:home_attack, opp(att)), nil)
        shooter[:rating_delta] = (shooter[:rating_delta] || 0) + 0.5
        return emit_narrative(:long_shot_post, att_state, shooter,
          NarrativeBuilder.build(:long_shot_post,
            carrier: shooter[:known_as], keeper: keeper&.dig(:known_as) || "el portero"))
      end

      pos_penalty = rand * 0.25 + 0.15
      sp = (gk_save_prob(keeper, shooter) - pos_penalty).clamp(0.05, 0.75)

      if rand < sp
        keeper&.tap { |k| k[:rating_delta] = (k[:rating_delta] || 0) + 0.8 }
        def_state[:stats][:saves] += 1
        switch_possession(opp(att), mirror(:home_defense, opp(att)), nil)
        emit_narrative(:long_shot_save, def_state, keeper,
          NarrativeBuilder.build(:long_shot_saved_scramble,
            carrier: shooter[:known_as], keeper: keeper&.dig(:known_as) || "el portero"))
      else
        shooter[:rating_delta] = (shooter[:rating_delta] || 0) + 3.0
        score_goal(att, att_state, def_state, shooter, nil, keeper)
      end
    end

    # ── Goal ────────────────────────────────────────────────────────────────

    def score_goal(att, att_state, def_state, scorer, assister, keeper)
      if att == :home
        @home_goals += 1
      else
        @away_goals += 1
      end

      stats_for(att)[:shots]           = (stats_for(att)[:shots] || 0) + 1
      stats_for(att)[:shots_on_target] = (stats_for(att)[:shots_on_target] || 0) + 1
      stats_for(att)[:goals]           = att == :home ? @home_goals : @away_goals

      att_state[:morale] = [att_state[:morale] + COMEBACK_MORALE_BOOST, 100].min
      def_state[:morale] = [def_state[:morale] - COMEBACK_MORALE_HIT, 0].max

      scorer[:rating_delta]  = (scorer[:rating_delta] || 0) + 2.0
      assister&.tap { |a| a[:rating_delta] = (a[:rating_delta] || 0) + 1.0 }

      score_str = "#{@home_goals}–#{@away_goals}"
      desc = if assister
        NarrativeBuilder.build(:goal,
          carrier: scorer[:known_as], keeper: keeper&.dig(:known_as) || "el portero",
          assister: assister[:known_as], score: score_str)
      else
        NarrativeBuilder.build(:goal_no_assist,
          carrier: scorer[:known_as], keeper: keeper&.dig(:known_as) || "el portero",
          score: score_str)
      end

      @scorers << { side: att, player: scorer[:known_as], minute: @minute }

      emit_event(:goal, att_state[:club], @minute, desc, {
        zone: @ball[:zone].to_s,
        scorer: scorer[:known_as],
        assister: assister&.dig(:known_as),
        score: score_str,
        xG: rand(0.10..0.85).round(2)
      })

      switch_possession(opp(att), mirror(:home_midfield, opp(att)), nil)
    end

    # ── Discipline ──────────────────────────────────────────────────────────

    def roll_discipline
      yp = (BASE_YELLOW_PROB * (@period == :second_half ? 1.3 : 1.0)).round(4)
      if rand < yp
        side = rand < 0.5 ? :home : :away
        state = side == :home ? @home : @away
        p = state.random_outfield
        return unless p

        p[:yellow_cards] = (p[:yellow_cards] || 0) + 1
        stats_for(side)[:yellows] = (stats_for(side)[:yellows] || 0) + 1
        p[:rating_delta] = (p[:rating_delta] || 0) - 0.5

        if p[:yellow_cards] >= 2
          p[:on_pitch] = false; p[:sent_off] = true
          emit_event(:yellow_red, state[:club], @minute,
            NarrativeBuilder.build(:yellow_red, carrier: p[:known_as], team: state[:club].short_name),
            { zone: @ball[:zone].to_s, player: p[:known_as] })
        else
          emit_event(:yellow_card, state[:club], @minute,
            NarrativeBuilder.build(:yellow_card, carrier: p[:known_as], team: state[:club].short_name),
            { zone: @ball[:zone].to_s, player: p[:known_as] })
        end
      end

      if rand < BASE_RED_PROB
        side  = rand < 0.5 ? :home : :away
        state = side == :home ? @home : @away
        p = state.random_outfield
        return unless p
        p[:on_pitch] = false; p[:sent_off] = true
        stats_for(side)[:reds] = (stats_for(side)[:reds] || 0) + 1
        emit_event(:red_card, state[:club], @minute,
          NarrativeBuilder.build(:red_card, carrier: p[:known_as], team: state[:club].short_name),
          { zone: @ball[:zone].to_s, player: p[:known_as] })
      end
    end

    def roll_injury
      avg_fat = [[@home, @away].sum { |t| t.avg_fatigue } / 2.0, 1].max
      prob = BASE_INJURY_PROB * [(100.0 - avg_fat) / 60.0, 1.0].max
      return unless rand < prob

      side  = rand < 0.5 ? :home : :away
      state = side == :home ? @home : @away
      p = state.random_outfield
      return unless p

      p[:fatigue] = 0
      emit_event(:injury, state[:club], @minute,
        NarrativeBuilder.build(:injury, carrier: p[:known_as]),
        { zone: @ball[:zone].to_s })

      return unless state[:subs_used] < MAX_SUBS

      fresh = (state[:bench] || []).find { |b| !b[:on_pitch] && !b[:substituted] }
      return unless fresh

      p[:on_pitch]   = false
      p[:substituted]= true
      fresh[:on_pitch] = true
      fresh[:fatigue]  = 100
      state[:subs_used] += 1

      emit_event(:substitution, state[:club], @minute,
        NarrativeBuilder.build(:substitution,
          carrier: fresh[:known_as], tackler: p[:known_as], team: state[:club].short_name),
        { zone: @ball[:zone].to_s, player_on: fresh[:known_as], player_off: p[:known_as] })
    end

    # ── Auto subs ───────────────────────────────────────────────────────────

    def check_auto_substitutions
      [@home, @away].each do |state|
        side = state == @home ? :home : :away
        next if state[:subs_used] >= MAX_SUBS || @minute < 55

        exhausted = state[:starters].find { |p|
          p[:on_pitch] && !p[:sent_off] && !p[:substituted] && p[:fatigue] < 20
        }
        next unless exhausted

        fresh = (state[:bench] || []).find { |p| !p[:on_pitch] && !p[:substituted] }
        next unless fresh

        exhausted[:on_pitch]    = false
        exhausted[:substituted] = true
        fresh[:on_pitch]  = true
        fresh[:fatigue]   = 100
        state[:subs_used] += 1

        emit_event(:substitution, state[:club], @minute,
          NarrativeBuilder.build(:substitution,
            carrier: fresh[:known_as], tackler: exhausted[:known_as], team: state[:club].short_name),
          { zone: @ball[:zone].to_s, player_on: fresh[:known_as], player_off: exhausted[:known_as] })
      end
    end

    # ── Fatigue ─────────────────────────────────────────────────────────────

    def apply_fatigue(minutes)
      [@home, @away].each do |state|
        press_mult = PRESSING_MOD.dig(state[:pressing], :fatigue) || 1.0
        late_mult  = @minute > 70 ? 1.25 : 1.0
        drain = minutes * FATIGUE_PER_MINUTE * press_mult * late_mult
        state.active_players.each do |p|
          sf = 1.0 - ((p[:attrs][:stamina] || 50) - 50) / 500.0
          p[:fatigue] = [p[:fatigue] - drain * sf, 0.0].max
          p[:minutes_played] = (p[:minutes_played] || 0) + minutes
        end
      end
    end

    # ── GK save ─────────────────────────────────────────────────────────────

    def gk_save_prob(gk, shooter)
      return 0.3 unless gk
      gk_score = ((gk[:attrs][:reflexes] || 50) +
                  (gk[:attrs][:handling] || 50) +
                  (gk[:attrs][:diving]   || 50)) / 3.0
      base = (gk_score / 99.0) * 0.65
      fat_penalty = (1.0 - gk[:fatigue] / 100.0) * 0.08
      (base - fat_penalty).clamp(0.15, 0.85)
    end

    # ── Duel ────────────────────────────────────────────────────────────────

    def duel_win(att_state, def_state, attr_key)
      as = att_state.avg_attr(attr_key)
      ds = def_state.avg_attr(attr_key)
      total = as + ds
      return 0.5 if total.zero?
      base = as.to_f / total
      fat_mod = (att_state.avg_fatigue - def_state.avg_fatigue) / 1000.0
      (base + fat_mod).clamp(0.15, 0.85)
    end

    # ── Possession helpers ───────────────────────────────────────────────────

    def advance_to_zone(team, zone)
      @ball[:zone]    = zone
      @ball[:team]    = team
      @ball[:carrier] = pick_carrier_for_zone(team == :home ? @home : @away, zone)
    end

    def switch_possession(new_team, new_zone, carrier)
      @ball[:team]    = new_team
      @ball[:zone]    = new_zone
      @ball[:carrier] = carrier || pick_carrier_for_zone(new_team == :home ? @home : @away, new_zone)
    end

    def mirror(home_zone, team)
      team == :home ? home_zone : home_zone.to_s.sub("home_", "away_").to_sym
    end

    def opp(side) = side == :home ? :away : :home

    def pick_carrier_for_zone(state, zone)
      pool = case zone.to_s
      when /_defense$/ then [*state.by_role(:defender), state.goalkeeper].compact
      when /_midfield$/ then state.by_role(:midfielder)
      when /_attack$/   then [*state.by_role(:striker), *state.by_role(:midfielder)]
      else state.active_players
      end
      pool = state.active_players if pool.empty?
      weighted_sample(pool, :ball_control)
    end

    def pick_striker(state)
      pool = state.by_role(:striker)
      pool = state.active_players if pool.empty?
      weighted_sample(pool, :shooting)
    end

    def pick_assister(state)
      pool = [*state.by_role(:midfielder), *state.by_role(:striker)]
      return nil if pool.empty? || rand < 0.25
      weighted_sample(pool, :vision)
    end

    def weighted_sample(players, attr_key)
      return nil if players.empty?
      weights = players.map { |p| [(p[:attrs][attr_key] || 60) * (p[:fatigue] / 100.0), 0.01].max }
      total = weights.sum
      r = rand * total; cum = 0.0
      players.zip(weights).each { |p, w| cum += w; return p if r <= cum }
      players.last
    end

    # ── Stats ───────────────────────────────────────────────────────────────

    def stats_for(side) = side == :home ? @home_stats : @away_stats
    def team_for(side)  = side == :home ? @home : @away

    def blank_stats
      { shots: 0, shots_on_target: 0, goals: 0, corners: 0,
        yellows: 0, reds: 0, saves: 0, crosses: 0 }
    end

    # ── Event emission ────────────────────────────────────────────────────────

    def emit_narrative(type, state, player, text)
      return unless text
      # Pass player info from payload if available
      payload = { zone: @ball[:zone].to_s, player: player&.dig(:known_as) }
      emit_event(type, state[:club], @minute, text, payload)
    end

    def emit_event(type, club, minute, description, payload = {})
      # Ensure we have a proper player name in the payload
      if payload[:player].nil? || payload[:player] == "—"
        # Try to extract player name from description if it's a transition event
        if type == :transition && description
          # Extract player name from description if it contains "— entra con dureza"
          if description.include?("— entra con dureza")
            # This is a fallback - we should have the player name in payload
          end
        end
      end
      
      @events << {
        club:        club,
        minute:      minute,
        added_time:  0,
        event_type:  type.to_s,
        description: description,
        payload:     payload.merge(minute: minute, team: club&.short_name)
      }
    end

    # ── Persist ────────────────────────────────────────────────────────────

    def persist_events!
      @events.each do |ev|
        # Ensure club is a Club record, not a TeamStateObject
        club = ev[:club].is_a?(Club) ? ev[:club] : 
               ev[:club].is_a?(Hash) ? ev[:club][:club] : 
               nil

        event_type = ev[:event_type].to_s
        unless MatchEvent::TYPES.include?(event_type)
          Rails.logger.warn "[MatchEngine::Simulator] Skipping invalid event_type=#{event_type.inspect}"
          next
        end

        unless club.is_a?(Club)
          Rails.logger.warn "[MatchEngine::Simulator] Skipping event without valid club: #{ev.inspect}"
          next
        end

        @match.match_events.create!(
          club:        club,
          minute:      ev[:minute],
          added_time:  ev[:added_time] || 0,
          event_type:  event_type,
          description: ev[:description],
          payload:     ev[:payload] || {}
        )
      end
    end

    def persist_lineups!
      [[@home, @match.home_club], [@away, @match.away_club]].each do |state, club|
        state ||= {}
        starters = state[:starters] || []
        bench = state[:bench] || []
        all = [*starters, *bench].compact

        position_map = {
          'AM' => 'CAM',
          'SS' => 'CF',
          'LW' => 'LW',
          'RW' => 'RW',
          'ST' => 'ST',
          'DM' => 'DM',
          'CM' => 'CM'
        }

        all.each do |p|
          next unless p.is_a?(Hash) && p[:known_as].present?

          player = Player.find_by(known_as: p[:known_as])
          next unless player
          next if Lineup.exists?(match: @match, club: club, player: player)

          status_value = (p[:on_pitch] || p[:substituted]) ? "starter" : "substitute"
          status_value = "starter" unless Lineup::STATUSES.include?(status_value)

          mapped_pos = position_map[p[:pos]] || p[:pos]
          mapped_pos = nil unless mapped_pos.is_a?(String) && Lineup::POSITIONS.include?(mapped_pos)

          shirt_number = p[:num].to_i if p[:num].present?

          @match.lineups.create!(
            club:               club,
            player:             player,
            formation_position: mapped_pos,
            shirt_number:       shirt_number,
            status:             status_value,
            minute_off:         p[:substituted] ? p[:minutes_played] : nil,
            rating:             ((6.0 + (p[:rating_delta] || 0)).clamp(1, 10)).round(1)
          )
        end
      end
    end

    # ── Team state builder ────────────────────────────────────────────────

    def build_team_state(club, competition_season, home:)
      cs      = club.club_seasons.find_by(competition_season: competition_season)
      tactic  = cs&.tactics&.find_by(active: true)
      lineup  = MatchEngine::LineupBuilder.new(cs || club).build

      raise "No lineup generated for #{club.name}" if lineup.nil? || lineup[:starters].nil?

      state = TeamStateObject.new
      state[:club]          = club
      state[:starters]      = (lineup[:starters] || []).map { |p| player_hash(p) }
      state[:bench]         = (lineup[:bench] || []).map    { |p| player_hash(p) }
      state[:morale]        = cs&.team_morale || 50
      state[:subs_used]     = 0
      state[:mentality]     = tactic&.mentality    || "balanced"
      state[:pressing]      = tactic&.pressing     || "medium"
      state[:formation]     = tactic&.formation    || "4-4-2"
      state[:passing_style] = tactic&.passing_style || "mixed"
      state[:stats]         = blank_stats
      state[:home]          = home

      state[:starters].each { |p| p[:on_pitch] = true; p[:fatigue] = 95.0 }
      state[:bench].each    { |p| p[:on_pitch] = false; p[:fatigue] = 100.0 }
      state
    end

    def player_hash(player)
      {
        id:          player.id,
        known_as:    player.known_as,
        position:    player.position,
        pos:         player.position,
        num:         player.contracts.active.first&.squad_number || 0,
        role:        player_role(player.position),
        on_pitch:    false,
        substituted: false,
        sent_off:    false,
        fatigue:     95.0,
        yellow_cards: 0,
        rating_delta: 0.0,
        minutes_played: 0,
        attrs: {
          shooting:     player.attr_shooting,
          long_shot:    player.attr_long_shot,
          reflexes:     player.attr_reflexes,
          handling:     player.attr_handling,
          diving:       player.attr_diving,
          stamina:      player.attr_stamina,
          ball_control: player.attr_ball_control,
          heading:      player.attr_heading,
          dribbling:    player.attr_dribbling,
          passing:      player.attr_passing,
          tackling:     player.attr_tackling,
          vision:       player.attr_vision,
          speed:        player.attr_speed,
        }
      }
    end

    def player_role(position)
      case position
      when "GK"                   then :goalkeeper
      when "CB", "LB", "RB", "SW" then :defender
      when "DM", "CM", "AM",
           "LW", "RW"             then :midfielder
      when "ST", "SS"             then :striker
      else                             :midfielder
      end
    end
  end

  # ── TeamStateObject (Struct-like object with helper methods) ─────────────

  class TeamStateObject < Hash
    def active_players
      (self[:starters] || []).select { |p| p[:on_pitch] && !p[:sent_off] }
    end

    def by_role(role)
      active_players.select { |p| p[:role] == role }
    end

    def short_name
      self[:club]&.short_name || "Unknown"
    end

    def goalkeeper
      active_players.find { |p| p[:role] == :goalkeeper }
    end

    def random_outfield
      pool = active_players.reject { |p| p[:role] == :goalkeeper }
      pool.sample
    end

    def avg_attr(attr_key)
      pool = active_players.reject { |p| p[:role] == :goalkeeper }
      return 60.0 if pool.empty?
      pool.sum { |p| p[:attrs][attr_key] || 60 }.to_f / pool.size
    end

    def avg_fatigue
      pool = active_players
      return 100.0 if pool.empty?
      pool.sum { |p| p[:fatigue] }.to_f / pool.size
    end

    def best_long_shot_candidate
      pool = active_players.select { |p|
        (p[:role] == :midfielder || p[:role] == :striker) &&
          (p[:attrs][:long_shot] || 0) >= MatchEngine::Simulator::LONG_SHOT_MIN_ATTR
      }
      return nil if pool.empty?
      pool.max_by { |p| (p[:attrs][:long_shot] || 0) * (p[:fatigue] / 100.0) }
    end
  end
end

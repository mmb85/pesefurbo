# ⚽ PC Fútbol · Retro Football Manager

Rails 8 clone of PC Fútbol 96/97 with Win95/CRT aesthetic, Hotwire Turbo, and a possession-state-machine match engine.

---

## Stack

| Layer | Tech |
|---|---|
| Backend | Ruby on Rails 8, PostgreSQL |
| Frontend | Hotwire (Turbo + Stimulus), Tailwind CSS |
| Jobs | Solid Queue (Rails 8 native) |
| Cable | Solid Cable (Rails 8 native) |
| CSS fonts | Press Start 2P · VT323 · Share Tech Mono |

---

## Architecture (Fake Live System)

```
[Solid Queue Job]
  MatchSimulationJob
    → MatchEngine::Simulator#run!          ← calculates full 90min in milliseconds
        → PossessionMachine (zone states)  ← coherent ball state per tick
        → LineupBuilder                    ← formation-aware lineup selection
        → NarrativeBuilder                 ← contextual narrative templates
        → saves all MatchEvents to DB
          (event_type, description, payload JSONB)

[Stimulus Controller]
  match_playback_controller.js
    → reads events JSON from DOM data attribute
    → reveals events one-by-one via setTimeout (5s interval)
    → updates scoreboard, zone indicator, narration feed
    → typewriter effect on each narrative line
```

---

## Setup

```bash
# 1. Clone / unzip project
cd pcfutbol

# 2. Install gems
bundle install

# 3. Configure database
cp config/database.yml.example config/database.yml
# Edit with your PostgreSQL credentials

# 4. Create & migrate database
rails db:create db:migrate

# 5. Seed (creates 3 clubs, Real Madrid squad, 6 fixtures, simulates 1st match)
rails db:seed

# 6. Start background job worker (Solid Queue)
bin/jobs &

# 7. Start server
bin/rails server

# 8. Open browser
open http://localhost:3000
```

---

## File Structure

```
app/
├── assets/stylesheets/
│   └── application.css              ← Win95/CRT full stylesheet
├── controllers/
│   ├── application_controller.rb
│   ├── matches_controller.rb        ← show (playback), simulate, simulate_all
│   └── clubs_controller.rb          ← index (standings), show (squad/tactic)
├── javascript/controllers/
│   ├── match_playback_controller.js ← Fake Live System (Stimulus)
│   ├── navigation_controller.js     ← Tab switching without reload
│   └── squad_panel_controller.js    ← Player card selection
├── jobs/
│   └── match_simulation_job.rb      ← Solid Queue job
├── models/
│   └── all_models.rb                ← All ActiveRecord models
├── services/match_engine/
│   ├── simulator.rb                 ← Core match engine (event-driven, ticks 1-6 min)
│   ├── lineup_builder.rb            ← Formation-aware lineup selection
│   └── narrative_builder.rb        ← 200+ narrative templates
└── views/
    ├── layouts/application.html.erb ← Win95 taskbar + CRT overlay
    ├── matches/
    │   ├── show.html.erb             ← Main match view (3 tabs: Partido/Stats/Alineaciones)
    │   └── index.html.erb            ← Calendar / fixture list
    └── clubs/
        ├── index.html.erb            ← Standings table
        └── show.html.erb             ← Club detail (squad + tactic + results)
db/
├── migrate/all_migrations.rb        ← All 7 migrations
└── seeds.rb                         ← 3 clubs + RM squad + fixtures + 1 auto-simulation
```

---

## Engine Features

### Possession State Machine
Ball has a persistent zone state across ticks:
```
home_defense → home_midfield → home_attack
                     ↕ lose_ball / tackle / interception
away_defense → away_midfield → away_attack
```
No event can fire from an incoherent zone (e.g. shot from defense).

### Transition actions per zone
| Zone | Actions |
|---|---|
| defense | build_up, long_ball, gk_kick, lose_ball |
| midfield | advance, back_pass, lose_ball, foul_won, hold_ball, **long_shot** |
| attack | shoot, cross, dribble, lose_ball, back_pass |

### Long Shot (midfield)
- Only fires if best midfielder has `attr_long_shot >= 72`
- Base probability: 4% per midfield tick (~2-3 attempts per match max)
- 2-part narrative: "sees keeper off his line..." → resolution
- Outcomes: off-target · post (rebound zone) · scramble save (+0.8 GK rating) · GOAL (+3.0 rating)

### Influencing factors
- **Player attributes** (OVR, 13 individual attrs)
- **Tactics** (formation bias, mentality ±18%, pressing multiplier)
- **Fatigue** (drain per minute × stamina factor, steep curve below 40%)
- **Home advantage** (+6% attack weight)
- **Morale** (±per goal, affects attack weight)
- **Substitutions** (sub enters at 100% fatigue — key mechanic)

---

## Turbo Streams (Real-time)

When a match finishes simulation, the job broadcasts via Turbo Streams:
- Updates the status badge in the matches index without page reload
- Any viewer on the match show page gets notified to start playback

```erb
<%= turbo_stream_from "match_#{match.id}_status" %>
```

---

## Adding more clubs / players

Edit `db/seeds.rb` following the existing pattern. Each player needs:
- All 22 attribute fields (use defaults for non-role attributes)
- An active `Contract` with `squad_number` and `role`
- A `ClubSeason` + `Tactic` for match engine access

Run `rails db:seed` again (idempotent via `find_or_create_by!`).

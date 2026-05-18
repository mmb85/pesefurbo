# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_05_17_200846) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "club_season_standings", force: :cascade do |t|
    t.bigint "club_season_id", null: false
    t.datetime "created_at", null: false
    t.integer "drawn", default: 0, null: false
    t.string "form", limit: 15
    t.integer "goal_difference", default: 0, null: false
    t.integer "goals_against", default: 0, null: false
    t.integer "goals_for", default: 0, null: false
    t.integer "lost", default: 0, null: false
    t.integer "played", default: 0, null: false
    t.integer "points", default: 0, null: false
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "won", default: 0, null: false
    t.index ["club_season_id"], name: "index_club_season_standings_on_club_season_id", unique: true
  end

  create_table "club_seasons", force: :cascade do |t|
    t.integer "board_confidence", default: 50, null: false
    t.decimal "budget_total", precision: 14, scale: 2, default: "0.0", null: false
    t.decimal "budget_transfers", precision: 14, scale: 2, default: "0.0", null: false
    t.decimal "budget_wages", precision: 14, scale: 2, default: "0.0", null: false
    t.bigint "club_id", null: false
    t.bigint "competition_season_id", null: false
    t.datetime "created_at", null: false
    t.integer "expected_position", default: 10
    t.string "form", limit: 10
    t.integer "team_morale", default: 50, null: false
    t.datetime "updated_at", null: false
    t.index ["club_id", "competition_season_id"], name: "index_club_seasons_on_club_id_and_competition_season_id", unique: true
    t.index ["club_id"], name: "index_club_seasons_on_club_id"
    t.index ["competition_season_id"], name: "index_club_seasons_on_competition_season_id"
  end

  create_table "clubs", force: :cascade do |t|
    t.string "abbr", limit: 5, null: false
    t.bigint "country_id", null: false
    t.datetime "created_at", null: false
    t.integer "founded_year"
    t.boolean "is_player_club", default: false, null: false
    t.string "name", null: false
    t.string "primary_color", limit: 7
    t.string "secondary_color", limit: 7
    t.string "short_name", limit: 25, null: false
    t.bigint "stadium_id"
    t.datetime "updated_at", null: false
    t.index ["abbr"], name: "index_clubs_on_abbr", unique: true
    t.index ["country_id"], name: "index_clubs_on_country_id"
    t.index ["stadium_id"], name: "index_clubs_on_stadium_id"
  end

  create_table "competition_seasons", force: :cascade do |t|
    t.integer "champions_spots", default: 1
    t.bigint "competition_id", null: false
    t.datetime "created_at", null: false
    t.integer "europa_spots", default: 3
    t.boolean "finished", default: false, null: false
    t.integer "relegation_spots", default: 3
    t.integer "rounds_total", default: 38, null: false
    t.bigint "season_id", null: false
    t.integer "teams_count", default: 20, null: false
    t.datetime "updated_at", null: false
    t.index ["competition_id", "season_id"], name: "index_competition_seasons_on_competition_id_and_season_id", unique: true
    t.index ["competition_id"], name: "index_competition_seasons_on_competition_id"
    t.index ["season_id"], name: "index_competition_seasons_on_season_id"
  end

  create_table "competitions", force: :cascade do |t|
    t.string "competition_type", default: "league", null: false
    t.bigint "country_id"
    t.datetime "created_at", null: false
    t.string "logo_url"
    t.string "name", null: false
    t.string "short_name", limit: 20, null: false
    t.integer "tier", default: 1, null: false
    t.datetime "updated_at", null: false
    t.index ["country_id"], name: "index_competitions_on_country_id"
  end

  create_table "contracts", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.bigint "club_id", null: false
    t.datetime "created_at", null: false
    t.date "expires_on", null: false
    t.bigint "player_id", null: false
    t.decimal "release_clause", precision: 14, scale: 2
    t.string "role", default: "squad", null: false
    t.bigint "season_id", null: false
    t.integer "squad_number"
    t.date "starts_on", null: false
    t.boolean "transfer_listed", default: false, null: false
    t.datetime "updated_at", null: false
    t.decimal "weekly_wage", precision: 12, scale: 2, null: false
    t.index ["club_id"], name: "index_contracts_on_club_id"
    t.index ["player_id", "club_id", "active"], name: "index_contracts_on_player_id_and_club_id_and_active"
    t.index ["player_id"], name: "idx_contracts_one_active_per_player", unique: true, where: "(active = true)"
    t.index ["player_id"], name: "index_contracts_on_player_id"
    t.index ["season_id"], name: "index_contracts_on_season_id"
  end

  create_table "countries", force: :cascade do |t|
    t.string "code", limit: 3, null: false
    t.datetime "created_at", null: false
    t.string "flag_emoji", limit: 4
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_countries_on_code", unique: true
  end

  create_table "game_saves", force: :cascade do |t|
    t.bigint "club_id", null: false
    t.datetime "created_at", null: false
    t.jsonb "game_state", default: {}, null: false
    t.integer "in_game_date", null: false
    t.datetime "saved_at", null: false
    t.bigint "season_id", null: false
    t.string "slot_name", limit: 50, null: false
    t.integer "slot_number", null: false
    t.datetime "updated_at", null: false
    t.index ["club_id"], name: "index_game_saves_on_club_id"
    t.index ["season_id"], name: "index_game_saves_on_season_id"
    t.index ["slot_number"], name: "index_game_saves_on_slot_number", unique: true
  end

  create_table "injuries", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.bigint "club_id", null: false
    t.datetime "created_at", null: false
    t.date "expected_return"
    t.string "injury_type", null: false
    t.bigint "match_id"
    t.integer "matches_missed", default: 0
    t.date "occurred_on", null: false
    t.bigint "player_id", null: false
    t.date "returned_on"
    t.string "severity", default: "minor", null: false
    t.datetime "updated_at", null: false
    t.index ["club_id"], name: "index_injuries_on_club_id"
    t.index ["match_id"], name: "index_injuries_on_match_id"
    t.index ["player_id"], name: "index_injuries_on_player_id"
  end

  create_table "lineups", force: :cascade do |t|
    t.bigint "club_id", null: false
    t.datetime "created_at", null: false
    t.string "formation_position", limit: 5
    t.bigint "match_id", null: false
    t.integer "minute_off"
    t.integer "minute_on", default: 0
    t.bigint "player_id", null: false
    t.integer "rating", default: 60
    t.integer "shirt_number"
    t.string "status", default: "starter", null: false
    t.datetime "updated_at", null: false
    t.index ["club_id"], name: "index_lineups_on_club_id"
    t.index ["match_id", "club_id"], name: "index_lineups_on_match_id_and_club_id"
    t.index ["match_id", "player_id"], name: "index_lineups_on_match_id_and_player_id", unique: true
    t.index ["match_id"], name: "index_lineups_on_match_id"
    t.index ["player_id"], name: "index_lineups_on_player_id"
  end

  create_table "match_events", force: :cascade do |t|
    t.integer "added_time", default: 0
    t.bigint "assist_player_id"
    t.bigint "club_id", null: false
    t.datetime "created_at", null: false
    t.string "description", limit: 500
    t.string "event_type", null: false
    t.bigint "match_id", null: false
    t.integer "minute", null: false
    t.jsonb "payload", default: {}, null: false
    t.bigint "player_id"
    t.bigint "player_off_id"
    t.datetime "updated_at", null: false
    t.index ["assist_player_id"], name: "index_match_events_on_assist_player_id"
    t.index ["club_id"], name: "index_match_events_on_club_id"
    t.index ["event_type"], name: "index_match_events_on_event_type"
    t.index ["match_id", "minute"], name: "index_match_events_on_match_id_and_minute"
    t.index ["match_id"], name: "index_match_events_on_match_id"
    t.index ["payload"], name: "index_match_events_on_payload", using: :gin
    t.index ["player_id"], name: "index_match_events_on_player_id"
    t.index ["player_off_id"], name: "index_match_events_on_player_off_id"
  end

  create_table "matches", force: :cascade do |t|
    t.integer "attendance"
    t.bigint "away_club_id", null: false
    t.integer "away_corners", default: 0
    t.integer "away_goals", default: 0
    t.integer "away_goals_ht", default: 0
    t.integer "away_possession", default: 50
    t.integer "away_red_cards", default: 0
    t.integer "away_shots", default: 0
    t.integer "away_shots_on", default: 0
    t.integer "away_yellow_cards", default: 0
    t.bigint "competition_season_id", null: false
    t.datetime "created_at", null: false
    t.integer "current_minute", default: 0
    t.bigint "home_club_id", null: false
    t.integer "home_corners", default: 0
    t.integer "home_goals", default: 0
    t.integer "home_goals_ht", default: 0
    t.integer "home_possession", default: 50
    t.integer "home_red_cards", default: 0
    t.integer "home_shots", default: 0
    t.integer "home_shots_on", default: 0
    t.integer "home_yellow_cards", default: 0
    t.datetime "kickoff_at"
    t.integer "round", null: false
    t.bigint "stadium_id"
    t.string "status", default: "scheduled", null: false
    t.datetime "updated_at", null: false
    t.index ["away_club_id"], name: "index_matches_on_away_club_id"
    t.index ["competition_season_id", "round"], name: "index_matches_on_competition_season_id_and_round"
    t.index ["competition_season_id"], name: "index_matches_on_competition_season_id"
    t.index ["home_club_id"], name: "index_matches_on_home_club_id"
    t.index ["kickoff_at"], name: "index_matches_on_kickoff_at"
    t.index ["stadium_id"], name: "index_matches_on_stadium_id"
    t.index ["status"], name: "index_matches_on_status"
  end

  create_table "news_items", force: :cascade do |t|
    t.text "body"
    t.string "category", default: "general", null: false
    t.bigint "club_id"
    t.datetime "created_at", null: false
    t.string "headline", null: false
    t.boolean "important", default: false, null: false
    t.bigint "match_id"
    t.bigint "player_id"
    t.date "published_on", null: false
    t.boolean "read", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["club_id"], name: "index_news_items_on_club_id"
    t.index ["match_id"], name: "index_news_items_on_match_id"
    t.index ["player_id"], name: "index_news_items_on_player_id"
    t.index ["published_on", "read"], name: "index_news_items_on_published_on_and_read"
  end

  create_table "player_fitnesses", force: :cascade do |t|
    t.bigint "club_season_id", null: false
    t.datetime "created_at", null: false
    t.integer "fitness", default: 100, null: false
    t.boolean "injured", default: false, null: false
    t.integer "morale", default: 50, null: false
    t.bigint "player_id", null: false
    t.boolean "suspended", default: false, null: false
    t.integer "suspension_matches_remaining", default: 0
    t.datetime "updated_at", null: false
    t.index ["club_season_id"], name: "index_player_fitnesses_on_club_season_id"
    t.index ["player_id", "club_season_id"], name: "index_player_fitnesses_on_player_id_and_club_season_id", unique: true
    t.index ["player_id"], name: "index_player_fitnesses_on_player_id"
  end

  create_table "player_season_stats", force: :cascade do |t|
    t.integer "appearances", default: 0, null: false
    t.integer "assists", default: 0, null: false
    t.integer "avg_rating", default: 60, null: false
    t.integer "clean_sheets", default: 0, null: false
    t.bigint "club_id", null: false
    t.bigint "competition_season_id", null: false
    t.datetime "created_at", null: false
    t.integer "goals", default: 0, null: false
    t.integer "goals_conceded", default: 0, null: false
    t.integer "minutes_played", default: 0, null: false
    t.bigint "player_id", null: false
    t.integer "red_cards", default: 0, null: false
    t.integer "saves", default: 0, null: false
    t.integer "shots", default: 0, null: false
    t.integer "shots_on_target", default: 0, null: false
    t.integer "starts", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "yellow_cards", default: 0, null: false
    t.index ["club_id"], name: "index_player_season_stats_on_club_id"
    t.index ["competition_season_id"], name: "index_player_season_stats_on_competition_season_id"
    t.index ["player_id", "competition_season_id"], name: "idx_on_player_id_competition_season_id_07f6ca15a7", unique: true
    t.index ["player_id"], name: "index_player_season_stats_on_player_id"
  end

  create_table "players", force: :cascade do |t|
    t.integer "attr_acceleration", default: 50, null: false
    t.integer "attr_aggression", default: 50, null: false
    t.integer "attr_ball_control", default: 50, null: false
    t.integer "attr_command", default: 50, null: false
    t.integer "attr_crossing", default: 50, null: false
    t.integer "attr_diving", default: 50, null: false
    t.integer "attr_dribbling", default: 50, null: false
    t.integer "attr_handling", default: 50, null: false
    t.integer "attr_heading", default: 50, null: false
    t.integer "attr_interceptions", default: 50, null: false
    t.integer "attr_kicking", default: 50, null: false
    t.integer "attr_long_shot", default: 50, null: false
    t.integer "attr_marking", default: 50, null: false
    t.integer "attr_passing", default: 50, null: false
    t.integer "attr_positioning", default: 50, null: false
    t.integer "attr_reflexes", default: 50, null: false
    t.integer "attr_shooting", default: 50, null: false
    t.integer "attr_speed", default: 50, null: false
    t.integer "attr_stamina", default: 50, null: false
    t.integer "attr_strength", default: 50, null: false
    t.integer "attr_tackling", default: 50, null: false
    t.integer "attr_vision", default: 50, null: false
    t.datetime "created_at", null: false
    t.date "date_of_birth", null: false
    t.string "first_name", null: false
    t.integer "growth_rate", default: 0, null: false
    t.integer "height_cm"
    t.string "known_as", null: false
    t.string "last_name", null: false
    t.decimal "market_value", precision: 14, scale: 2, default: "0.0", null: false
    t.bigint "nationality_id", null: false
    t.integer "overall_rating", default: 50, null: false
    t.string "position", limit: 3, null: false
    t.integer "potential", default: 50, null: false
    t.string "preferred_foot", limit: 5, default: "right", null: false
    t.bigint "second_nationality_id"
    t.datetime "updated_at", null: false
    t.integer "weight_kg"
    t.index ["nationality_id"], name: "index_players_on_nationality_id"
    t.index ["overall_rating"], name: "index_players_on_overall_rating"
    t.index ["position"], name: "index_players_on_position"
    t.index ["second_nationality_id"], name: "index_players_on_second_nationality_id"
  end

  create_table "scouting_reports", force: :cascade do |t|
    t.boolean "attributes_revealed", default: false, null: false
    t.bigint "club_id", null: false
    t.datetime "created_at", null: false
    t.text "notes"
    t.bigint "player_id", null: false
    t.boolean "recommended", default: false, null: false
    t.integer "scout_rating", default: 60, null: false
    t.bigint "season_id", null: false
    t.datetime "updated_at", null: false
    t.index ["club_id"], name: "index_scouting_reports_on_club_id"
    t.index ["player_id", "club_id", "season_id"], name: "index_scouting_reports_on_player_id_and_club_id_and_season_id", unique: true
    t.index ["player_id"], name: "index_scouting_reports_on_player_id"
    t.index ["season_id"], name: "index_scouting_reports_on_season_id"
  end

  create_table "seasons", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "current", default: false, null: false
    t.date "ends_on"
    t.string "name", null: false
    t.date "starts_on"
    t.datetime "updated_at", null: false
    t.integer "year_end", null: false
    t.integer "year_start", null: false
    t.index ["current"], name: "index_seasons_on_current"
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.string "concurrency_key", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error"
    t.bigint "job_id", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "active_job_id"
    t.text "arguments"
    t.string "class_name", null: false
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "finished_at"
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at"
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "queue_name", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "hostname"
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.text "metadata"
    t.string "name", null: false
    t.integer "pid", null: false
    t.bigint "supervisor_id"
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.datetime "run_at", null: false
    t.string "task_key", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.text "arguments"
    t.string "class_name"
    t.string "command", limit: 2048
    t.datetime "created_at", null: false
    t.text "description"
    t.string "key", null: false
    t.integer "priority", default: 0
    t.string "queue_name"
    t.string "schedule", null: false
    t.boolean "static", default: true, null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.integer "value", default: 1, null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "stadiums", force: :cascade do |t|
    t.integer "capacity", default: 20000, null: false
    t.string "city", null: false
    t.bigint "country_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "surface", default: "grass", null: false
    t.datetime "updated_at", null: false
    t.integer "year_built"
    t.index ["country_id"], name: "index_stadiums_on_country_id"
  end

  create_table "tactics", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.bigint "club_season_id", null: false
    t.datetime "created_at", null: false
    t.string "formation", default: "4-4-2", null: false
    t.string "mentality", default: "balanced", null: false
    t.string "name", default: "Default", null: false
    t.boolean "offside_trap", default: false, null: false
    t.string "passing_style", default: "mixed", null: false
    t.string "pressing", default: "medium", null: false
    t.string "tempo", default: "normal", null: false
    t.datetime "updated_at", null: false
    t.index ["club_season_id"], name: "index_tactics_on_club_season_id"
  end

  create_table "transfer_windows", force: :cascade do |t|
    t.boolean "active", default: false, null: false
    t.date "closes_on", null: false
    t.datetime "created_at", null: false
    t.date "opens_on", null: false
    t.bigint "season_id", null: false
    t.datetime "updated_at", null: false
    t.string "window_type", limit: 10, null: false
    t.index ["season_id"], name: "index_transfer_windows_on_season_id"
  end

  create_table "transfers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.decimal "fee", precision: 14, scale: 2, default: "0.0", null: false
    t.bigint "from_club_id"
    t.bigint "player_id", null: false
    t.bigint "season_id", null: false
    t.string "status", default: "completed", null: false
    t.bigint "to_club_id", null: false
    t.date "transfer_date", null: false
    t.string "transfer_type", default: "permanent", null: false
    t.datetime "updated_at", null: false
    t.index ["from_club_id"], name: "index_transfers_on_from_club_id"
    t.index ["player_id"], name: "index_transfers_on_player_id"
    t.index ["season_id"], name: "index_transfers_on_season_id"
    t.index ["to_club_id"], name: "index_transfers_on_to_club_id"
  end

  add_foreign_key "club_season_standings", "club_seasons"
  add_foreign_key "club_seasons", "clubs"
  add_foreign_key "club_seasons", "competition_seasons"
  add_foreign_key "clubs", "countries"
  add_foreign_key "clubs", "stadiums"
  add_foreign_key "competition_seasons", "competitions"
  add_foreign_key "competition_seasons", "seasons"
  add_foreign_key "competitions", "countries"
  add_foreign_key "contracts", "clubs"
  add_foreign_key "contracts", "players"
  add_foreign_key "contracts", "seasons"
  add_foreign_key "game_saves", "clubs"
  add_foreign_key "game_saves", "seasons"
  add_foreign_key "injuries", "clubs"
  add_foreign_key "injuries", "matches"
  add_foreign_key "injuries", "players"
  add_foreign_key "lineups", "clubs"
  add_foreign_key "lineups", "matches"
  add_foreign_key "lineups", "players"
  add_foreign_key "match_events", "clubs"
  add_foreign_key "match_events", "matches"
  add_foreign_key "match_events", "players"
  add_foreign_key "match_events", "players", column: "assist_player_id"
  add_foreign_key "match_events", "players", column: "player_off_id"
  add_foreign_key "matches", "clubs", column: "away_club_id"
  add_foreign_key "matches", "clubs", column: "home_club_id"
  add_foreign_key "matches", "competition_seasons"
  add_foreign_key "matches", "stadiums"
  add_foreign_key "news_items", "clubs"
  add_foreign_key "news_items", "matches"
  add_foreign_key "news_items", "players"
  add_foreign_key "player_fitnesses", "club_seasons"
  add_foreign_key "player_fitnesses", "players"
  add_foreign_key "player_season_stats", "clubs"
  add_foreign_key "player_season_stats", "competition_seasons"
  add_foreign_key "player_season_stats", "players"
  add_foreign_key "players", "countries", column: "nationality_id"
  add_foreign_key "players", "countries", column: "second_nationality_id"
  add_foreign_key "scouting_reports", "clubs"
  add_foreign_key "scouting_reports", "players"
  add_foreign_key "scouting_reports", "seasons"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "stadiums", "countries"
  add_foreign_key "tactics", "club_seasons"
  add_foreign_key "transfer_windows", "seasons"
  add_foreign_key "transfers", "clubs", column: "from_club_id"
  add_foreign_key "transfers", "clubs", column: "to_club_id"
  add_foreign_key "transfers", "players"
  add_foreign_key "transfers", "seasons"
end

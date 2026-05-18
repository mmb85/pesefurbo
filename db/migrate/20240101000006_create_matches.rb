# db/migrate/20240101000006_create_matches.rb
class CreateMatches < ActiveRecord::Migration[8.0]
  def change
    create_table :matches do |t|
      t.references :competition_season, null: false, foreign_key: true
      t.references :home_club, foreign_key: { to_table: :clubs }, null: false
      t.references :away_club, foreign_key: { to_table: :clubs }, null: false
      t.references :stadium,   foreign_key: { to_table: :stadiums }, null: true
      t.integer :round,        null: false
      t.datetime :kickoff_at
      t.string  :status,       null: false, default: "scheduled"

      # Score
      t.integer :home_goals,    default: 0
      t.integer :away_goals,    default: 0
      t.integer :home_goals_ht, default: 0
      t.integer :away_goals_ht, default: 0

      # Live simulation
      t.integer :current_minute, default: 0
      t.integer :attendance

      # Stats (denormalized)
      t.integer :home_shots,       default: 0
      t.integer :away_shots,       default: 0
      t.integer :home_shots_on,    default: 0
      t.integer :away_shots_on,    default: 0
      t.integer :home_possession,  default: 50
      t.integer :away_possession,  default: 50
      t.integer :home_corners,     default: 0
      t.integer :away_corners,     default: 0
      t.integer :home_yellow_cards,default: 0
      t.integer :away_yellow_cards,default: 0
      t.integer :home_red_cards,   default: 0
      t.integer :away_red_cards,   default: 0

      t.timestamps
    end
    add_index :matches, [:competition_season_id, :round]
    add_index :matches, :status
    add_index :matches, :kickoff_at

    # MatchEvent stores every tick with full payload in JSONB
    create_table :match_events do |t|
      t.references :match,  null: false, foreign_key: true
      t.references :club,   null: false, foreign_key: true
      t.references :player, foreign_key: true, null: true
      t.references :assist_player, foreign_key: { to_table: :players }, null: true
      t.references :player_off,    foreign_key: { to_table: :players }, null: true
      t.integer :minute,      null: false
      t.integer :added_time,  default: 0
      t.string  :event_type,  null: false
      # Full narrative payload — zone, narrative text, xG, etc.
      t.jsonb   :payload,     null: false, default: {}
      t.string  :description, limit: 500
      t.timestamps
    end
    add_index :match_events, [:match_id, :minute]
    add_index :match_events, :event_type
    add_index :match_events, :payload, using: :gin

    create_table :lineups do |t|
      t.references :match,  null: false, foreign_key: true
      t.references :club,   null: false, foreign_key: true
      t.references :player, null: false, foreign_key: true
      t.string  :formation_position, limit: 5
      t.integer :shirt_number
      t.string  :status,    null: false, default: "starter"
      t.integer :minute_on, default: 0
      t.integer :minute_off
      t.integer :rating,    default: 60
      t.timestamps
    end
    add_index :lineups, [:match_id, :club_id]
    add_index :lineups, [:match_id, :player_id], unique: true

    create_table :tactics do |t|
      t.references :club_season, null: false, foreign_key: true
      t.string  :name,           null: false, default: "Default"
      t.string  :formation,      null: false, default: "4-4-2"
      t.string  :mentality,      null: false, default: "balanced"
      t.string  :pressing,       null: false, default: "medium"
      t.string  :passing_style,  null: false, default: "mixed"
      t.string  :tempo,          null: false, default: "normal"
      t.boolean :offside_trap,   null: false, default: false
      t.boolean :active,         null: false, default: true
      t.timestamps
    end
  end
end

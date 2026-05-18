# db/migrate/20240101000007_create_player_stats.rb
class CreatePlayerStats < ActiveRecord::Migration[8.0]
  def change
    create_table :player_season_stats do |t|
      t.references :player,             null: false, foreign_key: true
      t.references :club,               null: false, foreign_key: true
      t.references :competition_season, null: false, foreign_key: true
      t.integer :appearances,     null: false, default: 0
      t.integer :starts,          null: false, default: 0
      t.integer :minutes_played,  null: false, default: 0
      t.integer :goals,           null: false, default: 0
      t.integer :assists,         null: false, default: 0
      t.integer :shots,           null: false, default: 0
      t.integer :shots_on_target, null: false, default: 0
      t.integer :yellow_cards,    null: false, default: 0
      t.integer :red_cards,       null: false, default: 0
      t.integer :saves,           null: false, default: 0
      t.integer :goals_conceded,  null: false, default: 0
      t.integer :clean_sheets,    null: false, default: 0
      t.integer :avg_rating,      null: false, default: 60
      t.timestamps
    end
    add_index :player_season_stats, [:player_id, :competition_season_id], unique: true

    create_table :club_season_standings do |t|
      t.references :club_season, null: false, foreign_key: true, index: false
      t.integer :position,       null: false, default: 0
      t.integer :played,         null: false, default: 0
      t.integer :won,            null: false, default: 0
      t.integer :drawn,          null: false, default: 0
      t.integer :lost,           null: false, default: 0
      t.integer :goals_for,      null: false, default: 0
      t.integer :goals_against,  null: false, default: 0
      t.integer :goal_difference,null: false, default: 0
      t.integer :points,         null: false, default: 0
      t.string  :form,           limit: 15
      t.timestamps
    end
    add_index :club_season_standings, :club_season_id, unique: true

    create_table :injuries do |t|
      t.references :player, null: false, foreign_key: true
      t.references :club,   null: false, foreign_key: true
      t.references :match,  foreign_key: true, null: true
      t.string  :injury_type,     null: false
      t.string  :severity,        null: false, default: "minor"
      t.date    :occurred_on,     null: false
      t.date    :expected_return
      t.date    :returned_on
      t.integer :matches_missed,  default: 0
      t.boolean :active,          null: false, default: true
      t.timestamps
    end

    create_table :player_fitnesses do |t|
      t.references :player,      null: false, foreign_key: true
      t.references :club_season, null: false, foreign_key: true
      t.integer :fitness,    null: false, default: 100
      t.integer :morale,     null: false, default: 50
      t.boolean :injured,    null: false, default: false
      t.boolean :suspended,  null: false, default: false
      t.integer :suspension_matches_remaining, default: 0
      t.timestamps
    end
    add_index :player_fitnesses, [:player_id, :club_season_id], unique: true

    create_table :news_items do |t|
      t.string  :headline,     null: false
      t.text    :body
      t.string  :category,     null: false, default: "general"
      t.references :club,      foreign_key: true, null: true
      t.references :player,    foreign_key: true, null: true
      t.references :match,     foreign_key: true, null: true
      t.boolean :read,         null: false, default: false
      t.boolean :important,    null: false, default: false
      t.date    :published_on, null: false
      t.timestamps
    end
    add_index :news_items, [:published_on, :read]

    create_table :game_saves do |t|
      t.string  :slot_name,   null: false, limit: 50
      t.integer :slot_number, null: false
      t.references :club,     foreign_key: true, null: false
      t.references :season,   foreign_key: true, null: false
      t.integer :in_game_date,null: false
      t.jsonb   :game_state,  null: false, default: {}
      t.datetime :saved_at,   null: false
      t.timestamps
    end
    add_index :game_saves, :slot_number, unique: true

    create_table :scouting_reports do |t|
      t.references :player, null: false, foreign_key: true
      t.references :club,   null: false, foreign_key: true
      t.references :season, null: false, foreign_key: true
      t.integer :scout_rating,         null: false, default: 60
      t.boolean :recommended,          null: false, default: false
      t.text    :notes
      t.boolean :attributes_revealed,  null: false, default: false
      t.timestamps
    end
    add_index :scouting_reports, [:player_id, :club_id, :season_id], unique: true
  end
end

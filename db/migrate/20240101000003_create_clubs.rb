# db/migrate/20240101000003_create_clubs.rb
class CreateClubs < ActiveRecord::Migration[8.0]
  def change
    create_table :stadiums do |t|
      t.string  :name,      null: false
      t.string  :city,      null: false
      t.references :country, foreign_key: true, null: false
      t.integer :capacity,  null: false, default: 20_000
      t.integer :year_built
      t.string  :surface,   null: false, default: "grass"
      t.timestamps
    end

    create_table :clubs do |t|
      t.string  :name,             null: false
      t.string  :short_name,       null: false, limit: 25
      t.string  :abbr,             null: false, limit: 5
      t.references :country,       foreign_key: true, null: false
      t.references :stadium,       null: true, foreign_key: { to_table: :stadiums }
      t.string  :primary_color,    limit: 7
      t.string  :secondary_color,  limit: 7
      t.integer :founded_year
      t.boolean :is_player_club,   null: false, default: false
      t.timestamps
    end
    add_index :clubs, :abbr, unique: true

    create_table :club_seasons do |t|
      t.references :club,               null: false, foreign_key: true
      t.references :competition_season, null: false, foreign_key: true
      t.decimal :budget_total,    precision: 14, scale: 2, null: false, default: 0
      t.decimal :budget_transfers,precision: 14, scale: 2, null: false, default: 0
      t.decimal :budget_wages,    precision: 14, scale: 2, null: false, default: 0
      t.integer :expected_position,  default: 10
      t.integer :board_confidence,   null: false, default: 50
      t.integer :team_morale,        null: false, default: 50
      t.string  :form,               limit: 10
      t.timestamps
    end
    add_index :club_seasons, [:club_id, :competition_season_id], unique: true
  end
end

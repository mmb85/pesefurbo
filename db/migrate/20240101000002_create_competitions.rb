# db/migrate/20240101000002_create_competitions.rb
class CreateCompetitions < ActiveRecord::Migration[8.0]
  def change
    create_table :competitions do |t|
      t.references :country,          foreign_key: true, null: true
      t.string  :name,                null: false
      t.string  :short_name,          null: false, limit: 20
      t.string  :competition_type,    null: false, default: "league"
      t.integer :tier,                null: false, default: 1
      t.string  :logo_url
      t.timestamps
    end

    create_table :seasons do |t|
      t.string  :name,       null: false
      t.integer :year_start, null: false
      t.integer :year_end,   null: false
      t.date    :starts_on
      t.date    :ends_on
      t.boolean :current,    null: false, default: false
      t.timestamps
    end
    add_index :seasons, :current

    create_table :competition_seasons do |t|
      t.references :competition, null: false, foreign_key: true
      t.references :season,      null: false, foreign_key: true
      t.integer :rounds_total,       null: false, default: 38
      t.integer :teams_count,        null: false, default: 20
      t.integer :relegation_spots,   default: 3
      t.integer :champions_spots,    default: 1
      t.integer :europa_spots,       default: 3
      t.boolean :finished,           null: false, default: false
      t.timestamps
    end
    add_index :competition_seasons, [:competition_id, :season_id], unique: true
  end
end

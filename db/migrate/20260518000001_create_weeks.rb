class CreateWeeks < ActiveRecord::Migration[8.0]
  def change
    create_table :weeks do |t|
      t.references :competition_season, null: false, foreign_key: true
      t.integer :week_number, null: false
      t.datetime :starts_at
      t.datetime :ends_at

      t.timestamps
    end

    add_index :weeks, [:competition_season_id, :week_number], unique: true

    # Add week_id to matches
    add_reference :matches, :week, null: true, foreign_key: true
    add_index :matches, [:week_id, :kickoff_at]
  end
end

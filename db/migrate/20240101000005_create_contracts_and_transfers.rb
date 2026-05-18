# db/migrate/20240101000005_create_contracts_and_transfers.rb
class CreateContractsAndTransfers < ActiveRecord::Migration[8.0]
  def change
    create_table :contracts do |t|
      t.references :player, null: false, foreign_key: true
      t.references :club,   null: false, foreign_key: true
      t.references :season, null: false, foreign_key: true
      t.date    :starts_on,      null: false
      t.date    :expires_on,     null: false
      t.decimal :weekly_wage,    precision: 12, scale: 2, null: false
      t.integer :squad_number
      t.string  :role,           null: false, default: "squad"
      t.boolean :active,         null: false, default: true
      t.boolean :transfer_listed,null: false, default: false
      t.decimal :release_clause, precision: 14, scale: 2, null: true
      t.timestamps
    end
    add_index :contracts, [:player_id, :club_id, :active]
    add_index :contracts, :player_id,
      where: "active = true", unique: true, name: "idx_contracts_one_active_per_player"

    create_table :transfers do |t|
      t.references :player,    null: false, foreign_key: true
      t.references :from_club, foreign_key: { to_table: :clubs }, null: true
      t.references :to_club,   foreign_key: { to_table: :clubs }, null: false
      t.references :season,    null: false, foreign_key: true
      t.date    :transfer_date, null: false
      t.decimal :fee,           precision: 14, scale: 2, null: false, default: 0
      t.string  :transfer_type, null: false, default: "permanent"
      t.string  :status,        null: false, default: "completed"
      t.timestamps
    end

    create_table :transfer_windows do |t|
      t.references :season,   null: false, foreign_key: true
      t.string  :window_type, null: false, limit: 10
      t.date    :opens_on,    null: false
      t.date    :closes_on,   null: false
      t.boolean :active,      null: false, default: false
      t.timestamps
    end
  end
end

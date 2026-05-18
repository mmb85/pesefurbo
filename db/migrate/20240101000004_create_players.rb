# db/migrate/20240101000004_create_players.rb
class CreatePlayers < ActiveRecord::Migration[8.0]
  def change
    create_table :players do |t|
      t.string  :first_name,    null: false
      t.string  :last_name,
      t.string  :known_as,      null: false
      t.references :nationality,
                   foreign_key: { to_table: :countries }, null: false
      t.references :second_nationality,
                   foreign_key: { to_table: :countries }, null: true
      t.date    :date_of_birth, null: false
      t.string  :position,      null: false, limit: 3
      t.string  :preferred_foot,null: false, default: "right", limit: 5
      t.integer :height_cm
      t.integer :weight_kg

      # Attributes
      t.integer :attr_speed,          null: false, default: 50
      t.integer :attr_acceleration,   null: false, default: 50
      t.integer :attr_stamina,        null: false, default: 50
      t.integer :attr_strength,       null: false, default: 50
      t.integer :attr_aggression,     null: false, default: 50
      t.integer :attr_shooting,       null: false, default: 50
      t.integer :attr_long_shot,      null: false, default: 50
      t.integer :attr_heading,        null: false, default: 50
      t.integer :attr_passing,        null: false, default: 50
      t.integer :attr_crossing,       null: false, default: 50
      t.integer :attr_dribbling,      null: false, default: 50
      t.integer :attr_ball_control,   null: false, default: 50
      t.integer :attr_vision,         null: false, default: 50
      t.integer :attr_positioning,    null: false, default: 50
      t.integer :attr_tackling,       null: false, default: 50
      t.integer :attr_marking,        null: false, default: 50
      t.integer :attr_interceptions,  null: false, default: 50
      t.integer :attr_reflexes,       null: false, default: 50
      t.integer :attr_handling,       null: false, default: 50
      t.integer :attr_diving,         null: false, default: 50
      t.integer :attr_kicking,        null: false, default: 50
      t.integer :attr_command,        null: false, default: 50

      t.integer :overall_rating, null: false, default: 50
      t.integer :potential,      null: false, default: 50
      t.integer :growth_rate,    null: false, default: 0
      t.decimal :market_value,   precision: 14, scale: 2, null: false, default: 0
      t.timestamps
    end
    add_index :players, :position
    add_index :players, :overall_rating
  end
end

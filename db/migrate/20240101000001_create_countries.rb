# db/migrate/20240101000001_create_countries.rb
class CreateCountries < ActiveRecord::Migration[8.0]
  def change
    create_table :countries do |t|
      t.string :name,       null: false
      t.string :code,       null: false, limit: 3
      t.string :flag_emoji, limit: 4
      t.timestamps
    end
    add_index :countries, :code, unique: true
  end
end

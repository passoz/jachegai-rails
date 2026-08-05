class CreateMarketplaceSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :marketplace_settings, id: :string do |t|
      t.string :key, null: false
      t.text :value, null: false
      t.datetime :effective_at, null: false
      t.string :actor_id, null: false
      t.string :reason

      t.timestamps
    end

    add_index :marketplace_settings, [ :key, :effective_at ]
  end
end

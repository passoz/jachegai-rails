class CreateSellerSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :seller_settings, id: :string, primary_key: :id do |t|
      t.references :seller, type: :string, null: false, foreign_key: true, index: { unique: true }
      t.string :currency, null: false, default: "BRL"
      t.boolean :auto_accept_orders, null: false, default: false
      t.integer :preparation_time_minutes, null: false, default: 30
      t.timestamps
    end
  end
end

class CreateInventoryItems < ActiveRecord::Migration[8.1]
  def change
    create_table :inventory_items, id: :string, primary_key: :id do |t|
      t.references :seller, type: :string, null: false, foreign_key: true
      t.references :product, type: :string, null: false, foreign_key: true, index: { unique: true }
      t.integer :quantity, null: false, default: 0
      t.timestamps
    end

    add_check_constraint :inventory_items, "quantity >= 0", name: "inventory_quantity_non_negative"
  end
end

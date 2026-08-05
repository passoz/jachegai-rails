class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products, id: :string, primary_key: :id do |t|
      t.references :seller, type: :string, null: false, foreign_key: true
      t.references :category, type: :string, null: true, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.integer :price_cents, null: false, default: 0
      t.string :currency, null: false, default: "BRL"
      t.boolean :active, null: false, default: true
      t.timestamps
    end

    add_index :products, [ :seller_id, :active ]
  end
end

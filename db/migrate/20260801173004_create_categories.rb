class CreateCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :categories, id: :string, primary_key: :id do |t|
      t.references :seller, type: :string, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :position, null: false, default: 0
      t.timestamps
    end

    add_index :categories, [ :seller_id, :name ], unique: true
    add_index :categories, [ :seller_id, :position ]
  end
end

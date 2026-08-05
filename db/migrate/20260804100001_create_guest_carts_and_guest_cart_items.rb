class CreateGuestCartsAndGuestCartItems < ActiveRecord::Migration[8.1]
  def change
    create_table :guest_carts, id: :string do |t|
      t.string :token_digest, null: false
      t.string :seller_id
      t.datetime :expires_at, null: false

      t.timestamps
    end

    add_index :guest_carts, :token_digest, unique: true
    add_index :guest_carts, :expires_at
    add_foreign_key :guest_carts, :sellers, column: :seller_id, on_delete: :nullify

    create_table :guest_cart_items, id: :string do |t|
      t.string :guest_cart_id, null: false
      t.string :product_id, null: false
      t.integer :quantity, null: false

      t.timestamps
    end

    add_index :guest_cart_items, [ :guest_cart_id, :product_id ], unique: true
    add_foreign_key :guest_cart_items, :guest_carts, column: :guest_cart_id, on_delete: :cascade
    add_foreign_key :guest_cart_items, :products, column: :product_id, on_delete: :cascade

    add_check_constraint :guest_cart_items, "quantity > 0", name: "guest_cart_items_quantity_positive"
  end
end

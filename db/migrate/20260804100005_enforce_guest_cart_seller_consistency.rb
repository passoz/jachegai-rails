class EnforceGuestCartSellerConsistency < ActiveRecord::Migration[8.1]
  def up
    add_column :guest_cart_items, :seller_id, :string

    execute <<~SQL
      UPDATE guest_cart_items
      SET seller_id = (
        SELECT seller_id FROM products WHERE products.id = guest_cart_items.product_id
      )
    SQL

    change_column_null :guest_cart_items, :seller_id, false

    add_index :guest_carts, [ :id, :seller_id ], unique: true, name: "index_guest_carts_on_id_and_seller_id"
    add_index :products, [ :id, :seller_id ], unique: true, name: "index_products_on_id_and_seller_id"
    add_index :guest_cart_items, :seller_id

    add_foreign_key :guest_cart_items,
                    :guest_carts,
                    column: [ :guest_cart_id, :seller_id ],
                    primary_key: [ :id, :seller_id ],
                    name: "fk_guest_cart_items_cart_seller"
    add_foreign_key :guest_cart_items,
                    :products,
                    column: [ :product_id, :seller_id ],
                    primary_key: [ :id, :seller_id ],
                    name: "fk_guest_cart_items_product_seller"
  end

  def down
    remove_foreign_key :guest_cart_items, name: "fk_guest_cart_items_product_seller"
    remove_foreign_key :guest_cart_items, name: "fk_guest_cart_items_cart_seller"
    remove_index :guest_cart_items, :seller_id
    remove_index :products, name: "index_products_on_id_and_seller_id"
    remove_index :guest_carts, name: "index_guest_carts_on_id_and_seller_id"
    remove_column :guest_cart_items, :seller_id
  end
end

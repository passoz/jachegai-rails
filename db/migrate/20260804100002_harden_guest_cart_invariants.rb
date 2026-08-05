class HardenGuestCartInvariants < ActiveRecord::Migration[8.1]
  MAX_QUANTITY = 100

  def up
    add_check_constraint :guest_cart_items,
                         "quantity > 0 AND quantity <= #{MAX_QUANTITY}",
                         name: "guest_cart_items_quantity_bounded"
  end

  def down
    remove_check_constraint :guest_cart_items, name: "guest_cart_items_quantity_bounded"
  end
end

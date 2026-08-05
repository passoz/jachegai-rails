class DropLegacyGuestCartSqliteTriggers < ActiveRecord::Migration[8.1]
  def up
    execute "DROP TRIGGER IF EXISTS guest_carts_empty_before_clearing_seller"
    execute "DROP TRIGGER IF EXISTS guest_carts_seller_matches_items_before_update"
    execute "DROP TRIGGER IF EXISTS guest_cart_items_assign_seller_after_insert"
    execute "DROP TRIGGER IF EXISTS guest_cart_items_seller_matches_cart_before_insert"
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "Legacy SQLite triggers are intentionally not restored"
  end
end

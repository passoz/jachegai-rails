class EnforceOneActiveOrderPerCourier < ActiveRecord::Migration[8.1]
  def change
    add_index :orders,
      :courier_id,
      unique: true,
      where: "courier_id IS NOT NULL AND status IN ('assigned', 'picked_up')",
      name: "index_orders_on_one_active_delivery_per_courier"
  end
end

class AddCourierToOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :courier_id, :string
    add_index :orders, :courier_id
    add_foreign_key :orders, :couriers, column: :courier_id
  end
end

class MoveCustomerExperienceOwnershipToCustomers < ActiveRecord::Migration[8.1]
  TABLES = %i[addresses favorites carts].freeze

  def up
    TABLES.each do |table|
      add_column table, :customer_id, :string
      execute <<~SQL
        UPDATE #{table}
        SET customer_id = (
          SELECT customers.id
          FROM customers
          WHERE customers.user_id = #{table}.user_id
        )
      SQL
      change_column_null table, :customer_id, false
      add_foreign_key table, :customers, column: :customer_id
    end

    remove_index :addresses, name: "index_addresses_on_user_id_and_is_default"
    add_index :addresses, [ :customer_id, :is_default ], unique: true, where: "is_default = 1"

    remove_index :favorites, name: "index_favorites_on_user_id_and_seller_id"
    add_index :favorites, [ :customer_id, :seller_id ], unique: true

    remove_index :carts, name: "index_carts_on_user_id"
    add_index :carts, :customer_id, unique: true

    TABLES.each do |table|
      remove_foreign_key table, :users
      remove_column table, :user_id
    end
  end

  def down
    TABLES.each do |table|
      add_column table, :user_id, :string
      execute <<~SQL
        UPDATE #{table}
        SET user_id = (
          SELECT customers.user_id
          FROM customers
          WHERE customers.id = #{table}.customer_id
        )
      SQL
      change_column_null table, :user_id, false
      add_foreign_key table, :users, column: :user_id
    end

    remove_index :addresses, name: "index_addresses_on_customer_id_and_is_default"
    add_index :addresses, [ :user_id, :is_default ], unique: true, where: "is_default = 1"

    remove_index :favorites, name: "index_favorites_on_customer_id_and_seller_id"
    add_index :favorites, [ :user_id, :seller_id ], unique: true

    remove_index :carts, name: "index_carts_on_customer_id"
    add_index :carts, :user_id, unique: true

    TABLES.each do |table|
      remove_foreign_key table, :customers
      remove_column table, :customer_id
    end
  end
end

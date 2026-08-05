require "test_helper"

class SQLiteBaselineTest < ActiveSupport::TestCase
  def connection
    ActiveRecord::Base.connection
  end

  test "SQLite foreign keys are enabled" do
    result = connection.execute("PRAGMA foreign_keys").first
    assert_equal 1, result["foreign_keys"], "Foreign keys must be ON"
  end

  test "SQLite journal mode is WAL" do
    result = connection.execute("PRAGMA journal_mode").first
    assert_equal "wal", result["journal_mode"], "Journal mode must be WAL"
  end

  test "SQLite busy timeout is configured" do
    result = connection.execute("PRAGMA busy_timeout").first
    timeout = result["timeout"]
    assert timeout.to_i > 0, "Busy timeout must be greater than 0"
  end

  test "readiness query succeeds when DB is accessible" do
    result = connection.execute("SELECT 1 AS ready")
    assert_equal 1, result.first["ready"], "DB must be accessible"
  end

  test "SQLite supports concurrent reads" do
    # WAL mode allows concurrent reads
    result = connection.execute("PRAGMA journal_mode").first
    assert_equal "wal", result["journal_mode"], "WAL mode required for concurrent reads"
  end

  test "customer experience database invariants are present" do
    customer_index = connection.indexes(:customers).find { |index| index.columns == [ "user_id" ] }
    assert customer_index&.unique, "one buyer profile per user must be database-enforced"

    address_default_index = connection.indexes(:addresses).find do |index|
      index.columns == %w[customer_id is_default]
    end
    assert address_default_index&.unique, "one default address per customer must be database-enforced"
    assert_equal "is_default = 1", address_default_index.where

    favorite_index = connection.indexes(:favorites).find do |index|
      index.columns == %w[customer_id seller_id]
    end
    assert favorite_index&.unique, "a seller may be favorited once per customer"

    cart_index = connection.indexes(:carts).find { |index| index.columns == [ "customer_id" ] }
    assert cart_index&.unique, "the selected strict policy permits one persistent cart per customer"

    %i[addresses favorites carts].each do |table|
      foreign_key = connection.foreign_keys(table).find { |key| key.to_table == "customers" }
      assert_equal "customer_id", foreign_key&.options&.fetch(:column), "#{table} must belong to a customer profile"
    end

    cart_item_foreign_keys = connection.foreign_keys(:cart_items)
    assert cart_item_foreign_keys.any? { |key|
      key.to_table == "carts" && key.options[:column] == %w[cart_id seller_id] && key.options[:primary_key] == %w[id seller_id]
    }, "cart item and cart seller must match"
    assert cart_item_foreign_keys.any? { |key|
      key.to_table == "products" && key.options[:column] == %w[product_id seller_id] && key.options[:primary_key] == %w[id seller_id]
    }, "cart item and product seller must match"

    quantity_constraint = connection.check_constraints(:cart_items).find do |constraint|
      constraint.name == "cart_items_quantity_bounded"
    end
    assert quantity_constraint, "cart quantity bounds must be database-enforced"
  end

  test "checkout database invariants are present" do
    payment_order_index = connection.indexes(:payments).find { |index| index.columns == [ "order_id" ] }
    assert payment_order_index&.unique, "each order must have exactly one payment"

    idempotency_index = connection.indexes(:idempotency_records).find do |index|
      index.columns == %w[principal_id operation key]
    end
    assert idempotency_index&.unique, "idempotency keys must be unique in principal and operation scope"

    movement_index = connection.indexes(:inventory_movements).find do |index|
      index.columns == %w[order_id product_id kind]
    end
    assert movement_index&.unique, "inventory movement must be unique per order product and kind"

    outbox_index = connection.indexes(:outbox_events).find { |index| index.columns == [ "event_key" ] }
    assert outbox_index&.unique, "outbox event keys must be unique"

    assert connection.check_constraints(:orders).any? { |constraint| constraint.name == "orders_total_consistent" }
    assert connection.check_constraints(:orders).any? { |constraint| constraint.name == "orders_status_valid" }
    assert connection.check_constraints(:order_items).any? { |constraint| constraint.name == "order_items_money_consistent" }
    assert connection.check_constraints(:outbox_events).any? { |constraint| constraint.name == "outbox_events_attempts_valid" }

    order_item_foreign_keys = connection.foreign_keys(:order_items)
    order_item_fk = order_item_foreign_keys.find { |key| key.to_table == "orders" && key.options[:column] == "order_id" }
    assert_nil order_item_fk&.options&.fetch(:on_delete), "order snapshots must not cascade-delete"
    assert order_item_foreign_keys.any? { |key|
      key.to_table == "orders" && key.options[:column] == %w[order_id seller_id] && key.options[:primary_key] == %w[id seller_id]
    }, "order item seller must match its order seller"
    assert order_item_foreign_keys.any? { |key|
      key.to_table == "products" && key.options[:column] == %w[product_id seller_id] && key.options[:primary_key] == %w[id seller_id]
    }, "order item product must match its seller"

    movement_foreign_keys = connection.foreign_keys(:inventory_movements)
    assert movement_foreign_keys.any? { |key|
      key.to_table == "orders" && key.options[:column] == %w[order_id seller_id] && key.options[:primary_key] == %w[id seller_id]
    }, "inventory movement seller must match its order seller"
    assert movement_foreign_keys.any? { |key|
      key.to_table == "products" && key.options[:column] == %w[product_id seller_id] && key.options[:primary_key] == %w[id seller_id]
    }, "inventory movement product must match its seller"

    history_fk = connection.foreign_keys(:order_status_histories).find { |key| key.to_table == "orders" }
    assert_nil history_fk&.options&.fetch(:on_delete), "order history must not cascade-delete"
  end

  test "courier workflow database invariants are present" do
    user_index = connection.indexes(:couriers).find { |index| index.columns == [ "user_id" ] }
    document_index = connection.indexes(:couriers).find { |index| index.columns == [ "document_number" ] }
    active_index = connection.indexes(:orders).find { |index| index.name == "index_orders_on_one_active_delivery_per_courier" }

    assert user_index&.unique, "one courier profile per user must be database-enforced"
    assert document_index&.unique, "courier document number must be unique"
    assert active_index&.unique, "a courier may have at most one assigned or picked-up order"
    assert_equal "courier_id IS NOT NULL AND status IN ('assigned', 'picked_up')", active_index.where
    assert connection.check_constraints(:couriers).any? { |constraint| constraint.name == "couriers_unapproved_must_be_offline" }
    assert connection.foreign_keys(:orders).any? { |foreign_key|
      foreign_key.to_table == "couriers" && foreign_key.options[:column] == "courier_id"
    }
  end

  test "order validation tolerates a pre-courier schema during rolling migration" do
    order = Order.new(status: "ready")
    original_has_attribute = order.method(:has_attribute?)
    order.define_singleton_method(:has_attribute?) do |name|
      name.to_sym == :courier_id ? false : original_has_attribute.call(name)
    end

    assert_nothing_raised { order.valid? }
  end

  test "seller domain database invariants are present" do
    membership_index = connection.indexes(:seller_memberships).find { |index| index.columns == [ "user_id" ] }
    assert membership_index&.unique, "seller membership user index must be unique"

    moderation_constraint = connection.check_constraints(:sellers).find do |constraint|
      constraint.name == "seller_moderation_state_valid"
    end
    assert moderation_constraint, "seller moderation state CHECK must exist"

    category_position_index = connection.indexes(:categories).find do |index|
      index.columns == %w[seller_id position]
    end
    assert category_position_index&.unique, "category position index must be seller-scoped and unique"
  end
end

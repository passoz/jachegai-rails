class CreateCheckoutDomain < ActiveRecord::Migration[8.1]
  def up
    create_table :orders, id: :string do |t|
      t.references :customer, null: false, type: :string, foreign_key: true
      t.references :seller, null: false, type: :string, foreign_key: true
      t.references :source_address, null: true, type: :string, foreign_key: { to_table: :addresses, on_delete: :nullify }
      t.string :status, null: false, default: "pending"
      t.string :currency, null: false
      t.integer :subtotal_cents, null: false
      t.integer :delivery_fee_cents, null: false, default: 0
      t.integer :discount_cents, null: false, default: 0
      t.integer :courier_fee_cents, null: false, default: 0
      t.integer :total_cents, null: false
      t.string :address_name, null: false
      t.string :address_line1, null: false
      t.string :address_city, null: false
      t.string :address_state, null: false
      t.string :address_zip, null: false
      t.string :address_country, null: false
      t.timestamps
    end
    add_check_constraint :orders, "status IN ('pending','accepted','rejected','preparing','ready','assigned','picked_up','delivered','cancelled')", name: "orders_status_valid"
    add_check_constraint :orders, "currency GLOB '[A-Z][A-Z][A-Z]'", name: "orders_currency_valid"
    add_check_constraint :orders, "subtotal_cents >= 0 AND delivery_fee_cents >= 0 AND discount_cents >= 0 AND courier_fee_cents >= 0 AND total_cents >= 0", name: "orders_money_non_negative"
    add_check_constraint :orders, "total_cents = subtotal_cents + delivery_fee_cents - discount_cents", name: "orders_total_consistent"
    add_index :orders, [ :customer_id, :created_at, :id ]
    add_index :orders, [ :seller_id, :created_at, :id ]
    add_index :orders, [ :id, :seller_id ], unique: true

    create_table :order_items, id: :string do |t|
      t.references :order, null: false, type: :string, foreign_key: true
      t.references :product, null: true, type: :string, foreign_key: { on_delete: :nullify }
      t.references :seller, null: false, type: :string, foreign_key: true
      t.string :product_name, null: false
      t.integer :quantity, null: false
      t.integer :unit_price_cents, null: false
      t.integer :subtotal_cents, null: false
      t.string :currency, null: false
      t.timestamps
    end
    add_check_constraint :order_items, "quantity > 0 AND quantity <= 100", name: "order_items_quantity_bounded"
    add_check_constraint :order_items, "unit_price_cents >= 0 AND subtotal_cents = unit_price_cents * quantity", name: "order_items_money_consistent"
    add_check_constraint :order_items, "currency GLOB '[A-Z][A-Z][A-Z]'", name: "order_items_currency_valid"
    add_index :order_items, [ :order_id, :product_id ], unique: true
    add_foreign_key :order_items, :orders, column: [ :order_id, :seller_id ], primary_key: [ :id, :seller_id ]
    add_foreign_key :order_items, :products, column: [ :product_id, :seller_id ], primary_key: [ :id, :seller_id ]

    create_table :order_status_histories, id: :string do |t|
      t.references :order, null: false, type: :string, foreign_key: true
      t.string :from_status
      t.string :to_status, null: false
      t.string :actor_principal_id, null: false
      t.string :reason
      t.string :request_id
      t.datetime :occurred_at, null: false
      t.timestamps
    end
    add_index :order_status_histories, [ :order_id, :occurred_at, :id ]

    create_table :payments, id: :string do |t|
      t.references :order, null: false, type: :string, foreign_key: true, index: { unique: true }
      t.string :state, null: false, default: "pending"
      t.string :method, null: false, default: "simulated"
      t.string :provider, null: false, default: "simulated"
      t.string :external_reference
      t.integer :amount_cents, null: false
      t.string :currency, null: false
      t.string :last_error_code
      t.timestamps
    end
    add_check_constraint :payments, "state IN ('pending','paid','failed','refunded')", name: "payments_state_valid"
    add_check_constraint :payments, "amount_cents >= 0", name: "payments_amount_non_negative"
    add_check_constraint :payments, "currency GLOB '[A-Z][A-Z][A-Z]'", name: "payments_currency_valid"
    add_index :payments, :external_reference, unique: true, where: "external_reference IS NOT NULL"

    create_table :idempotency_records, id: :string do |t|
      t.string :principal_id, null: false
      t.string :operation, null: false
      t.string :key, null: false
      t.string :request_digest, null: false
      t.string :state, null: false, default: "processing"
      t.string :resource_type
      t.string :resource_id
      t.integer :response_status
      t.text :response_body
      t.string :last_error_code
      t.datetime :locked_at
      t.datetime :completed_at
      t.timestamps
    end
    add_index :idempotency_records, [ :principal_id, :operation, :key ], unique: true, name: "index_idempotency_records_on_scope_and_key"
    add_check_constraint :idempotency_records, "state IN ('processing','completed','failed')", name: "idempotency_records_state_valid"

    create_table :inventory_movements, id: :string do |t|
      t.references :order, null: false, type: :string, foreign_key: true
      t.references :product, null: false, type: :string, foreign_key: true
      t.references :seller, null: false, type: :string, foreign_key: true
      t.string :kind, null: false
      t.integer :quantity, null: false
      t.integer :balance_after, null: false
      t.timestamps
    end
    add_index :inventory_movements, [ :order_id, :product_id, :kind ], unique: true, name: "index_inventory_movements_on_order_product_kind"
    add_foreign_key :inventory_movements, :orders, column: [ :order_id, :seller_id ], primary_key: [ :id, :seller_id ]
    add_foreign_key :inventory_movements, :products, column: [ :product_id, :seller_id ], primary_key: [ :id, :seller_id ]
    add_check_constraint :inventory_movements, "kind IN ('checkout_decrement','restore')", name: "inventory_movements_kind_valid"
    add_check_constraint :inventory_movements, "quantity > 0 AND balance_after >= 0", name: "inventory_movements_quantity_valid"

    create_table :outbox_events, id: :string do |t|
      t.string :event_key, null: false
      t.string :event_type, null: false
      t.string :aggregate_type, null: false
      t.string :aggregate_id, null: false
      t.text :payload, null: false
      t.string :state, null: false, default: "pending"
      t.integer :attempts, null: false, default: 0
      t.integer :max_attempts, null: false, default: 10
      t.text :last_error
      t.datetime :available_at, null: false
      t.datetime :locked_at
      t.datetime :completed_at
      t.timestamps
    end
    add_index :outbox_events, :event_key, unique: true
    add_index :outbox_events, [ :state, :available_at ]
    add_check_constraint :outbox_events, "state IN ('pending','processing','completed','dead_letter')", name: "outbox_events_state_valid"
    add_check_constraint :outbox_events, "attempts >= 0 AND max_attempts > 0", name: "outbox_events_attempts_valid"
  end

  def down
    drop_table :outbox_events
    drop_table :inventory_movements
    drop_table :idempotency_records
    drop_table :payments
    drop_table :order_status_histories
    drop_table :order_items
    drop_table :orders
  end
end

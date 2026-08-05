# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_08_04_233241) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "addresses", id: :string, force: :cascade do |t|
    t.string "city", null: false
    t.string "country", default: "BR", null: false
    t.datetime "created_at", null: false
    t.string "customer_id", null: false
    t.boolean "is_default", default: false, null: false
    t.string "line1", null: false
    t.string "name", null: false
    t.string "state", null: false
    t.datetime "updated_at", null: false
    t.string "zip", null: false
    t.index ["customer_id", "is_default"], name: "index_addresses_on_customer_id_and_is_default", unique: true, where: "is_default = 1"
  end

  create_table "audit_records", id: :string, force: :cascade do |t|
    t.string "action", null: false
    t.string "actor_principal_id", null: false
    t.string "correlation_id"
    t.datetime "created_at", null: false
    t.text "metadata"
    t.string "reason"
    t.string "resource_id", null: false
    t.string "resource_type", null: false
    t.string "result", default: "success", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_principal_id"], name: "index_audit_records_on_actor_principal_id"
    t.index ["correlation_id"], name: "index_audit_records_on_correlation_id"
    t.index ["resource_type", "resource_id"], name: "index_audit_records_on_resource_type_and_resource_id"
  end

  create_table "cart_items", id: :text, force: :cascade do |t|
    t.text "cart_id", null: false
    t.datetime "created_at", null: false
    t.text "product_id", null: false
    t.integer "quantity", null: false
    t.text "seller_id", null: false
    t.datetime "updated_at", null: false
    t.index ["cart_id", "product_id"], name: "index_cart_items_on_cart_id_and_product_id", unique: true
    t.check_constraint "quantity > 0 AND quantity <= 100", name: "cart_items_quantity_bounded"
  end

  create_table "carts", id: :string, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "customer_id", null: false
    t.string "seller_id"
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_carts_on_customer_id", unique: true
    t.index ["id", "seller_id"], name: "index_carts_on_id_and_seller_id", unique: true
  end

  create_table "categories", id: :string, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.string "seller_id", null: false
    t.datetime "updated_at", null: false
    t.index ["seller_id", "name"], name: "index_categories_on_seller_id_and_name", unique: true
    t.index ["seller_id", "position"], name: "index_categories_on_seller_id_and_position", unique: true
    t.index ["seller_id"], name: "index_categories_on_seller_id"
  end

  create_table "courier_locations", id: :string, force: :cascade do |t|
    t.float "accuracy_meters"
    t.string "courier_id", null: false
    t.datetime "created_at", null: false
    t.float "latitude", null: false
    t.float "longitude", null: false
    t.datetime "recorded_at", null: false
    t.datetime "updated_at", null: false
    t.index ["courier_id", "recorded_at"], name: "index_courier_locations_on_courier_and_recorded_at"
    t.check_constraint "latitude >= -90.0 AND latitude <= 90.0 AND longitude >= -180.0 AND longitude <= 180.0", name: "courier_locations_coordinates_check"
  end

  create_table "couriers", id: :string, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "document_number", null: false
    t.datetime "location_consent_given_at"
    t.string "moderation_state", default: "pending_review", null: false
    t.string "operational_state", default: "offline", null: false
    t.string "phone", null: false
    t.datetime "updated_at", null: false
    t.string "user_id", null: false
    t.string "vehicle_plate"
    t.string "vehicle_type", null: false
    t.index ["document_number"], name: "index_couriers_on_document_number", unique: true
    t.index ["user_id"], name: "index_couriers_on_user_id", unique: true
    t.check_constraint "moderation_state = 'approved' OR operational_state = 'offline'", name: "couriers_unapproved_must_be_offline"
    t.check_constraint "moderation_state IN ('pending_review', 'approved', 'rejected', 'suspended')", name: "couriers_moderation_state_check"
    t.check_constraint "operational_state IN ('offline', 'available', 'on_delivery')", name: "couriers_operational_state_check"
    t.check_constraint "vehicle_type IN ('motorcycle', 'bicycle', 'car', 'foot')", name: "couriers_vehicle_type_check"
  end

  create_table "customers", id: :string, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "full_name", null: false
    t.string "phone"
    t.datetime "updated_at", null: false
    t.string "user_id", null: false
    t.index ["user_id"], name: "index_customers_on_user_id", unique: true
  end

  create_table "favorites", id: :string, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "customer_id", null: false
    t.string "seller_id", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id", "seller_id"], name: "index_favorites_on_customer_id_and_seller_id", unique: true
  end

  create_table "guest_cart_items", id: :string, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "guest_cart_id", null: false
    t.string "product_id", null: false
    t.integer "quantity", null: false
    t.string "seller_id", null: false
    t.datetime "updated_at", null: false
    t.index ["guest_cart_id", "product_id"], name: "index_guest_cart_items_on_guest_cart_id_and_product_id", unique: true
    t.index ["seller_id"], name: "index_guest_cart_items_on_seller_id"
    t.check_constraint "quantity > 0 AND quantity <= 100", name: "guest_cart_items_quantity_bounded"
    t.check_constraint "quantity > 0", name: "guest_cart_items_quantity_positive"
  end

  create_table "guest_carts", id: :string, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "seller_id"
    t.string "token_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_guest_carts_on_expires_at"
    t.index ["id", "seller_id"], name: "index_guest_carts_on_id_and_seller_id", unique: true
    t.index ["token_digest"], name: "index_guest_carts_on_token_digest", unique: true
  end

  create_table "idempotency_records", id: :string, force: :cascade do |t|
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.string "key", null: false
    t.string "last_error_code"
    t.datetime "locked_at"
    t.string "operation", null: false
    t.string "principal_id", null: false
    t.string "request_digest", null: false
    t.string "resource_id"
    t.string "resource_type"
    t.text "response_body"
    t.integer "response_status"
    t.string "state", default: "processing", null: false
    t.datetime "updated_at", null: false
    t.index ["principal_id", "operation", "key"], name: "index_idempotency_records_on_scope_and_key", unique: true
    t.check_constraint "state IN ('processing','completed','failed')", name: "idempotency_records_state_valid"
  end

  create_table "inventory_items", id: :string, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "product_id", null: false
    t.integer "quantity", default: 0, null: false
    t.string "seller_id", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_inventory_items_on_product_id", unique: true
    t.index ["seller_id"], name: "index_inventory_items_on_seller_id"
    t.check_constraint "quantity >= 0", name: "inventory_quantity_non_negative"
  end

  create_table "inventory_movements", id: :string, force: :cascade do |t|
    t.integer "balance_after", null: false
    t.datetime "created_at", null: false
    t.string "kind", null: false
    t.string "order_id", null: false
    t.string "product_id", null: false
    t.integer "quantity", null: false
    t.string "seller_id", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id", "product_id", "kind"], name: "index_inventory_movements_on_order_product_kind", unique: true
    t.index ["order_id"], name: "index_inventory_movements_on_order_id"
    t.index ["product_id"], name: "index_inventory_movements_on_product_id"
    t.index ["seller_id"], name: "index_inventory_movements_on_seller_id"
    t.check_constraint "kind IN ('checkout_decrement','restore')", name: "inventory_movements_kind_valid"
    t.check_constraint "quantity > 0 AND balance_after >= 0", name: "inventory_movements_quantity_valid"
  end

  create_table "invoices", id: :string, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "currency", default: "BRL", null: false
    t.integer "fee_amount_cents", default: 0, null: false
    t.integer "gross_amount_cents", default: 0, null: false
    t.integer "net_amount_cents", default: 0, null: false
    t.datetime "paid_at"
    t.date "period_end", null: false
    t.date "period_start", null: false
    t.string "seller_id", null: false
    t.string "state", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["seller_id", "period_start", "period_end"], name: "idx_invoices_seller_period", unique: true
  end

  create_table "marketplace_settings", id: :string, force: :cascade do |t|
    t.string "actor_id", null: false
    t.datetime "created_at", null: false
    t.datetime "effective_at", null: false
    t.string "key", null: false
    t.string "reason"
    t.datetime "updated_at", null: false
    t.text "value", null: false
    t.index ["key", "effective_at"], name: "index_marketplace_settings_on_key_and_effective_at"
  end

  create_table "order_items", id: :string, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "currency", null: false
    t.string "order_id", null: false
    t.string "product_id"
    t.string "product_name", null: false
    t.integer "quantity", null: false
    t.string "seller_id", null: false
    t.integer "subtotal_cents", null: false
    t.integer "unit_price_cents", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id", "product_id"], name: "index_order_items_on_order_id_and_product_id", unique: true
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["product_id"], name: "index_order_items_on_product_id"
    t.index ["seller_id"], name: "index_order_items_on_seller_id"
    t.check_constraint "currency GLOB '[A-Z][A-Z][A-Z]'", name: "order_items_currency_valid"
    t.check_constraint "quantity > 0 AND quantity <= 100", name: "order_items_quantity_bounded"
    t.check_constraint "unit_price_cents >= 0 AND subtotal_cents = unit_price_cents * quantity", name: "order_items_money_consistent"
  end

  create_table "order_status_histories", id: :string, force: :cascade do |t|
    t.string "actor_principal_id", null: false
    t.datetime "created_at", null: false
    t.string "from_status"
    t.datetime "occurred_at", null: false
    t.string "order_id", null: false
    t.string "reason"
    t.string "request_id"
    t.string "to_status", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id", "occurred_at", "id"], name: "idx_on_order_id_occurred_at_id_135ceb611d"
    t.index ["order_id"], name: "index_order_status_histories_on_order_id"
  end

  create_table "orders", id: :string, force: :cascade do |t|
    t.string "address_city", null: false
    t.string "address_country", null: false
    t.string "address_line1", null: false
    t.string "address_name", null: false
    t.string "address_state", null: false
    t.string "address_zip", null: false
    t.integer "courier_fee_cents", default: 0, null: false
    t.string "courier_id"
    t.datetime "created_at", null: false
    t.string "currency", null: false
    t.string "customer_id", null: false
    t.integer "delivery_fee_cents", default: 0, null: false
    t.integer "discount_cents", default: 0, null: false
    t.string "seller_id", null: false
    t.string "source_address_id"
    t.string "status", default: "pending", null: false
    t.integer "subtotal_cents", null: false
    t.integer "total_cents", null: false
    t.datetime "updated_at", null: false
    t.index ["courier_id"], name: "index_orders_on_courier_id"
    t.index ["courier_id"], name: "index_orders_on_one_active_delivery_per_courier", unique: true, where: "courier_id IS NOT NULL AND status IN ('assigned', 'picked_up')"
    t.index ["customer_id", "created_at", "id"], name: "index_orders_on_customer_id_and_created_at_and_id"
    t.index ["customer_id"], name: "index_orders_on_customer_id"
    t.index ["id", "seller_id"], name: "index_orders_on_id_and_seller_id", unique: true
    t.index ["seller_id", "created_at", "id"], name: "index_orders_on_seller_id_and_created_at_and_id"
    t.index ["seller_id"], name: "index_orders_on_seller_id"
    t.index ["source_address_id"], name: "index_orders_on_source_address_id"
    t.check_constraint "currency GLOB '[A-Z][A-Z][A-Z]'", name: "orders_currency_valid"
    t.check_constraint "status IN ('pending','accepted','rejected','preparing','ready','assigned','picked_up','delivered','cancelled')", name: "orders_status_valid"
    t.check_constraint "subtotal_cents >= 0 AND delivery_fee_cents >= 0 AND discount_cents >= 0 AND courier_fee_cents >= 0 AND total_cents >= 0", name: "orders_money_non_negative"
    t.check_constraint "total_cents = subtotal_cents + delivery_fee_cents - discount_cents", name: "orders_total_consistent"
  end

  create_table "outbox_events", id: :string, force: :cascade do |t|
    t.string "aggregate_id", null: false
    t.string "aggregate_type", null: false
    t.integer "attempts", default: 0, null: false
    t.datetime "available_at", null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.string "event_key", null: false
    t.string "event_type", null: false
    t.text "last_error"
    t.datetime "locked_at"
    t.integer "max_attempts", default: 10, null: false
    t.text "payload", null: false
    t.string "state", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["event_key"], name: "index_outbox_events_on_event_key", unique: true
    t.index ["state", "available_at"], name: "index_outbox_events_on_state_and_available_at"
    t.check_constraint "attempts >= 0 AND max_attempts > 0", name: "outbox_events_attempts_valid"
    t.check_constraint "state IN ('pending','processing','completed','dead_letter')", name: "outbox_events_state_valid"
  end

  create_table "payments", id: :string, force: :cascade do |t|
    t.integer "amount_cents", null: false
    t.datetime "created_at", null: false
    t.string "currency", null: false
    t.string "external_reference"
    t.string "last_error_code"
    t.string "method", default: "simulated", null: false
    t.string "order_id", null: false
    t.string "provider", default: "simulated", null: false
    t.string "state", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["external_reference"], name: "index_payments_on_external_reference", unique: true, where: "external_reference IS NOT NULL"
    t.index ["order_id"], name: "index_payments_on_order_id", unique: true
    t.check_constraint "amount_cents >= 0", name: "payments_amount_non_negative"
    t.check_constraint "currency GLOB '[A-Z][A-Z][A-Z]'", name: "payments_currency_valid"
    t.check_constraint "state IN ('pending','paid','failed','refunded')", name: "payments_state_valid"
  end

  create_table "products", id: :string, force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "category_id"
    t.datetime "created_at", null: false
    t.string "currency", default: "BRL", null: false
    t.text "description"
    t.string "name", null: false
    t.integer "price_cents", default: 0, null: false
    t.string "seller_id", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_products_on_category_id"
    t.index ["id", "seller_id"], name: "index_products_on_id_and_seller_id", unique: true
    t.index ["seller_id", "active"], name: "index_products_on_seller_id_and_active"
    t.index ["seller_id"], name: "index_products_on_seller_id"
  end

  create_table "role_assignments", id: :string, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "role", null: false
    t.datetime "updated_at", null: false
    t.string "user_id", null: false
    t.index ["user_id", "role"], name: "index_role_assignments_on_user_id_and_role", unique: true
    t.index ["user_id"], name: "index_role_assignments_on_user_id"
  end

  create_table "seller_memberships", id: :string, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "role", default: "owner", null: false
    t.string "seller_id", null: false
    t.datetime "updated_at", null: false
    t.string "user_id", null: false
    t.index ["seller_id"], name: "index_seller_memberships_on_seller_id"
    t.index ["user_id"], name: "index_seller_memberships_on_user_id", unique: true
  end

  create_table "seller_settings", id: :string, force: :cascade do |t|
    t.boolean "auto_accept_orders", default: false, null: false
    t.datetime "created_at", null: false
    t.string "currency", default: "BRL", null: false
    t.integer "preparation_time_minutes", default: 30, null: false
    t.string "seller_id", null: false
    t.datetime "updated_at", null: false
    t.index ["seller_id"], name: "index_seller_settings_on_seller_id", unique: true
  end

  create_table "sellers", id: :string, force: :cascade do |t|
    t.string "address_city"
    t.string "address_country", default: "BR", null: false
    t.string "address_line1"
    t.string "address_state"
    t.string "address_zip"
    t.string "contact_email"
    t.string "contact_phone"
    t.datetime "created_at", null: false
    t.text "description"
    t.datetime "moderated_at"
    t.string "moderation_state", default: "pending_review", null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["moderation_state"], name: "index_sellers_on_moderation_state"
    t.index ["slug"], name: "index_sellers_on_slug", unique: true
    t.check_constraint "moderation_state IN ('pending_review', 'approved', 'suspended', 'rejected')", name: "seller_moderation_state_valid"
  end

  create_table "sessions", id: :string, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "ip_address"
    t.datetime "last_seen_at"
    t.datetime "revoked_at"
    t.string "token_digest", null: false
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.string "user_id", null: false
    t.index ["token_digest"], name: "index_sessions_on_token_digest", unique: true
    t.index ["user_id", "expires_at"], name: "index_sessions_on_user_id_and_expires_at"
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "ticket_messages", id: :string, force: :cascade do |t|
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.string "sender_id", null: false
    t.string "sender_role", null: false
    t.string "ticket_id", null: false
    t.datetime "updated_at", null: false
    t.index ["sender_id", "created_at", "id"], name: "index_ticket_messages_on_sender_id_and_created_at_and_id"
    t.index ["sender_id"], name: "index_ticket_messages_on_sender_id"
    t.index ["ticket_id", "created_at", "id"], name: "index_ticket_messages_on_ticket_id_and_created_at_and_id"
    t.index ["ticket_id"], name: "index_ticket_messages_on_ticket_id"
    t.check_constraint "sender_role IN ('customer', 'admin')", name: "ticket_messages_sender_role_allowed"
  end

  create_table "tickets", id: :string, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "customer_id", null: false
    t.string "order_id"
    t.string "state", default: "open", null: false
    t.string "subject", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id", "created_at", "id"], name: "index_tickets_on_customer_id_and_created_at_and_id"
    t.index ["customer_id"], name: "index_tickets_on_customer_id"
    t.index ["order_id"], name: "index_tickets_on_order_id"
    t.index ["state"], name: "index_tickets_on_state"
    t.check_constraint "state IN ('open', 'in_progress', 'resolved', 'closed')", name: "tickets_state_allowed"
  end

  create_table "uploads", id: :string, force: :cascade do |t|
    t.integer "byte_size", default: 0, null: false
    t.string "content_type", null: false
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "owner_id", null: false
    t.string "owner_type", null: false
    t.string "storage_key", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_type", "owner_id"], name: "index_uploads_on_owner_type_and_owner_id"
    t.index ["storage_key"], name: "index_uploads_on_storage_key", unique: true
  end

  create_table "users", id: :string, force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "disabled_at"
    t.string "email", null: false
    t.string "full_name", null: false
    t.string "password_digest"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "addresses", "customers"
  add_foreign_key "cart_items", "carts", column: ["cart_id", "seller_id"], primary_key: ["id", "seller_id"], on_delete: :cascade
  add_foreign_key "cart_items", "products", column: ["product_id", "seller_id"], primary_key: ["id", "seller_id"], on_delete: :cascade
  add_foreign_key "carts", "customers"
  add_foreign_key "carts", "sellers"
  add_foreign_key "categories", "sellers"
  add_foreign_key "courier_locations", "couriers"
  add_foreign_key "couriers", "users"
  add_foreign_key "customers", "users"
  add_foreign_key "favorites", "customers"
  add_foreign_key "favorites", "sellers"
  add_foreign_key "guest_cart_items", "guest_carts", column: ["guest_cart_id", "seller_id"], primary_key: ["id", "seller_id"]
  add_foreign_key "guest_cart_items", "guest_carts", on_delete: :cascade
  add_foreign_key "guest_cart_items", "products", column: ["product_id", "seller_id"], primary_key: ["id", "seller_id"]
  add_foreign_key "guest_cart_items", "products", on_delete: :cascade
  add_foreign_key "guest_carts", "sellers", on_delete: :nullify
  add_foreign_key "inventory_items", "products"
  add_foreign_key "inventory_items", "sellers"
  add_foreign_key "inventory_movements", "orders"
  add_foreign_key "inventory_movements", "orders", column: ["order_id", "seller_id"], primary_key: ["id", "seller_id"]
  add_foreign_key "inventory_movements", "products"
  add_foreign_key "inventory_movements", "products", column: ["product_id", "seller_id"], primary_key: ["id", "seller_id"]
  add_foreign_key "inventory_movements", "sellers"
  add_foreign_key "invoices", "sellers"
  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "orders", column: ["order_id", "seller_id"], primary_key: ["id", "seller_id"]
  add_foreign_key "order_items", "products", column: ["product_id", "seller_id"], primary_key: ["id", "seller_id"]
  add_foreign_key "order_items", "products", on_delete: :nullify
  add_foreign_key "order_items", "sellers"
  add_foreign_key "order_status_histories", "orders"
  add_foreign_key "orders", "addresses", column: "source_address_id", on_delete: :nullify
  add_foreign_key "orders", "couriers"
  add_foreign_key "orders", "customers"
  add_foreign_key "orders", "sellers"
  add_foreign_key "payments", "orders"
  add_foreign_key "products", "categories"
  add_foreign_key "products", "sellers"
  add_foreign_key "role_assignments", "users"
  add_foreign_key "seller_memberships", "sellers"
  add_foreign_key "seller_memberships", "users"
  add_foreign_key "seller_settings", "sellers"
  add_foreign_key "sessions", "users"
  add_foreign_key "ticket_messages", "tickets"
  add_foreign_key "ticket_messages", "users", column: "sender_id"
  add_foreign_key "tickets", "customers"
  add_foreign_key "tickets", "orders"
end

require "test_helper"

class OpenApiTest < ActiveSupport::TestCase
  OPENAPI_PATH = Rails.root.join("docs", "api", "openapi.yaml")

  test "openapi spec exists" do
    assert File.exist?(OPENAPI_PATH)
  end

  test "openapi spec is valid YAML and version 3.1" do
    spec = YAML.safe_load(File.read(OPENAPI_PATH))
    assert_equal "3.1.0", spec["openapi"]
    assert_equal "JaChegai API", spec.dig("info", "title")
  end

  test "openapi documents authentication endpoints and bearer security" do
    spec = YAML.safe_load(File.read(OPENAPI_PATH))
    assert spec.dig("paths", "/api/v1/auth/register", "post")
    assert spec.dig("paths", "/api/v1/auth/login", "post")
    assert spec.dig("paths", "/api/v1/auth/me", "get", "security")
    assert spec.dig("components", "securitySchemes", "BearerAuth")
    refute spec.dig("components", "securitySchemes", "SessionCookie")
  end

  test "openapi has health endpoints" do
    spec = YAML.safe_load(File.read(OPENAPI_PATH))
    assert spec.dig("paths", "/healthz", "get")
    assert spec.dig("paths", "/readyz", "get")
  end

  test "openapi defines envelope schema" do
    spec = YAML.safe_load(File.read(OPENAPI_PATH))
    envelope = spec.dig("components", "schemas", "Envelope")
    assert envelope
    assert_includes envelope["required"], "ok"
    assert_includes envelope["required"], "data"
    assert_includes envelope["required"], "meta"
  end

  test "openapi defines error taxonomy" do
    spec = YAML.safe_load(File.read(OPENAPI_PATH))
    codes = spec.dig("components", "schemas", "Error", "properties", "code", "enum")
    assert_includes codes, "invalid_input"
    assert_includes codes, "not_found"
    assert_includes codes, "forbidden"
    assert_includes codes, "rate_limited"
  end

  test "openapi does not advertise a cookie session" do
    spec = YAML.safe_load(File.read(OPENAPI_PATH))
    refute spec.dig("components", "securitySchemes", "SessionCookie")
  end

  test "openapi documents all phase 03 seller and admin operations" do
    spec = YAML.safe_load(File.read(OPENAPI_PATH))
    operations = {
      "/api/v1/seller/onboarding" => %w[post],
      "/api/v1/seller/profile" => %w[get patch],
      "/api/v1/seller/settings" => %w[get patch],
      "/api/v1/seller/categories" => %w[get post],
      "/api/v1/seller/categories/order" => %w[put],
      "/api/v1/seller/categories/{id}" => %w[get patch delete],
      "/api/v1/seller/products" => %w[get post],
      "/api/v1/seller/products/{id}" => %w[get patch delete],
      "/api/v1/seller/products/{id}/activate" => %w[post],
      "/api/v1/seller/products/{id}/deactivate" => %w[post],
      "/api/v1/seller/inventory" => %w[get],
      "/api/v1/seller/inventory/{product_id}" => %w[patch],
      "/api/v1/admin/sellers" => %w[get],
      "/api/v1/admin/sellers/{id}" => %w[get],
      "/api/v1/admin/sellers/{id}/approve" => %w[post],
      "/api/v1/admin/sellers/{id}/reject" => %w[post],
      "/api/v1/admin/sellers/{id}/suspend" => %w[post],
      "/api/v1/admin/sellers/{id}/reinstate" => %w[post]
    }

    operations.each do |path, methods|
      methods.each { |method| assert spec.dig("paths", path, method), "missing #{method.upcase} #{path}" }
    end
  end

  test "openapi separates create and partial update payloads" do
    spec = YAML.safe_load(File.read(OPENAPI_PATH))
    assert_equal [ "name" ], spec.dig("components", "schemas", "CategoryCreateRequest", "required")
    refute spec.dig("components", "schemas", "CategoryUpdateRequest", "required")
    assert_equal %w[name price_cents currency], spec.dig("components", "schemas", "ProductCreateRequest", "required")
    refute spec.dig("components", "schemas", "ProductUpdateRequest", "required")
  end

  test "openapi bounds all phase 03 collection pagination" do
    spec = YAML.safe_load(File.read(OPENAPI_PATH))
    per_page = spec.dig("components", "parameters", "PerPage", "schema")
    assert_equal 25, per_page["default"]
    assert_equal 100, per_page["maximum"]

    %w[/api/v1/seller/categories /api/v1/seller/products /api/v1/seller/inventory /api/v1/admin/sellers].each do |path|
      refs = spec.dig("paths", path, "get", "parameters").map { |parameter| parameter["$ref"] }
      assert_includes refs, "#/components/parameters/Page"
      assert_includes refs, "#/components/parameters/PerPage"
    end
  end

  test "openapi documents phase 04 public discovery and guest cart operations" do
    spec = YAML.safe_load(File.read(OPENAPI_PATH))
    paths = spec.fetch("paths")

    %w[/api/v1/public/sellers /api/v1/public/sellers/{id} /api/v1/public/sellers/{seller_id}/products /api/v1/public/products/{id} /api/v1/public/cart].each do |path|
      assert paths.fetch(path).fetch("get")
    end
    assert paths.fetch("/api/v1/public/cart").fetch("delete")

    create = paths.fetch("/api/v1/public/cart/items").fetch("post")
    update = paths.fetch("/api/v1/public/cart/items/{id}").fetch("patch")
    assert_equal "#/components/schemas/GuestCartItemCreateRequest", create.dig("requestBody", "content", "application/json", "schema", "$ref")
    assert_equal "#/components/schemas/GuestCartItemUpdateRequest", update.dig("requestBody", "content", "application/json", "schema", "$ref")
    assert create.fetch("responses").key?("429")
    assert update.fetch("responses").key?("429")

    assert_equal GuestCartItem::MAX_QUANTITY, spec.dig("components", "schemas", "GuestCartItemCreateRequest", "properties", "quantity", "maximum")
  end

  test "openapi documents phase 05 customer operations and strict cart contracts" do
    spec = YAML.safe_load(File.read(OPENAPI_PATH))
    paths = spec.fetch("paths")
    operations = {
      "/api/v1/customer/profile" => %w[get patch],
      "/api/v1/customer/addresses" => %w[get post],
      "/api/v1/customer/addresses/{id}" => %w[get patch delete],
      "/api/v1/customer/addresses/{id}/default" => %w[post],
      "/api/v1/customer/favorites" => %w[get post],
      "/api/v1/customer/favorites/{id}" => %w[delete],
      "/api/v1/customer/cart" => %w[get delete],
      "/api/v1/customer/cart/items" => %w[post],
      "/api/v1/customer/cart/items/{id}" => %w[patch delete],
      "/api/v1/customer/cart/handoff" => %w[post]
    }

    operations.each do |path, methods|
      methods.each { |method| assert paths.fetch(path).fetch(method), "missing #{method.upcase} #{path}" }
    end

    create_quantity = spec.dig("components", "schemas", "CustomerCartItemCreateRequest", "properties", "quantity")
    update_quantity = spec.dig("components", "schemas", "CustomerCartItemUpdateRequest", "properties", "quantity")
    assert_equal 1, create_quantity["minimum"]
    assert_equal CartItem::MAX_QUANTITY, create_quantity["maximum"]
    assert_equal 0, update_quantity["minimum"]
    assert_equal CartItem::MAX_QUANTITY, update_quantity["maximum"]
    assert_equal "boolean", spec.dig("components", "schemas", "CustomerCartHandoffRequest", "properties", "replace_confirmed", "type")
    assert_equal "#/components/schemas/CustomerProfileEnvelope",
                 paths.dig("/api/v1/customer/profile", "get", "responses", "200", "content", "application/json", "schema", "$ref")
    assert spec.dig("components", "schemas", "CustomerProfile", "properties", "user_id")
    assert spec.dig("components", "schemas", "CustomerProfileUpdateRequest", "properties", "phone")
    assert_equal "#/components/schemas/CustomerCartEnvelope",
                 paths.dig("/api/v1/customer/cart", "get", "responses", "200", "content", "application/json", "schema", "$ref")

    collection_schemas = {
      "/api/v1/customer/addresses" => "#/components/schemas/CustomerAddressCollectionEnvelope",
      "/api/v1/customer/favorites" => "#/components/schemas/CustomerFavoriteCollectionEnvelope"
    }
    collection_schemas.each do |path, expected_schema|
      refs = paths.dig(path, "get", "parameters").map { |parameter| parameter["$ref"] }
      assert_includes refs, "#/components/parameters/Page"
      assert_includes refs, "#/components/parameters/PerPage"
      assert_equal expected_schema,
                   paths.dig(path, "get", "responses", "200", "content", "application/json", "schema", "$ref")
    end

    assert_includes spec.dig("components", "schemas", "Error", "properties", "code", "enum"), "seller_conflict"
  end

  test "openapi documents phase 06 atomic idempotent checkout" do
    spec = YAML.safe_load(File.read(OPENAPI_PATH))
    checkout = spec.dig("paths", "/api/v1/customer/checkout", "post")

    assert checkout
    assert_equal [ { "$ref" => "#/components/parameters/IdempotencyKey" } ], checkout.fetch("parameters")
    assert_equal "#/components/schemas/CustomerCheckoutRequest",
                 checkout.dig("requestBody", "content", "application/json", "schema", "$ref")
    assert_equal "#/components/schemas/CustomerCheckoutEnvelope",
                 checkout.dig("responses", "201", "content", "application/json", "schema", "$ref")
    %w[400 401 403 404 409 413 422 429 503].each do |status|
      assert checkout.fetch("responses").key?(status), "missing checkout response #{status}"
    end

    request_schema = spec.dig("components", "schemas", "CustomerCheckoutRequest")
    assert_equal false, request_schema["additionalProperties"]
    assert_equal [ "address_id" ], request_schema["required"]
    assert_equal 128, spec.dig("components", "parameters", "IdempotencyKey", "schema", "maxLength")

    order = spec.dig("components", "schemas", "CustomerCheckoutOrder")
    %w[order_state payment_state subtotal_cents delivery_fee_cents discount_cents courier_fee_cents total_cents items delivery_address].each do |field|
      assert order.fetch("properties").key?(field), "checkout order missing #{field}"
    end

    codes = spec.dig("components", "schemas", "Error", "properties", "code", "enum")
    assert_includes codes, "idempotency_conflict"
    assert_includes codes, "insufficient_inventory"
    assert_includes codes, "external_dependency_unavailable"
  end

  test "openapi documents phase 07 order workflow with strict typed contracts" do
    spec = YAML.safe_load(File.read(OPENAPI_PATH))
    paths = spec.fetch("paths")
    operations = {
      "/api/v1/seller/orders" => %w[get],
      "/api/v1/seller/orders/{id}" => %w[get],
      "/api/v1/seller/orders/{id}/accept" => %w[post],
      "/api/v1/seller/orders/{id}/reject" => %w[post],
      "/api/v1/seller/orders/{id}/preparing" => %w[post],
      "/api/v1/seller/orders/{id}/ready" => %w[post],
      "/api/v1/admin/payments/{id}/confirm" => %w[post],
      "/api/v1/admin/orders/{id}/cancel" => %w[post],
      "/api/v1/customer/orders/{id}/cancel" => %w[post]
    }

    operations.each do |path, methods|
      methods.each { |method| assert paths.fetch(path).fetch(method), "missing #{method.upcase} #{path}" }
    end

    assert_equal "#/components/schemas/SellerOrderListEnvelope",
                 paths.dig("/api/v1/seller/orders", "get", "responses", "200", "content", "application/json", "schema", "$ref")
    assert_equal "#/components/schemas/SellerOrderEnvelope",
                 paths.dig("/api/v1/seller/orders/{id}", "get", "responses", "200", "content", "application/json", "schema", "$ref")
    assert_equal "#/components/schemas/PaymentConfirmationEnvelope",
                 paths.dig("/api/v1/admin/payments/{id}/confirm", "post", "responses", "200", "content", "application/json", "schema", "$ref")
    assert_equal "#/components/schemas/OrderCancellationEnvelope",
                 paths.dig("/api/v1/customer/orders/{id}/cancel", "post", "responses", "200", "content", "application/json", "schema", "$ref")

    %w[/api/v1/seller/orders/{id}/reject /api/v1/admin/orders/{id}/cancel /api/v1/customer/orders/{id}/cancel].each do |path|
      schema = paths.dig(path, "post", "requestBody", "content", "application/json", "schema")
      assert_equal false, schema["additionalProperties"], "#{path} request must reject unknown fields"
    end

    codes = spec.dig("components", "schemas", "Error", "properties", "code", "enum")
    %w[reason_required payment_required payment_conflict order_conflict refund_required forbidden_transition].each do |code|
      assert_includes codes, code
    end
  end

  test "openapi documents phase 08 courier workflow with strict typed contracts" do
    spec = YAML.safe_load(File.read(OPENAPI_PATH))
    paths = spec.fetch("paths")
    operations = {
      "/api/v1/courier/onboarding" => %w[post],
      "/api/v1/courier/profile" => %w[get patch],
      "/api/v1/courier/availability" => %w[patch],
      "/api/v1/courier/orders/eligible" => %w[get],
      "/api/v1/courier/orders/active" => %w[get],
      "/api/v1/courier/orders/history" => %w[get],
      "/api/v1/courier/orders/{id}/accept" => %w[post],
      "/api/v1/courier/orders/{id}/pickup" => %w[post],
      "/api/v1/courier/orders/{id}/deliver" => %w[post],
      "/api/v1/courier/stats" => %w[get],
      "/api/v1/admin/couriers" => %w[get],
      "/api/v1/admin/couriers/{id}" => %w[get],
      "/api/v1/admin/couriers/{id}/approve" => %w[post],
      "/api/v1/admin/couriers/{id}/reject" => %w[post],
      "/api/v1/admin/couriers/{id}/suspend" => %w[post],
      "/api/v1/admin/couriers/{id}/reinstate" => %w[post]
    }
    operations.each do |path, methods|
      methods.each { |method| assert paths.dig(path, method), "missing #{method.upcase} #{path}" }
    end

    collection_paths = %w[
      /api/v1/courier/orders/eligible
      /api/v1/courier/orders/history
      /api/v1/admin/couriers
    ]
    collection_paths.each do |path|
      refs = paths.dig(path, "get", "parameters").map { |parameter| parameter["$ref"] }
      assert_includes refs, "#/components/parameters/Page"
      assert_includes refs, "#/components/parameters/PerPage"
    end

    accept_refs = paths.dig("/api/v1/courier/orders/{id}/accept", "post", "parameters").filter_map { |parameter| parameter["$ref"] }
    assert_includes accept_refs, "#/components/parameters/IdempotencyKey"

    {
      "/api/v1/courier/onboarding" => "CourierOnboardingRequest",
      "/api/v1/courier/profile" => "CourierProfileUpdateRequest",
      "/api/v1/courier/availability" => "CourierAvailabilityRequest"
    }.each do |path, schema_name|
      method = path.end_with?("onboarding") ? "post" : "patch"
      assert_equal "#/components/schemas/#{schema_name}",
                   paths.dig(path, method, "requestBody", "content", "application/json", "schema", "$ref")
      assert_equal false, spec.dig("components", "schemas", schema_name, "additionalProperties")
    end

    %w[approve reject suspend reinstate].each do |action|
      path = "/api/v1/admin/couriers/{id}/#{action}"
      assert_equal "#/components/schemas/OptionalReasonRequest",
                   paths.dig(path, "post", "requestBody", "content", "application/json", "schema", "$ref")
      assert_equal "#/components/schemas/CourierEnvelope",
                   paths.dig(path, "post", "responses", "200", "content", "application/json", "schema", "$ref")
    end

    expected_response_refs = {
      [ "/api/v1/courier/onboarding", "post", "201" ] => "CourierEnvelope",
      [ "/api/v1/courier/profile", "get", "200" ] => "CourierEnvelope",
      [ "/api/v1/courier/profile", "patch", "200" ] => "CourierEnvelope",
      [ "/api/v1/courier/availability", "patch", "200" ] => "CourierEnvelope",
      [ "/api/v1/courier/orders/eligible", "get", "200" ] => "CourierEligibleOrderCollectionEnvelope",
      [ "/api/v1/courier/orders/active", "get", "200" ] => "CourierActiveOrderEnvelope",
      [ "/api/v1/courier/orders/history", "get", "200" ] => "CourierOrderCollectionEnvelope",
      [ "/api/v1/courier/orders/{id}/accept", "post", "200" ] => "CourierOrderEnvelope",
      [ "/api/v1/courier/orders/{id}/pickup", "post", "200" ] => "CourierOrderEnvelope",
      [ "/api/v1/courier/orders/{id}/deliver", "post", "200" ] => "CourierOrderEnvelope",
      [ "/api/v1/courier/stats", "get", "200" ] => "CourierStatsEnvelope",
      [ "/api/v1/admin/couriers", "get", "200" ] => "AdminCourierCollectionEnvelope",
      [ "/api/v1/admin/couriers/{id}", "get", "200" ] => "CourierEnvelope"
    }
    expected_response_refs.each do |(path, method, status), schema_name|
      assert_equal "#/components/schemas/#{schema_name}",
                   paths.dig(path, method, "responses", status, "content", "application/json", "schema", "$ref")
    end

    eligible_order = spec.dig("components", "schemas", "CourierEligibleOrder")
    assert_equal %w[courier_fee_cents created_at currency id order_state seller_id], eligible_order.fetch("properties").keys.sort
    courier_order = spec.dig("components", "schemas", "CourierOrder")
    assert courier_order.dig("properties", "courier_id")
    earnings = spec.dig("components", "schemas", "CourierStats", "properties", "earnings", "items")
    assert_equal "#/components/schemas/CourierEarning", earnings["$ref"]
    assert_equal %w[amount_cents currency], spec.dig("components", "schemas", "CourierEarning", "required").sort

    codes = spec.dig("components", "schemas", "Error", "properties", "code", "enum")
    %w[courier_already_exists courier_not_approved courier_not_available active_delivery_in_progress order_already_assigned idempotency_conflict].each do |code|
      assert_includes codes, code
    end
  end

  test "openapi documents phase 09 courier location and customer tracking" do
    spec = YAML.safe_load(File.read(OPENAPI_PATH))
    paths = spec.fetch("paths")

    assert paths.dig("/api/v1/courier/location", "post")
    assert paths.dig("/api/v1/customer/orders/{id}/tracking", "get")

    assert_equal "#/components/schemas/CustomerOrderTrackingEnvelope",
                 paths.dig("/api/v1/customer/orders/{id}/tracking", "get", "responses", "200", "content", "application/json", "schema", "$ref")
  end

  test "openapi documents phase 10 support ticket workflow" do
    spec = YAML.safe_load(File.read(OPENAPI_PATH))
    paths = spec.fetch("paths")
    operations = {
      "/api/v1/customer/tickets" => %w[get post],
      "/api/v1/customer/tickets/{id}" => %w[get],
      "/api/v1/customer/tickets/{id}/messages" => %w[post],
      "/api/v1/admin/tickets" => %w[get],
      "/api/v1/admin/tickets/{id}" => %w[get],
      "/api/v1/admin/tickets/{id}/messages" => %w[post],
      "/api/v1/admin/tickets/{id}/start_progress" => %w[post],
      "/api/v1/admin/tickets/{id}/resolve" => %w[post],
      "/api/v1/admin/tickets/{id}/reopen" => %w[post],
      "/api/v1/admin/tickets/{id}/close" => %w[post]
    }

    operations.each do |path, methods|
      methods.each { |method| assert paths.dig(path, method), "missing #{method.upcase} #{path}" }
    end

    assert_equal "#/components/schemas/SupportTicketCreateRequest",
                 paths.dig("/api/v1/customer/tickets", "post", "requestBody", "content", "application/json", "schema", "$ref")
    assert_equal false, spec.dig("components", "schemas", "SupportTicketCreateRequest", "additionalProperties")
    assert_equal "#/components/schemas/SupportTicketEnvelope",
                 paths.dig("/api/v1/customer/tickets/{id}", "get", "responses", "200", "content", "application/json", "schema", "$ref")
    assert_equal "#/components/schemas/SupportTicketMessageEnvelope",
                 paths.dig("/api/v1/admin/tickets/{id}/messages", "post", "responses", "201", "content", "application/json", "schema", "$ref")
  end

  test "openapi documents phase 11 admin operations" do
    spec = YAML.safe_load(File.read(OPENAPI_PATH))
    paths = spec.fetch("paths")
    operations = {
      "/api/v1/admin/dashboard" => %w[get],
      "/api/v1/admin/users" => %w[get],
      "/api/v1/admin/users/{id}" => %w[get],
      "/api/v1/admin/users/{id}/disable" => %w[post],
      "/api/v1/admin/users/{id}/enable" => %w[post],
      "/api/v1/admin/settings" => %w[get post],
      "/api/v1/admin/invoices" => %w[get],
      "/api/v1/admin/invoices/generate" => %w[post],
      "/api/v1/admin/invoices/{id}" => %w[get],
      "/api/v1/admin/observability/summary" => %w[get]
    }

    operations.each do |path, methods|
      methods.each { |method| assert paths.dig(path, method), "missing #{method.upcase} #{path}" }
    end
  end

  test "openapi documents every route in the Rails router (T13.9)" do
    spec = YAML.safe_load(File.read(OPENAPI_PATH))
    openapi_paths = spec.fetch("paths").keys

    routes = Rails.application.routes.routes.map(&:path).map(&:spec).map(&:to_s)
    rails_paths = routes.grep(%r{^/(api/v1|healthz|readyz)})
      .reject { |p| p.include?("/api/v1/test/") }
      .map { |p| p.sub(/\(\.:format\)/, "").gsub(/:([a-z_]+)/, '{\1}') }
      .uniq
      .sort

    missing = rails_paths - openapi_paths
    assert_empty missing, "Routes missing from OpenAPI: #{missing.join(', ')}"
  end

  test "openapi defines admin order and payment collection envelopes (T13.9)" do
    spec = YAML.safe_load(File.read(OPENAPI_PATH))
    %w[OrderEnvelope OrderCollectionEnvelope PaymentEnvelope PaymentCollectionEnvelope].each do |name|
      assert spec.dig("components", "schemas", name), "missing schema #{name}"
    end
    assert spec.dig("paths", "/api/v1/admin/orders", "get")
    assert spec.dig("paths", "/api/v1/admin/orders/{id}", "get")
    assert spec.dig("paths", "/api/v1/admin/payments", "get")
    assert spec.dig("paths", "/api/v1/admin/payments/{id}", "get")
    assert spec.dig("paths", "/api/v1/admin/observability/requests", "get")
    assert spec.dig("paths", "/api/v1/admin/observability/orders", "get")
    assert spec.dig("paths", "/api/v1/admin/observability/jobs", "get")
  end

  test "every local component reference resolves" do
    spec = YAML.safe_load(File.read(OPENAPI_PATH))
    refs = File.read(OPENAPI_PATH).scan(%r{#/components/(schemas|responses|parameters)/([A-Za-z0-9]+)}).uniq
    missing = refs.reject { |section, name| spec.dig("components", section, name) }
    assert_empty missing
  end
end

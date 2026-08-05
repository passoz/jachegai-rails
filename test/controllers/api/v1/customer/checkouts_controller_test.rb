require "test_helper"

class Api::V1::Customer::CheckoutsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "checkout-api@example.com", password: "password123", full_name: "Buyer")
    @user.role_assignments.create!(role: "customer")
    @token = Session.issue_for(@user)
    @customer = @user.customer
    @seller = Seller.create!(name: "API Seller", moderation_state: "approved")
    category = Category.create!(seller: @seller, name: "API Products", position: 1)
    @product = Product.create!(seller: @seller, category: category, name: "API Product", price_cents: 600, currency: "BRL", active: true)
    @inventory = InventoryItem.create!(seller: @seller, product: @product, quantity: 3)
    @address = AddressService.create(customer: @customer, params: {
      name: "Home", line1: "Rua API", city: "São Paulo", state: "SP", zip: "01000-000", country: "BR"
    })
    CustomerCartService.add_item(customer: @customer, product_id: @product.id, quantity: 2)
    Api::V1::Customer::CheckoutsController.checkout_rate_limiter.store.reset
  end

  test "POST checkout returns 201 with immutable snapshots and separate order payment states" do
    assert_difference "Order.count", 1 do
      post_checkout(key: "api-success")
    end

    assert_response :created
    data = JSON.parse(response.body).fetch("data")
    assert_equal "pending", data["order_state"]
    assert_equal "pending", data["payment_state"]
    assert_equal @seller.id, data["seller_id"]
    assert_equal "BRL", data["currency"]
    assert_equal 1_200, data["subtotal_cents"]
    assert_equal 0, data["delivery_fee_cents"]
    assert_equal 0, data["discount_cents"]
    assert_equal 0, data["courier_fee_cents"]
    assert_equal 1_200, data["total_cents"]
    assert_equal "API Product", data.dig("items", 0, "product_name")
    assert_equal 600, data.dig("items", 0, "unit_price_cents")
    assert_equal "Rua API", data.dig("delivery_address", "line1")
    assert_match(/\A[0-9a-f-]{36}\z/, data["id"])
  end

  test "same key and payload replays same order without repeated decrement" do
    post_checkout(key: "api-retry")
    first_id = JSON.parse(response.body).dig("data", "id")

    post_checkout(key: "api-retry")

    assert_response :created
    assert_equal first_id, JSON.parse(response.body).dig("data", "id")
    assert_equal 1, Order.count
    assert_equal 1, Payment.count
    assert_equal 1, @inventory.reload.quantity
  end

  test "authenticated principal without customer role is forbidden" do
    seller_user = User.create!(email: "checkout-api-seller@example.com", password: "password123", full_name: "Seller")
    seller_user.role_assignments.create!(role: "seller")

    post "/api/v1/customer/checkout",
         params: { address_id: @address.id }.to_json,
         headers: { "Authorization" => "Bearer #{Session.issue_for(seller_user)}", "Content-Type" => "application/json", "Idempotency-Key" => "seller-key" }

    assert_response :forbidden
    assert_equal 0, Order.count
  end

  test "requires bearer customer idempotency key and address id" do
    post "/api/v1/customer/checkout",
         params: { address_id: @address.id }.to_json,
         headers: { "Content-Type" => "application/json", "Idempotency-Key" => "key" }
    assert_response :unauthorized

    post_checkout(key: nil)
    assert_response :unprocessable_content
    assert_equal "invalid_input", JSON.parse(response.body).dig("error", "code")

    post "/api/v1/customer/checkout",
         params: {}.to_json,
         headers: auth_headers.merge("Idempotency-Key" => "key")
    assert_response :unprocessable_content

    post_checkout(key: "blank-address", address_id: "")
    assert_response :unprocessable_content
    assert_equal "invalid_input", JSON.parse(response.body).dig("error", "code")
  end

  test "same idempotency key with different payload returns conflict" do
    post_checkout(key: "payload-conflict")
    assert_response :created

    post_checkout(key: "payload-conflict", address_id: ApplicationId.generate)

    assert_response :conflict
    assert_equal "idempotency_conflict", JSON.parse(response.body).dig("error", "code")
    assert_equal 1, Order.count
  end

  test "rejects unknown monetary fields and invalid idempotency key" do
    post "/api/v1/customer/checkout",
         params: { address_id: @address.id, total_cents: 1 }.to_json,
         headers: auth_headers.merge("Idempotency-Key" => "key")
    assert_response :unprocessable_content
    assert_equal "unknown_fields", JSON.parse(response.body).dig("error", "code")

    post_checkout(key: "x" * 129)
    assert_response :unprocessable_content
    assert_equal "invalid_input", JSON.parse(response.body).dig("error", "code")
  end

  test "provider outage returns recoverable 503 without exposing internals" do
    failing_service = Object.new
    failing_service.define_singleton_method(:call) do |**|
      raise DomainError.new(code: :external_dependency_unavailable, http_status: :service_unavailable)
    end

    with_checkout_service(failing_service) { post_checkout(key: "provider-outage") }

    assert_response :service_unavailable
    body = JSON.parse(response.body)
    assert_equal "external_dependency_unavailable", body.dig("error", "code")
    refute_includes response.body, "SQLite"
    assert_equal 1, @customer.cart.reload.cart_items.count
  end

  test "unexpected failure returns sanitized internal error" do
    failing_service = Object.new
    failing_service.define_singleton_method(:call) { |**| raise "sensitive provider detail" }

    with_checkout_service(failing_service) { post_checkout(key: "internal-failure") }

    assert_response :internal_server_error
    assert_equal "internal_error", JSON.parse(response.body).dig("error", "code")
    refute_includes response.body, "sensitive provider detail"
  end

  test "checkout mutation is rate limited by customer and IP" do
    limiter = Api::V1::Customer::CheckoutsController.checkout_rate_limiter
    10.times do |index|
      limiter.allowed?("checkout:customer:#{@customer.id}")
      limiter.allowed?("checkout:ip:127.0.0.1")
    end

    post_checkout(key: "rate-limited")

    assert_response :too_many_requests
    assert_equal "rate_limited", JSON.parse(response.body).dig("error", "code")
    assert_equal 0, Order.count
  end

  test "another customer's address is not disclosed and cart remains" do
    other = User.create!(email: "checkout-api-other@example.com", password: "password123", full_name: "Other")
    other.role_assignments.create!(role: "customer")
    address = AddressService.create(customer: other.customer, params: {
      name: "Other", line1: "Rua Other", city: "São Paulo", state: "SP", zip: "02000-000", country: "BR"
    })

    post_checkout(key: "other-address", address_id: address.id)

    assert_response :not_found
    assert_equal 0, Order.count
    assert_equal 1, @customer.cart.reload.cart_items.count
  end

  test "insufficient inventory returns stable conflict with no partial records" do
    @inventory.update!(quantity: 1)

    post_checkout(key: "api-stock")

    assert_response :conflict
    assert_equal "insufficient_inventory", JSON.parse(response.body).dig("error", "code")
    assert_equal 0, Order.count
    assert_equal 0, Payment.count
    assert_equal 0, OutboxEvent.count
    assert_equal 1, @inventory.reload.quantity
    assert_equal 1, @customer.cart.reload.cart_items.count
  end

  private

  def with_checkout_service(service)
    original_constructor = CheckoutService.method(:new)
    CheckoutService.define_singleton_method(:new) { service }
    yield
  ensure
    CheckoutService.define_singleton_method(:new, original_constructor)
  end

  def post_checkout(key:, address_id: @address.id)
    headers = auth_headers
    headers["Idempotency-Key"] = key if key
    post "/api/v1/customer/checkout", params: { address_id: address_id }.to_json, headers: headers
  end

  def auth_headers
    { "Authorization" => "Bearer #{@token}", "Content-Type" => "application/json" }
  end
end

require "test_helper"

# End-to-end API flow covering scenarios A–H via HTTP only:
#   public discovery → seller catalog → customer cart/checkout → payment →
#   seller fulfilment → courier delivery → tracking → support → admin,
# plus cross-role denial and disabled-user rejection.
class E2eFullFlowTest < ActionDispatch::IntegrationTest
  self.use_transactional_tests = false

  setup do
    cleanup_tables
    Api::V1::Customer::CheckoutsController.checkout_rate_limiter.store.reset
  end

  teardown do
    cleanup_tables
  end

  test "scenarios A-H full lifecycle over HTTP" do
    # ── A. Auth ─────────────────────────────────────────────────────────────
    customer_token = register(email: "e2e.customer@example.com", full_name: "E2E Customer")

    seller_user = User.create!(email: "e2e.seller@example.com", password: "password123", full_name: "E2E Seller")
    seller_user.role_assignments.create!(role: "seller")
    seller_token = Session.issue_for(seller_user)

    courier_user = User.create!(email: "e2e.courier@example.com", password: "password123", full_name: "E2E Courier")
    courier_user.role_assignments.create!(role: "courier")
    courier_token = Session.issue_for(courier_user)

    admin_user = User.create!(email: "e2e.admin@example.com", password: "password123", full_name: "E2E Admin")
    admin_user.role_assignments.create!(role: "admin")
    admin_token = Session.issue_for(admin_user)

    # auth/me for the customer
    get "/api/v1/auth/me", headers: auth(customer_token)
    assert_response :ok
    assert_equal "e2e.customer@example.com", JSON.parse(response.body).dig("data", "email")

    # ── B. Seller catalog + inventory ───────────────────────────────────────
    post "/api/v1/seller/onboarding",
         params: { name: "E2E Store", contact_email: "store@example.com" }.to_json,
         headers: auth(seller_token)
    assert_response :created
    seller_id = JSON.parse(response.body).dig("data", "id")

    post "/api/v1/admin/sellers/#{seller_id}/approve", headers: auth(admin_token)
    assert_response :ok

    post "/api/v1/seller/categories",
         params: { name: "E2E Category", position: 1 }.to_json,
         headers: auth(seller_token)
    assert_response :created
    category_id = JSON.parse(response.body).dig("data", "id")

    post "/api/v1/seller/products",
         params: { category_id: category_id, name: "E2E Product", price_cents: 1_000, currency: "BRL" }.to_json,
         headers: auth(seller_token)
    assert_response :created
    product_id = JSON.parse(response.body).dig("data", "id")

    patch "/api/v1/seller/inventory/#{product_id}",
          params: { quantity: 10 }.to_json,
          headers: auth(seller_token)
    assert_response :ok

    # ── Public discovery ────────────────────────────────────────────────────
    get "/api/v1/public/sellers"
    assert_response :ok
    assert_includes JSON.parse(response.body).fetch("data").map { |s| s["id"] }, seller_id

    get "/api/v1/public/products/#{product_id}"
    assert_response :ok
    assert_equal "E2E Product", JSON.parse(response.body).dig("data", "name")

    # ── C. Customer cart → checkout → payment ───────────────────────────────
    post "/api/v1/customer/cart/items",
         params: { product_id: product_id, quantity: 2 }.to_json,
         headers: auth(customer_token)
    assert_response :success

    get "/api/v1/customer/cart", headers: auth(customer_token)
    assert_response :ok

    post "/api/v1/customer/addresses",
         params: { name: "Home", line1: "Rua E2E 100", city: "São Paulo", state: "SP", zip: "01000-000", country: "BR" }.to_json,
         headers: auth(customer_token)
    assert_response :created
    address_id = JSON.parse(response.body).dig("data", "id")

    post "/api/v1/customer/checkout",
         params: { address_id: address_id }.to_json,
         headers: auth(customer_token).merge("Idempotency-Key" => "e2e-checkout-1")
    assert_response :created
    order_id = JSON.parse(response.body).dig("data", "id")
    payment_id = Order.find(order_id).payment.id

    # ── Admin confirms payment ──────────────────────────────────────────────
    post "/api/v1/admin/payments/#{payment_id}/confirm", headers: auth(admin_token)
    assert_response :ok

    # ── D. Seller fulfilment ────────────────────────────────────────────────
    post "/api/v1/seller/orders/#{order_id}/accept", headers: auth(seller_token)
    assert_response :ok

    post "/api/v1/seller/orders/#{order_id}/preparing", headers: auth(seller_token)
    assert_response :ok

    post "/api/v1/seller/orders/#{order_id}/ready", headers: auth(seller_token)
    assert_response :ok

    # ── E. Courier delivery ─────────────────────────────────────────────────
    post "/api/v1/courier/onboarding",
         params: { phone: "+5511988887777", document_number: "11122233344", vehicle_type: "motorcycle", vehicle_plate: "XYZ9876", location_consent: true }.to_json,
         headers: auth(courier_token)
    assert_response :created
    courier_id = JSON.parse(response.body).dig("data", "id")

    post "/api/v1/admin/couriers/#{courier_id}/approve", headers: auth(admin_token)
    assert_response :ok

    patch "/api/v1/courier/availability",
          params: { state: "available" }.to_json,
          headers: auth(courier_token)
    assert_response :ok

    get "/api/v1/courier/orders/eligible", headers: auth(courier_token)
    assert_response :ok
    assert_includes JSON.parse(response.body).fetch("data").map { |o| o["id"] }, order_id

    post "/api/v1/courier/orders/#{order_id}/accept",
         headers: auth(courier_token).merge("Idempotency-Key" => "e2e-accept-1")
    assert_response :ok

    post "/api/v1/courier/orders/#{order_id}/pickup",
         headers: auth(courier_token).merge("Idempotency-Key" => "e2e-pickup-1")
    assert_response :ok

    post "/api/v1/courier/orders/#{order_id}/deliver",
         headers: auth(courier_token).merge("Idempotency-Key" => "e2e-deliver-1")
    assert_response :ok

    # ── F. Tracking (after delivery) ────────────────────────────────────────
    get "/api/v1/customer/orders/#{order_id}/tracking", headers: auth(customer_token)
    assert_response :ok
    assert_equal "delivered", JSON.parse(response.body).dig("data", "order_state")

    # ── G. Support ticket + admin resolve ───────────────────────────────────
    post "/api/v1/customer/tickets",
         params: { subject: "E2E ticket", initial_message: "Ajuda por favor" }.to_json,
         headers: auth(customer_token)
    assert_response :created
    ticket_id = JSON.parse(response.body).dig("data", "id")

    post "/api/v1/admin/tickets/#{ticket_id}/start_progress", headers: auth(admin_token)
    assert_response :ok

    post "/api/v1/admin/tickets/#{ticket_id}/resolve", headers: auth(admin_token)
    assert_response :ok

    # ── H. Admin operations ─────────────────────────────────────────────────
    get "/api/v1/admin/dashboard", headers: auth(admin_token)
    assert_response :ok
    dashboard = JSON.parse(response.body).dig("data")
    assert dashboard["orders"].present?
    assert dashboard["sellers"].present?

    get "/api/v1/admin/users", headers: auth(admin_token)
    assert_response :ok

    get "/api/v1/admin/observability/summary", headers: auth(admin_token)
    assert_response :ok

    post "/api/v1/admin/settings",
         params: { key: "platform_fee_percent", value: "10.0", reason: "E2E", effective_at: Time.current.iso8601 }.to_json,
         headers: auth(admin_token)
    assert_response :created

    post "/api/v1/admin/invoices/generate",
         params: { seller_id: seller_id, period_start: Date.today.beginning_of_month.to_s, period_end: Date.today.end_of_month.to_s }.to_json,
         headers: auth(admin_token)
    assert_response :created

    # Final domain state assertions
    assert_equal "delivered", Order.find(order_id).status
    assert_equal "paid", Payment.find(payment_id).state
    assert_equal "resolved", Ticket.find(ticket_id).state
  end

  test "cross-role denial: seller cannot reach customer or courier endpoints" do
    seller_user = User.create!(email: "e2e.cross.seller@example.com", password: "password123", full_name: "Cross Seller")
    seller_user.role_assignments.create!(role: "seller")
    seller_token = Session.issue_for(seller_user)

    customer_user = User.create!(email: "e2e.cross.customer@example.com", password: "password123", full_name: "Cross Customer")
    customer_user.role_assignments.create!(role: "customer")
    customer_token = Session.issue_for(customer_user)

    courier_user = User.create!(email: "e2e.cross.courier@example.com", password: "password123", full_name: "Cross Courier")
    courier_user.role_assignments.create!(role: "courier")
    courier_token = Session.issue_for(courier_user)

    admin_user = User.create!(email: "e2e.cross.admin@example.com", password: "password123", full_name: "Cross Admin")
    admin_user.role_assignments.create!(role: "admin")
    admin_token = Session.issue_for(admin_user)

    # customer tries seller endpoints
    post "/api/v1/seller/onboarding",
         params: { name: "Nope" }.to_json,
         headers: auth(customer_token)
    assert_response :forbidden

    # seller tries customer checkout
    post "/api/v1/customer/checkout",
         params: { address_id: "x" }.to_json,
         headers: auth(seller_token).merge("Idempotency-Key" => "cross-1")
    assert_response :forbidden

    # seller tries courier availability
    patch "/api/v1/courier/availability",
          params: { state: "available" }.to_json,
          headers: auth(seller_token)
    assert_response :forbidden

    # courier tries admin dashboard
    get "/api/v1/admin/dashboard", headers: auth(courier_token)
    assert_response :forbidden

    # customer tries admin users
    get "/api/v1/admin/users", headers: auth(customer_token)
    assert_response :forbidden

    # non-admin cannot confirm payments
    post "/api/v1/admin/payments/fake/confirm", headers: auth(customer_token)
    assert_response :forbidden

    # seller cannot list admin invoices
    get "/api/v1/admin/invoices", headers: auth(seller_token)
    assert_response :forbidden
  end

  test "disabled user token is rejected after admin disables the account" do
    victim_user = User.create!(email: "e2e.victim@example.com", password: "password123", full_name: "Victim")
    victim_user.role_assignments.create!(role: "customer")
    victim_token = Session.issue_for(victim_user)

    admin_user = User.create!(email: "e2e.disable.admin@example.com", password: "password123", full_name: "Disable Admin")
    admin_user.role_assignments.create!(role: "admin")
    admin_token = Session.issue_for(admin_user)

    # token works before disable
    get "/api/v1/auth/me", headers: auth(victim_token)
    assert_response :ok

    post "/api/v1/admin/users/#{victim_user.id}/disable", headers: auth(admin_token)
    assert_response :ok

    # token is now rejected
    get "/api/v1/auth/me", headers: auth(victim_token)
    assert_response :unauthorized

    # login is rejected for disabled user
    post "/api/v1/auth/login",
         params: { email: "e2e.victim@example.com", password: "password123" }.to_json,
         headers: { "Content-Type" => "application/json" }
    assert_response :unauthorized
  end

  private

  def register(email:, full_name:)
    post "/api/v1/auth/register",
         params: { email: email, password: "password123", full_name: full_name }.to_json,
         headers: { "Content-Type" => "application/json" }
    assert_response :created
    JSON.parse(response.body).dig("data", "token")
  end

  def auth(token)
    { "Content-Type" => "application/json", "Authorization" => "Bearer #{token}" }
  end

  def cleanup_tables
    [ OutboxEvent, Invoice, Upload, GuestCartItem, GuestCart, InventoryMovement, Payment,
      OrderStatusHistory, OrderItem, IdempotencyRecord, Order, TicketMessage, Ticket, CartItem, Cart,
      Favorite, Address, CourierLocation, InventoryItem, Product, Category, SellerSettings,
      SellerMembership, Seller, Courier, Customer, RoleAssignment, Session, User ].each(&:delete_all)
    AuditRecord.delete_all
    MarketplaceSetting.delete_all
  end
end

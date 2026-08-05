require "test_helper"

# Security threat scenarios (T13.7).
#
# Most scenarios are covered by their owning phase tests:
#   1. cross-customer address/order/ticket  -> addresses/orders/tickets controller tests
#   2. cross-seller catalog/order mutation  -> seller products/orders controller tests
#   3. cross-courier delivery transition    -> courier delivery_controller_test
#   5. replayed checkout                    -> checkout_concurrency_test + e2e_full_flow_test
#   6. concurrent courier accept            -> courier_assignment_service_test
#   7. manipulated client price             -> checkouts_controller_test (unknown_fields)
#   8. crafted upload/path traversal        -> upload_service_test
#   9. revoked/disabled session             -> authorization_test + admin users_controller_test
#   10. CSRF/origin attack                  -> middleware/origin_policy_test
#   11. logs without credentials/PII/location -> middleware/logging_test
#
# This file closes the remaining gaps:
#   4. Public registration must never be able to claim the admin role.
#   12. External-callback scenarios must be marked conditional, never falsely green.
class SecurityThreatScenariosTest < ActionDispatch::IntegrationTest
  setup do
    @customer = User.create!(email: "threat.customer@example.com", password: "password123", full_name: "Threat Customer")
    @customer.role_assignments.create!(role: "customer")
    @token = Session.issue_for(@customer)
  end

  def auth(token = @token)
    { "Content-Type" => "application/json", "Authorization" => "Bearer #{token}" }
  end

  test "public registration with a forged admin role never grants admin" do
    # The API is strict about unknown fields: a forged `role` payload is rejected
    # outright, so registration can never claim admin.
    post "/api/v1/auth/register",
         params: { email: "threat.register@example.com", password: "password123", full_name: "Threat Register", role: "admin" }.to_json,
         headers: { "Content-Type" => "application/json" }

    assert_response :unprocessable_content
    assert_equal "unknown_fields", JSON.parse(response.body).dig("error", "code")
    refute User.exists?(email: "threat.register@example.com"), "registration with forged role must not create a user"

    # A normal registration creates only the customer role.
    post "/api/v1/auth/register",
         params: { email: "threat.register.ok@example.com", password: "password123", full_name: "Threat Register OK" }.to_json,
         headers: { "Content-Type" => "application/json" }
    assert_response :created
    json = JSON.parse(response.body)

    user = User.find_by!(email: "threat.register.ok@example.com")
    assert_equal [ :customer ], user.roles
    refute user.admin?, "registration must never grant admin"
    assert_equal [ "customer" ], json.dig("data", "user", "roles")

    # The forged token must not reach any admin surface.
    forged_token = json.dig("data", "token")
    get "/api/v1/admin/dashboard", headers: auth(forged_token)
    assert_response :forbidden
    get "/api/v1/admin/users", headers: auth(forged_token)
    assert_response :forbidden
  end

  test "external-callback scenarios are conditional, not falsely green" do
    # The simulated gateway raises real external_dependency_unavailable errors instead
    # of skipping or pretending success; provider contracts assert that behavior.
    # No provider/payment test may use a bare skip: conditional scenarios must be
    # explicit, and the simulated gateway must not silently pass through.
    external_tests = Dir["test/services/provider_contracts_test.rb", "test/services/payments/simulated_gateway_test.rb"]
    skipped_bodies = external_tests.flat_map do |path|
      File.readlines(path).grep(/\bskip\s+["']/).map { |line| "#{path}:#{line.strip}" }
    end
    assert_empty skipped_bodies,
      "external-callback tests must not be falsely skipped: #{skipped_bodies.join('; ')}"

    # Simulated gateway surfaces dependency failures as recoverable errors.
    gateway = Payments::SimulatedGateway.new(failure: true)
    command = Payments::CreateCommand.new(
      order_id: "threat-order",
      amount: Money.new(cents: 100, currency: "BRL"),
      idempotency_key: "threat-key"
    )
    error = assert_raises(DomainError) do
      gateway.create(command)
    end
    assert_equal "external_dependency_unavailable", error.code
  end

  test "customer cannot reach another customer's order even with guessed id" do
    other = User.create!(email: "threat.other@example.com", password: "password123", full_name: "Threat Other")
    other.role_assignments.create!(role: "customer")
    other_customer = other.customer
    seller = Seller.create!(name: "Threat Seller", moderation_state: "approved")
    order = Order.create!(
      customer: other_customer,
      seller: seller,
      status: "pending",
      currency: "BRL",
      subtotal_cents: 100,
      delivery_fee_cents: 0,
      discount_cents: 0,
      courier_fee_cents: 0,
      total_cents: 100,
      address_name: "Other",
      address_line1: "Rua Outra 1",
      address_city: "São Paulo",
      address_state: "SP",
      address_zip: "01000-000",
      address_country: "BR"
    )

    get "/api/v1/customer/orders/#{order.id}/tracking", headers: auth
    assert_response :not_found
    assert_equal "not_found", JSON.parse(response.body).dig("error", "code")
  end
end

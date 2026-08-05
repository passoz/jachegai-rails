require "test_helper"

class Api::V1::Courier::LocationRateLimitTest < ActionDispatch::IntegrationTest
  setup do
    @courier_user = User.create!(email: "courier.ratelimit@example.com", password: "password123", full_name: "Courier RateLimit")
    @courier_user.role_assignments.create!(role: "courier")
    @courier = Courier.create!(
      user: @courier_user, phone: "+5511944445555", document_number: "44455566677",
      vehicle_type: "motorcycle", moderation_state: "approved", operational_state: "on_delivery",
      location_consent_given_at: Time.current
    )
    @token = Session.issue_for(@courier_user, ip: "127.0.0.1", user_agent: "Test")

    seller = Seller.create!(name: "RateLimit Store", moderation_state: "approved")
    customer_user = User.create!(email: "customer.ratelimit@example.com", password: "password123", full_name: "Customer RateLimit")
    customer_user.role_assignments.create!(role: "customer")

    Order.create!(
      customer: customer_user.customer, seller: seller, courier: @courier, status: "assigned",
      currency: "BRL", subtotal_cents: 1000, delivery_fee_cents: 500, total_cents: 1500,
      address_name: "Home", address_line1: "Rua Z", address_city: "São Paulo", address_state: "SP", address_zip: "01000-000", address_country: "BR"
    )
  end

  test "updates sent faster than 5s interval are rate limited with 429" do
    # First request succeeds
    post "/api/v1/courier/location",
      headers: { "Authorization" => "Bearer #{@token}", "CONTENT_TYPE" => "application/json" },
      params: { latitude: -23.5505, longitude: -46.6333 }.to_json
    assert_response :created

    # Second request immediately after fails with 429 rate_limited
    post "/api/v1/courier/location",
      headers: { "Authorization" => "Bearer #{@token}", "CONTENT_TYPE" => "application/json" },
      params: { latitude: -23.5506, longitude: -46.6334 }.to_json

    assert_response :too_many_requests
    json = JSON.parse(response.body)
    assert_equal "rate_limited", json["error"]["code"]
  end
end

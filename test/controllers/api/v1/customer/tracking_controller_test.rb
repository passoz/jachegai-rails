require "test_helper"

class Api::V1::Customer::TrackingControllerTest < ActionDispatch::IntegrationTest
  setup do
    @customer_user = User.create!(email: "customer.track.http@example.com", password: "password123", full_name: "Customer Track HTTP")
    @customer_user.role_assignments.create!(role: "customer")
    @customer_token = Session.issue_for(@customer_user, ip: "127.0.0.1", user_agent: "Test")

    @courier_user = User.create!(email: "courier.track.http@example.com", password: "password123", full_name: "Courier Track HTTP")
    @courier_user.role_assignments.create!(role: "courier")
    @courier = Courier.create!(
      user: @courier_user, phone: "+5511966667777", document_number: "66677788899",
      vehicle_type: "motorcycle", moderation_state: "approved", operational_state: "on_delivery",
      location_consent_given_at: Time.current
    )

    @seller = Seller.create!(name: "Track HTTP Store", moderation_state: "approved")

    @order = Order.create!(
      customer: @customer_user.customer, seller: @seller, courier: @courier, status: "picked_up",
      currency: "BRL", subtotal_cents: 2000, delivery_fee_cents: 500, total_cents: 2500,
      address_name: "Home", address_line1: "Rua Track HTTP", address_city: "São Paulo", address_state: "SP", address_zip: "01000-000", address_country: "BR"
    )

    CourierLocation.create!(
      courier: @courier, latitude: -23.5505, longitude: -46.6333,
      accuracy_meters: 5.0, recorded_at: 30.seconds.ago
    )
  end

  test "customer gets tracking information via HTTP" do
    get "/api/v1/customer/orders/#{@order.id}/tracking",
      headers: { "Authorization" => "Bearer #{@customer_token}" }

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["ok"]
    assert_equal @order.id, json["data"]["order_id"]
    assert_equal "picked_up", json["data"]["order_state"]
    assert_equal -23.5505, json["data"]["location"]["latitude"]
    assert json["data"]["freshness_seconds"].present?
  end

  test "returns 404 for unowned order tracking" do
    other_user = User.create!(email: "other.track.http@example.com", password: "password123", full_name: "Other Track HTTP")
    other_user.role_assignments.create!(role: "customer")
    other_token = Session.issue_for(other_user, ip: "127.0.0.1", user_agent: "Test")

    get "/api/v1/customer/orders/#{@order.id}/tracking",
      headers: { "Authorization" => "Bearer #{other_token}" }

    assert_response :not_found
  end
end

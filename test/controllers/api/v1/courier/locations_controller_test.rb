require "test_helper"

class Api::V1::Courier::LocationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @courier_user = User.create!(email: "courier.loc.http@example.com", password: "password123", full_name: "Courier Loc HTTP")
    @courier_user.role_assignments.create!(role: "courier")
    @courier = Courier.create!(
      user: @courier_user, phone: "+5511933334444", document_number: "33344455566",
      vehicle_type: "motorcycle", moderation_state: "approved", operational_state: "on_delivery",
      location_consent_given_at: Time.current
    )
    @token = Session.issue_for(@courier_user, ip: "127.0.0.1", user_agent: "Test")

    @seller = Seller.create!(name: "Loc HTTP Store", moderation_state: "approved")
    customer_user = User.create!(email: "customer.loc.http@example.com", password: "password123", full_name: "Customer Loc HTTP")
    customer_user.role_assignments.create!(role: "customer")

    @order = Order.create!(
      customer: customer_user.customer, seller: @seller, courier: @courier, status: "assigned",
      currency: "BRL", subtotal_cents: 1000, delivery_fee_cents: 500, total_cents: 1500,
      address_name: "Home", address_line1: "Rua Y", address_city: "São Paulo", address_state: "SP", address_zip: "01000-000", address_country: "BR"
    )
  end

  test "courier posts location update successfully via HTTP" do
    post "/api/v1/courier/location",
      headers: { "Authorization" => "Bearer #{@token}", "CONTENT_TYPE" => "application/json" },
      params: { latitude: -23.5505, longitude: -46.6333, accuracy_meters: 8.0 }.to_json

    assert_response :created
    json = JSON.parse(response.body)
    assert json["ok"]
    assert_equal -23.5505, json["data"]["latitude"]
    assert_equal -46.6333, json["data"]["longitude"]
    assert json["data"]["recorded_at"].present?
  end

  test "rejects non-numeric coordinates" do
    post "/api/v1/courier/location",
      headers: { "Authorization" => "Bearer #{@token}", "CONTENT_TYPE" => "application/json" },
      params: { latitude: "invalid", longitude: -46.6333 }.to_json

    assert_response :unprocessable_content
  end
end

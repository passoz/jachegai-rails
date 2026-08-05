require "test_helper"

class Api::V1::Courier::StatsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @courier = create_courier(index: 1)
    @other_courier = create_courier(index: 2)
    @token = Session.issue_for(@courier.user, ip: "127.0.0.1", user_agent: "Test")
    @seller = Seller.create!(name: "Stats Store", moderation_state: "approved")
    customer_user = User.create!(email: "customer.stats@example.com", password: "password123", full_name: "Customer Stats")
    customer_user.role_assignments.create!(role: "customer")
    @customer = customer_user.customer

    create_order(courier: @courier, status: "delivered", fee_cents: 500, currency: "BRL")
    create_order(courier: @courier, status: "delivered", fee_cents: 700, currency: "BRL")
    create_order(courier: @courier, status: "delivered", fee_cents: 300, currency: "USD")
    create_order(courier: @courier, status: "assigned", fee_cents: 600, currency: "BRL")
    create_order(courier: @other_courier, status: "delivered", fee_cents: 9_999, currency: "BRL")
  end

  test "stats count own completed deliveries and group fee snapshots by currency" do
    get "/api/v1/courier/stats", headers: { "Authorization" => "Bearer #{@token}" }

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal 3, json.dig("data", "completed_deliveries_count")
    assert_equal(
      [
        { "currency" => "BRL", "amount_cents" => 1_200 },
        { "currency" => "USD", "amount_cents" => 300 }
      ],
      json.dig("data", "earnings")
    )
    refute json.dig("data").key?("earnings_cents")
    refute json.dig("data").key?("currency")
  end

  test "courier with no completed deliveries gets zero count and empty earnings" do
    empty_courier = create_courier(index: 3)
    token = Session.issue_for(empty_courier.user)

    get "/api/v1/courier/stats", headers: { "Authorization" => "Bearer #{token}" }

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal 0, json.dig("data", "completed_deliveries_count")
    assert_equal [], json.dig("data", "earnings")
  end

  private

  def create_courier(index:)
    user = User.create!(email: "courier-stats-#{index}@example.com", password: "password123", full_name: "Courier Stats #{index}")
    user.role_assignments.create!(role: "courier")
    Courier.create!(
      user: user,
      phone: "+55119999900#{index.to_s.rjust(2, "0")}",
      document_number: (999_000_999_00 + index).to_s,
      vehicle_type: "motorcycle",
      moderation_state: "approved",
      operational_state: "available"
    )
  end

  def create_order(courier:, status:, fee_cents:, currency:)
    Order.create!(
      customer: @customer,
      seller: @seller,
      courier: courier,
      status: status,
      subtotal_cents: 2_000,
      delivery_fee_cents: fee_cents,
      courier_fee_cents: fee_cents,
      total_cents: 2_000 + fee_cents,
      currency: currency,
      address_name: "Home",
      address_line1: "Rua F, 303",
      address_city: "São Paulo",
      address_state: "SP",
      address_zip: "01000-000",
      address_country: "BR"
    )
  end
end

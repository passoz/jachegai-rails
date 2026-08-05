require "test_helper"

class Api::V1::Courier::DeliveryControllerTest < ActionDispatch::IntegrationTest
  setup do
    @courier_user = User.create!(
      email: "courier.deliv.http@example.com",
      password_digest: BCrypt::Password.create("password123"),
      full_name: "Courier Deliv HTTP"
    )
    @courier_user.role_assignments.create!(role: "courier")
    @courier = Courier.create!(
      user: @courier_user,
      phone: "+5511966665555",
      document_number: "66655544433",
      vehicle_type: "motorcycle",
      moderation_state: "approved",
      operational_state: "on_delivery"
    )
    @token = Session.issue_for(@courier_user, ip: "127.0.0.1", user_agent: "Test")

    @seller_user = User.create!(
      email: "seller.deliv.http@example.com",
      password_digest: BCrypt::Password.create("password123"),
      full_name: "Seller Deliv HTTP"
    )
    @seller_user.role_assignments.create!(role: "seller")
    @seller = Seller.create!(name: "Deliv HTTP Store", moderation_state: "approved")
    @seller_user.seller_memberships.create!(seller: @seller, role: "owner")

    @customer_user = User.create!(
      email: "customer.deliv.http@example.com",
      password_digest: BCrypt::Password.create("password123"),
      full_name: "Customer Deliv HTTP"
    )
    @customer_user.role_assignments.create!(role: "customer")
    @customer = @customer_user.customer || Customer.create!(user: @customer_user, full_name: @customer_user.full_name)

    @order = Order.create!(
      customer: @customer,
      seller: @seller,
      courier: @courier,
      status: "assigned",
      subtotal_cents: 2000,
      delivery_fee_cents: 500,
      total_cents: 2500,
      currency: "BRL",
      address_name: "Home",
      address_line1: "Rua E, 202",
      address_city: "São Paulo",
      address_state: "SP",
      address_zip: "01000-000",
      address_country: "BR"
    )
  end

  test "courier pickup and deliver via HTTP POST" do
    post "/api/v1/courier/orders/#{@order.id}/pickup",
      headers: { "Authorization" => "Bearer #{@token}", "CONTENT_TYPE" => "application/json", "X-Request-ID" => "pickup-http-request" }

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal "picked_up", json["data"]["order_state"]
    assert_equal "user:#{@courier_user.id}", OrderStatusHistory.last.actor_principal_id
    assert_equal "pickup-http-request", OrderStatusHistory.last.request_id

    post "/api/v1/courier/orders/#{@order.id}/deliver",
      headers: { "Authorization" => "Bearer #{@token}", "CONTENT_TYPE" => "application/json" }

    assert_response :ok
    json2 = JSON.parse(response.body)
    assert_equal "delivered", json2["data"]["order_state"]
  end

  test "another courier receives not found and cannot mutate assignment" do
    other_user = User.create!(email: "courier-deliv-other@example.com", password: "password123", full_name: "Other Courier")
    other_user.role_assignments.create!(role: "courier")
    Courier.create!(
      user: other_user,
      phone: "+5511966665556",
      document_number: "66655544434",
      vehicle_type: "bicycle",
      moderation_state: "approved",
      operational_state: "available"
    )

    post "/api/v1/courier/orders/#{@order.id}/pickup",
      headers: { "Authorization" => "Bearer #{Session.issue_for(other_user)}", "Content-Type" => "application/json" }

    assert_response :not_found
    assert_equal "not_found", JSON.parse(response.body).dig("error", "code")
    assert_equal "assigned", @order.reload.status
  end
end

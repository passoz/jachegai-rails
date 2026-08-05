require "test_helper"

class CustomerTrackingServiceTest < ActiveSupport::TestCase
  setup do
    @customer_user = User.create!(email: "customer.track@example.com", password: "password123", full_name: "Customer Track")
    @customer_user.role_assignments.create!(role: "customer")
    @customer = @customer_user.customer
    @customer_principal = Principal.new(user: @customer_user)

    @other_customer_user = User.create!(email: "other.track@example.com", password: "password123", full_name: "Other Track")
    @other_customer_user.role_assignments.create!(role: "customer")
    @other_principal = Principal.new(user: @other_customer_user)

    @courier_user = User.create!(email: "courier.track@example.com", password: "password123", full_name: "Courier Track")
    @courier_user.role_assignments.create!(role: "courier")
    @courier = Courier.create!(
      user: @courier_user, phone: "+5511955556666", document_number: "55566677788",
      vehicle_type: "motorcycle", moderation_state: "approved", operational_state: "on_delivery",
      location_consent_given_at: Time.current
    )

    @seller = Seller.create!(name: "Track Store", moderation_state: "approved")

    @order = Order.create!(
      customer: @customer, seller: @seller, courier: @courier, status: "picked_up",
      currency: "BRL", subtotal_cents: 2000, delivery_fee_cents: 500, total_cents: 2500,
      address_name: "Home", address_line1: "Rua Track", address_city: "São Paulo", address_state: "SP", address_zip: "01000-000", address_country: "BR"
    )

    OrderStatusHistory.create!(
      order: @order, from_status: "ready", to_status: "assigned",
      actor_principal_id: "user:#{@courier_user.id}", occurred_at: 10.minutes.ago
    )
    OrderStatusHistory.create!(
      order: @order, from_status: "assigned", to_status: "picked_up",
      actor_principal_id: "user:#{@courier_user.id}", occurred_at: 5.minutes.ago
    )

    @location = CourierLocation.create!(
      courier: @courier, latitude: -23.5505, longitude: -46.6333,
      accuracy_meters: 5.0, recorded_at: 1.minute.ago
    )
  end

  test "returns tracking detail for order owner with latest location and freshness" do
    service = CustomerTrackingService.new(@customer_principal)
    tracking = service.get_tracking(@order.id)

    assert_equal @order.id, tracking[:order_id]
    assert_equal "picked_up", tracking[:order_state]
    assert_equal 2, tracking[:history].size
    assert tracking[:location].present?
    assert_equal -23.5505, tracking[:location][:latitude]
    assert tracking[:freshness_seconds] >= 55
  end

  test "returns nil location when no location has been published" do
    CourierLocation.delete_all
    service = CustomerTrackingService.new(@customer_principal)
    tracking = service.get_tracking(@order.id)

    assert_equal @order.id, tracking[:order_id]
    assert_nil tracking[:location]
    assert_nil tracking[:freshness_seconds]
  end

  test "other customer cannot access order tracking" do
    service = CustomerTrackingService.new(@other_principal)

    assert_raises ActiveRecord::RecordNotFound do
      service.get_tracking(@order.id)
    end
  end
end

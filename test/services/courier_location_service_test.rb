require "test_helper"

class CourierLocationServiceTest < ActiveSupport::TestCase
  setup do
    @courier_user = User.create!(email: "courier.loc.svc@example.com", password: "password123", full_name: "Courier Loc Svc")
    @courier_user.role_assignments.create!(role: "courier")
    @courier = Courier.create!(
      user: @courier_user, phone: "+5511922223333", document_number: "22233344455",
      vehicle_type: "motorcycle", moderation_state: "approved", operational_state: "available",
      location_consent_given_at: Time.current
    )
    @principal = Principal.new(user: @courier_user)

    @seller = Seller.create!(name: "Loc Store", moderation_state: "approved")
    customer_user = User.create!(email: "customer.loc@example.com", password: "password123", full_name: "Customer Loc")
    customer_user.role_assignments.create!(role: "customer")

    @order = Order.create!(
      customer: customer_user.customer, seller: @seller, courier: @courier, status: "assigned",
      currency: "BRL", subtotal_cents: 1000, delivery_fee_cents: 500, total_cents: 1500,
      address_name: "Home", address_line1: "Rua X", address_city: "São Paulo", address_state: "SP", address_zip: "01000-000", address_country: "BR"
    )
    @courier.update!(operational_state: "on_delivery")
  end

  test "records location when courier has consent and active delivery" do
    service = CourierLocationService.new(@principal)
    loc = service.record_location!(latitude: -23.5505, longitude: -46.6333, accuracy_meters: 5.0)

    assert loc.persisted?
    assert_equal @courier.id, loc.courier_id
    assert_equal -23.5505, loc.latitude
    assert_equal -46.6333, loc.longitude
    assert loc.recorded_at.present?
  end

  test "fails if courier has not given location consent" do
    @courier.update!(location_consent_given_at: nil)
    service = CourierLocationService.new(@principal)

    error = assert_raises DomainError do
      service.record_location!(latitude: -23.5505, longitude: -46.6333)
    end
    assert_equal "location_consent_required", error.code
  end

  test "fails if courier has no active delivery" do
    @order.update!(status: "delivered")
    @courier.update!(operational_state: "available")
    service = CourierLocationService.new(@principal)

    error = assert_raises DomainError do
      service.record_location!(latitude: -23.5505, longitude: -46.6333)
    end
    assert_equal "active_delivery_required", error.code
  end
end

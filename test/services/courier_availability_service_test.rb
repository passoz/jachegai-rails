require "test_helper"

class CourierAvailabilityServiceTest < ActiveSupport::TestCase
  setup do
    @courier_user = User.create!(
      email: "courier.avail@example.com",
      password_digest: BCrypt::Password.create("password123"),
      full_name: "Courier Avail"
    )
    @courier_user.role_assignments.create!(role: "courier")
    @courier = Courier.create!(
      user: @courier_user,
      phone: "+5511955554444",
      document_number: "44455566677",
      vehicle_type: "motorcycle",
      moderation_state: "pending_review",
      operational_state: "offline"
    )
    session = Session.issue_for(@courier_user, ip: "127.0.0.1", user_agent: "Test")
    @principal = Principal.new(user: @courier_user, session: session)
  end

  test "unapproved courier cannot become available" do
    service = CourierAvailabilityService.new(@principal)

    assert_raises DomainError do
      service.set_availability!(state: "available")
    end
    assert_equal "offline", @courier.reload.operational_state
  end

  test "principal without courier role cannot change availability" do
    @courier_user.role_assignments.where(role: "courier").delete_all
    service = CourierAvailabilityService.new(@principal)

    error = assert_raises DomainError do
      service.set_availability!(state: "offline")
    end

    assert_equal "forbidden", error.code
    assert_equal "offline", @courier.reload.operational_state
  end

  test "approved courier can switch between available and offline" do
    @courier.update!(moderation_state: "approved")
    service = CourierAvailabilityService.new(@principal)

    updated = service.set_availability!(state: "available")
    assert_equal "available", updated.operational_state

    updated_off = service.set_availability!(state: "offline")
    assert_equal "offline", updated_off.operational_state
  end

  test "active assigned order prevents offline even if operational state is stale" do
    @courier.update!(moderation_state: "approved", operational_state: "available")
    create_active_order_for(@courier, status: "assigned")
    service = CourierAvailabilityService.new(@principal)

    error = assert_raises DomainError do
      service.set_availability!(state: "offline")
    end

    assert_equal "active_delivery_in_progress", error.code
    assert_equal "available", @courier.reload.operational_state
  end

  test "active assigned order prevents becoming available after moderation state recovery" do
    @courier.update!(moderation_state: "approved", operational_state: "offline")
    create_active_order_for(@courier, status: "assigned")
    service = CourierAvailabilityService.new(@principal)

    error = assert_raises DomainError do
      service.set_availability!(state: "available")
    end

    assert_equal "active_delivery_in_progress", error.code
    assert_equal "offline", @courier.reload.operational_state
  end

  test "courier on_delivery cannot switch to offline" do
    @courier.update!(moderation_state: "approved", operational_state: "on_delivery")
    service = CourierAvailabilityService.new(@principal)

    error = assert_raises DomainError do
      service.set_availability!(state: "offline")
    end
    assert_equal "active_delivery_in_progress", error.code
    assert_equal "on_delivery", @courier.reload.operational_state
  end

  private

  def create_active_order_for(courier, status:)
    seller = Seller.create!(name: "Availability Store", moderation_state: "approved")
    customer_user = User.create!(email: "availability-customer@example.com", password: "password123", full_name: "Customer")
    customer_user.role_assignments.create!(role: "customer")

    Order.create!(
      customer: customer_user.customer,
      seller: seller,
      courier: courier,
      status: status,
      subtotal_cents: 2_000,
      delivery_fee_cents: 500,
      total_cents: 2_500,
      currency: "BRL",
      address_name: "Home",
      address_line1: "Rua A, 1",
      address_city: "São Paulo",
      address_state: "SP",
      address_zip: "01000-000",
      address_country: "BR"
    )
  end
end

require "test_helper"

class CourierTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      email: "courier.test@example.com",
      password_digest: BCrypt::Password.create("password123"),
      full_name: "Test Courier"
    )
    @user.role_assignments.create!(role: "courier")
  end

  test "creates valid courier in pending_review and offline state by default" do
    courier = Courier.new(
      user: @user,
      phone: "+5511999999999",
      document_number: "12345678901",
      vehicle_type: "motorcycle",
      vehicle_plate: "ABC1D23"
    )

    assert courier.valid?
    assert_equal "pending_review", courier.moderation_state
    assert_equal "offline", courier.operational_state
  end

  test "enforces unique user_id and unique document_number" do
    Courier.create!(
      user: @user,
      phone: "+5511999999999",
      document_number: "12345678901",
      vehicle_type: "motorcycle",
      vehicle_plate: "ABC1D23"
    )

    user2 = User.create!(
      email: "courier2.test@example.com",
      password_digest: BCrypt::Password.create("password123"),
      full_name: "Test Courier 2"
    )
    user2.role_assignments.create!(role: "courier")

    duplicate_user = Courier.new(
      user: @user,
      phone: "+5511888888888",
      document_number: "98765432100",
      vehicle_type: "bicycle"
    )
    refute duplicate_user.valid?

    duplicate_doc = Courier.new(
      user: user2,
      phone: "+5511888888888",
      document_number: "12345678901",
      vehicle_type: "bicycle"
    )
    refute duplicate_doc.valid?
  end

  test "validates moderation_state and operational_state values" do
    courier = Courier.new(
      user: @user,
      phone: "+5511999999999",
      document_number: "12345678901",
      vehicle_type: "motorcycle"
    )

    courier.moderation_state = "invalid_state"
    refute courier.valid?

    courier.moderation_state = "approved"
    courier.operational_state = "invalid_op"
    refute courier.valid?

    courier.operational_state = "available"
    assert courier.valid?
  end

  test "database constraints reject invalid state dimensions" do
    courier = Courier.create!(
      user: @user,
      phone: "+5511999999999",
      document_number: "12345678901",
      vehicle_type: "motorcycle"
    )

    assert_raises ActiveRecord::StatementInvalid do
      Courier.where(id: courier.id).update_all(moderation_state: "invalid")
    end
    assert_raises ActiveRecord::StatementInvalid do
      Courier.where(id: courier.id).update_all(operational_state: "invalid")
    end
  end

  test "database keeps unapproved couriers offline" do
    courier = Courier.create!(
      user: @user,
      phone: "+5511999999999",
      document_number: "12345678901",
      vehicle_type: "motorcycle"
    )

    %w[pending_review rejected suspended].each do |moderation_state|
      Courier.where(id: courier.id).update_all(moderation_state: moderation_state, operational_state: "offline")
      assert_raises ActiveRecord::StatementInvalid do
        Courier.where(id: courier.id).update_all(operational_state: "available")
      end
    end
  end

  test "database prevents more than one active order per courier" do
    courier = Courier.create!(
      user: @user,
      phone: "+5511999999999",
      document_number: "12345678901",
      vehicle_type: "motorcycle",
      moderation_state: "approved",
      operational_state: "on_delivery"
    )
    seller = Seller.create!(name: "Active Order Store", moderation_state: "approved")
    customer_user = User.create!(email: "active-order-customer@example.com", password: "password123", full_name: "Customer")
    customer_user.role_assignments.create!(role: "customer")
    create_order_for(courier: courier, seller: seller, customer: customer_user.customer, status: "assigned")

    duplicate = build_order_for(courier: courier, seller: seller, customer: customer_user.customer, status: "picked_up")
    assert_raises ActiveRecord::RecordNotUnique do
      duplicate.save!(validate: false)
    end
  end

  test "validates vehicle_type options" do
    courier = Courier.new(
      user: @user,
      phone: "+5511999999999",
      document_number: "12345678901",
      vehicle_type: "rocket"
    )
    refute courier.valid?
  end

  private

  def create_order_for(courier:, seller:, customer:, status:)
    build_order_for(courier: courier, seller: seller, customer: customer, status: status).tap(&:save!)
  end

  def build_order_for(courier:, seller:, customer:, status:)
    Order.new(
      customer: customer,
      seller: seller,
      courier: courier,
      status: status,
      subtotal_cents: 100,
      delivery_fee_cents: 0,
      total_cents: 100,
      currency: "BRL",
      address_name: "Home",
      address_line1: "Rua A",
      address_city: "City",
      address_state: "ST",
      address_zip: "1",
      address_country: "BR"
    )
  end
end

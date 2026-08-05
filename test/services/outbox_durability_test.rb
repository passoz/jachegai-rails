require "test_helper"

class OutboxDurabilityTest < ActiveSupport::TestCase
  setup do
    @customer_user = User.create!(email: "durable-buyer@example.com", password: "password123", full_name: "Buyer")
    @customer = Customer.create!(user: @customer_user, full_name: "Buyer")
    @seller = Seller.create!(name: "Durable Merchant", moderation_state: "approved")

    @order = Order.create!(
      customer: @customer, seller: @seller, status: "pending", currency: "BRL",
      subtotal_cents: 1000, delivery_fee_cents: 0, discount_cents: 0, courier_fee_cents: 0,
      total_cents: 1000, address_name: "Home", address_line1: "123 Main St",
      address_city: "City", address_state: "ST", address_zip: "12345", address_country: "BR"
    )

    @payment = Payment.create!(order: @order, state: "pending", amount_cents: 1000, currency: "BRL")
    @admin_user = User.create!(email: "durable-admin@example.com", password: "password123", full_name: "Admin")
    @admin_user.role_assignments.create!(role: "admin")
    @admin_principal = Principal.new(user: @admin_user)
  end

  test "business commit leaves pending outbox event that a later dispatch recovers" do
    # Business commit creates the outbox event inside the transaction
    PaymentConfirmationService.new(@payment, actor: @admin_principal).confirm_payment!

    event = OutboxEvent.where(aggregate_type: "Payment", aggregate_id: @payment.id).last
    assert event.present?
    assert_equal "pending", event.state, "event must remain pending until dispatched"
    assert_equal 0, event.attempts

    # Simulate process restart: no in-memory handler state survives; a fresh
    # dispatch run picks the event up from the durable table.
    OutboxDispatchJob.perform_now

    assert_equal "completed", event.reload.state
    assert_equal 1, event.attempts
    assert_not_nil event.completed_at
  end
end

require "test_helper"

class PaymentConfirmationServiceTest < ActiveSupport::TestCase
  setup do
    @customer_user = User.create!(email: "buyer@example.com", password: "password123", full_name: "Buyer")
    @customer = Customer.create!(user: @customer_user, full_name: "Buyer")
    @seller = Seller.create!(name: "Merchant Store", moderation_state: "approved")

    @order = Order.create!(
      customer: @customer, seller: @seller, status: "pending", currency: "BRL",
      subtotal_cents: 1000, delivery_fee_cents: 0, discount_cents: 0, courier_fee_cents: 0,
      total_cents: 1000, address_name: "Home", address_line1: "123 Main St",
      address_city: "City", address_state: "ST", address_zip: "12345", address_country: "BR"
    )

    @payment = Payment.create!(
      order: @order, state: "pending", amount_cents: 1000, currency: "BRL"
    )

    @admin_user = User.create!(email: "admin@example.com", password: "password123", full_name: "Admin")
    @admin_user.role_assignments.create!(role: "admin")
    @admin_principal = Principal.new(user: @admin_user)
  end

  test "admin confirms pending payment successfully" do
    service = PaymentConfirmationService.new(@payment, actor: @admin_principal)

    assert_difference -> { AuditRecord.count } => 1, -> { OutboxEvent.count } => 1 do
      service.confirm_payment!
    end

    assert_equal "paid", @payment.reload.state
    event = OutboxEvent.last
    assert_equal "payment.confirmed", event.event_type
    payload = JSON.parse(event.payload)
    assert_equal @payment.id, payload["payment_id"]
    assert_equal "paid", payload["state"]

    audit = AuditRecord.last
    assert_equal "confirm_payment", audit.action
  end

  test "confirmation rolls back payment and audit when outbox persistence fails" do
    event_key = "payment:#{@payment.id}:confirmed"
    OutboxEvent.create!(
      event_key: event_key,
      event_type: "probe.conflict",
      aggregate_type: "Probe",
      aggregate_id: @payment.id,
      payload: "{}",
      available_at: Time.current
    )
    service = PaymentConfirmationService.new(@payment, actor: @admin_principal)

    assert_raises ActiveRecord::RecordInvalid do
      service.confirm_payment!
    end

    assert_equal "pending", @payment.reload.state
    assert_empty AuditRecord.where(resource_type: "Payment", resource_id: @payment.id)
    assert_equal 1, OutboxEvent.where(event_key: event_key).count
  end

  test "confirming already paid payment is idempotent and no-op" do
    @payment.update!(state: "paid")
    service = PaymentConfirmationService.new(@payment, actor: @admin_principal)

    assert_no_difference -> { AuditRecord.count } do
      assert_no_difference -> { OutboxEvent.count } do
        service.confirm_payment!
      end
    end

    assert_equal "paid", @payment.reload.state
  end

  test "confirming failed or refunded payment returns conflict" do
    @payment.update!(state: "failed")
    service = PaymentConfirmationService.new(@payment, actor: @admin_principal)

    err = assert_raises DomainError do
      service.confirm_payment!
    end
    assert_equal "payment_conflict", err.code

    @payment.update!(state: "refunded")
    err = assert_raises DomainError do
      service.confirm_payment!
    end
    assert_equal "payment_conflict", err.code
  end

  test "confirming payment for rejected or cancelled order returns conflict" do
    @order.update!(status: "cancelled")
    service = PaymentConfirmationService.new(@payment, actor: @admin_principal)

    err = assert_raises DomainError do
      service.confirm_payment!
    end
    assert_equal "order_conflict", err.code
  end

  test "confirmation rechecks authoritative order state inside the transaction" do
    assert_equal "pending", @payment.order.status
    Order.where(id: @order.id).update_all(status: "cancelled", updated_at: Time.current)
    service = PaymentConfirmationService.new(@payment, actor: @admin_principal)

    error = assert_raises DomainError do
      service.confirm_payment!
    end

    assert_equal "order_conflict", error.code
    assert_equal "pending", @payment.reload.state
    assert_empty OutboxEvent.where(aggregate_type: "Payment", aggregate_id: @payment.id)
  end

  test "non-admin cannot confirm payment" do
    buyer_principal = Principal.new(user: @customer_user)
    service = PaymentConfirmationService.new(@payment, actor: buyer_principal)

    assert_raises ActiveRecord::RecordNotFound do
      service.confirm_payment!
    end
  end
end

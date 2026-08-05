require "test_helper"

class PendingPaymentExpirationJobTest < ActiveSupport::TestCase
  setup do
    @customer_user = User.create!(email: "buyer@example.com", password: "password123", full_name: "Buyer")
    @customer_user.role_assignments.create!(role: "customer")
    @customer = @customer_user.customer

    @seller = Seller.create!(name: "Merchant Store", moderation_state: "approved")

    @product = Product.create!(
      seller: @seller, name: "Pizza", price_cents: 1000, currency: "BRL",
      active: true, category: Category.create!(seller: @seller, name: "Food", position: 1)
    )
    @inventory = InventoryItem.create!(product: @product, seller: @seller, quantity: 10)

    # 1. Pedido pendente antigo (31 minutos atrás) - deve expirar
    @expired_order = Order.create!(
      customer: @customer, seller: @seller, status: "pending", currency: "BRL",
      subtotal_cents: 1000, delivery_fee_cents: 0, discount_cents: 0, courier_fee_cents: 0,
      total_cents: 1000, address_name: "Home", address_line1: "123 Main St",
      address_city: "City", address_state: "ST", address_zip: "12345", address_country: "BR",
      created_at: 31.minutes.ago
    )
    @expired_order.order_items.create!(
      product: @product, seller: @seller, product_name: "Pizza",
      quantity: 1, unit_price_cents: 1000, subtotal_cents: 1000, currency: "BRL"
    )
    @expired_payment = Payment.create!(
      order: @expired_order, state: "pending", amount_cents: 1000, currency: "BRL"
    )
    @inventory.decrement!(:quantity, 1) # Estoque vai para 9

    # 2. Pedido pendente recente (15 minutos atrás) - NÃO deve expirar
    @recent_order = Order.create!(
      customer: @customer, seller: @seller, status: "pending", currency: "BRL",
      subtotal_cents: 1000, delivery_fee_cents: 0, discount_cents: 0, courier_fee_cents: 0,
      total_cents: 1000, address_name: "Home", address_line1: "123 Main St",
      address_city: "City", address_state: "ST", address_zip: "12345", address_country: "BR",
      created_at: 15.minutes.ago
    )
    @recent_payment = Payment.create!(
      order: @recent_order, state: "pending", amount_cents: 1000, currency: "BRL"
    )

    # 3. Pedido antigo mas já pago - NÃO deve expirar
    @paid_order = Order.create!(
      customer: @customer, seller: @seller, status: "pending", currency: "BRL",
      subtotal_cents: 1000, delivery_fee_cents: 0, discount_cents: 0, courier_fee_cents: 0,
      total_cents: 1000, address_name: "Home", address_line1: "123 Main St",
      address_city: "City", address_state: "ST", address_zip: "12345", address_country: "BR",
      created_at: 40.minutes.ago
    )
    @paid_payment = Payment.create!(
      order: @paid_order, state: "paid", amount_cents: 1000, currency: "BRL"
    )
  end

  test "expires old pending payments, restores inventory and ignores active orders" do
    assert_difference -> { InventoryMovement.count } => 1 do
      PendingPaymentExpirationJob.perform_now
    end

    assert_equal "cancelled", @expired_order.reload.status
    assert_equal "failed", @expired_payment.reload.state
    assert_equal "order_cancelled", @expired_payment.last_error_code
    assert_equal 10, @inventory.reload.quantity # Restaurou 9 + 1

    # Recent order remains pending
    assert_equal "pending", @recent_order.reload.status
    assert_equal "pending", @recent_payment.reload.state

    # Paid order remains pending
    assert_equal "pending", @paid_order.reload.status
    assert_equal "paid", @paid_payment.reload.state
  end

  test "expiration is idempotent across repeated job runs" do
    PendingPaymentExpirationJob.perform_now

    counts_before_retry = [ InventoryMovement.count, OrderStatusHistory.count, OutboxEvent.count ]

    PendingPaymentExpirationJob.perform_now

    assert_equal counts_before_retry, [ InventoryMovement.count, OrderStatusHistory.count, OutboxEvent.count ]
    assert_equal "cancelled", @expired_order.reload.status
    assert_equal 10, @inventory.reload.quantity
  end
end

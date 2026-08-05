require "test_helper"

class InvoiceServiceTest < ActiveSupport::TestCase
  setup do
    @seller = Seller.create!(name: "Seller Invoice Test", moderation_state: "approved")
    @customer = Customer.create!(user: User.create!(email: "customer-invoice@example.com", password: "password123", full_name: "Customer"), full_name: "Customer")

    @order = Order.create!(
      customer: @customer, seller: @seller, status: "delivered", currency: "BRL",
      subtotal_cents: 10000, delivery_fee_cents: 1000, discount_cents: 0, courier_fee_cents: 500,
      total_cents: 11000, address_name: "Home", address_line1: "Line 1", address_city: "City", address_state: "ST", address_zip: "123", address_country: "BR",
      created_at: Time.current.beginning_of_month
    )
  end

  test "generate_for_period creates invoice using completed orders and fee calculation" do
    service = InvoiceService.new(seller: @seller, period_start: Time.current.beginning_of_month.to_date, period_end: Time.current.end_of_month.to_date)
    invoice = service.generate!

    assert invoice.persisted?
    assert_equal 10000, invoice.gross_amount_cents
    assert_equal "pending", invoice.state
  end

  test "generate_for_period is idempotent" do
    period_start = Time.current.beginning_of_month.to_date
    period_end = Time.current.end_of_month.to_date

    service = InvoiceService.new(seller: @seller, period_start: period_start, period_end: period_end)
    inv1 = service.generate!
    inv2 = service.generate!

    assert_equal inv1.id, inv2.id
  end
end

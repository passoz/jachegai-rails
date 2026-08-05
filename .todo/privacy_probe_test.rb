require "test_helper"

class PrivacyProbeTest < ActiveSupport::TestCase
  test "probe setup" do
    user = User.create!(email: "privacy-owner@example.com", password: "password123", full_name: "Ana Owner")
    user.role_assignments.create!(role: "customer")
    customer = user.customer
    customer.update!(full_name: "Ana Owner")
    address = Address.create!(
      customer: customer, name: "Casa", line1: "Rua das Flores 10", city: "São Paulo",
      state: "SP", zip: "01000-000", country: "BR", is_default: true
    )
    seller = Seller.create!(name: "Loja A", moderation_state: "approved", contact_email: "loja@example.com")
    order = Order.create!(
      customer: customer, seller: seller, status: "delivered",
      currency: "BRL", subtotal_cents: 1000, delivery_fee_cents: 500,
      discount_cents: 0, courier_fee_cents: 0, total_cents: 1500,
      address_name: "Ana Owner", address_line1: "Rua das Flores 10",
      address_city: "São Paulo", address_state: "SP", address_zip: "01000-000",
      address_country: "BR"
    )
    Payment.create!(
      order: order, state: "paid", method: "card", provider: "simulated",
      external_reference: "pay-1", amount_cents: 1500, currency: "BRL"
    )
    result = Privacy::ExportService.export(user)
    puts result.keys.inspect
  end
end

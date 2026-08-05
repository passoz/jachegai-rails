require "test_helper"

class GuestCartHandoffServiceTest < ActiveSupport::TestCase
  setup do
    user = User.create!(email: "handoff-service@example.com", password: "password123", full_name: "Customer")
    user.role_assignments.create!(role: "customer")
    @customer = user.customer
    @seller1 = Seller.create!(name: "Seller One", moderation_state: "approved")
    @seller2 = Seller.create!(name: "Seller Two", moderation_state: "approved")
    category1 = Category.create!(seller: @seller1, name: "One", position: 1)
    category2 = Category.create!(seller: @seller2, name: "Two", position: 1)
    @product1 = Product.create!(seller: @seller1, category: category1, name: "One", price_cents: 500, currency: "BRL", active: true)
    @product2 = Product.create!(seller: @seller2, category: category2, name: "Two", price_cents: 700, currency: "BRL", active: true)
    InventoryItem.create!(seller: @seller1, product: @product1, quantity: 10)
    InventoryItem.create!(seller: @seller2, product: @product2, quantity: 2)
  end

  test "merges same-seller quantities and retry is idempotent" do
    token, guest_cart = guest_cart_for(@seller1, @product1, 2)
    customer_cart = CustomerCartService.add_item(customer: @customer, product_id: @product1.id, quantity: 3)

    GuestCartHandoffService.handoff(customer: @customer, guest_token: token)
    GuestCartHandoffService.handoff(customer: @customer, guest_token: token)

    assert_equal 5, customer_cart.reload.cart_items.find_by!(product: @product1).quantity
    refute GuestCart.exists?(guest_cart.id)
  end

  test "different seller requires explicit replacement and preserves both carts" do
    customer_cart = CustomerCartService.add_item(customer: @customer, product_id: @product1.id, quantity: 1)
    token, guest_cart = guest_cart_for(@seller2, @product2, 1)

    error = assert_raises(DomainError) do
      GuestCartHandoffService.handoff(customer: @customer, guest_token: token)
    end

    assert_equal "seller_conflict", error.code
    assert_equal [ @product1.id ], customer_cart.reload.cart_items.pluck(:product_id)
    assert GuestCart.exists?(guest_cart.id)
  end

  test "failed confirmed replacement rolls back and preserves both carts" do
    customer_cart = CustomerCartService.add_item(customer: @customer, product_id: @product1.id, quantity: 1)
    token, guest_cart = guest_cart_for(@seller2, @product2, 2)
    @seller2.update!(moderation_state: "suspended")

    assert_raises ActiveRecord::RecordInvalid do
      GuestCartHandoffService.handoff(customer: @customer, guest_token: token, replace_confirmed: true)
    end

    assert_equal @seller1.id, customer_cart.reload.seller_id
    assert_equal [ @product1.id ], customer_cart.cart_items.pluck(:product_id)
    assert GuestCart.exists?(guest_cart.id)
  end

  private

  def guest_cart_for(seller, product, quantity)
    token, digest = GuestCart.generate_token
    cart = GuestCart.create!(token_digest: digest, seller: seller)
    cart.guest_cart_items.create!(product: product, seller: seller, quantity: quantity)
    [ token, cart ]
  end
end

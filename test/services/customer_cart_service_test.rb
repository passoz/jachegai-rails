require "test_helper"

class CustomerCartServiceTest < ActiveSupport::TestCase
  setup do
    user = User.create!(email: "cart-service@example.com", password: "password123", full_name: "Customer")
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

  test "adds and accumulates an authoritative product" do
    cart = CustomerCartService.add_item(customer: @customer, product_id: @product1.id, quantity: 2)
    CustomerCartService.add_item(customer: @customer, product_id: @product1.id, quantity: 3)

    assert_equal @seller1.id, cart.reload.seller_id
    assert_equal 5, cart.cart_items.find_by!(product: @product1).quantity
  end

  test "requires confirmation before replacing another seller" do
    cart = CustomerCartService.add_item(customer: @customer, product_id: @product1.id, quantity: 1)

    error = assert_raises(DomainError) do
      CustomerCartService.add_item(customer: @customer, product_id: @product2.id, quantity: 1)
    end

    assert_equal "seller_conflict", error.code
    assert_equal @seller1.id, cart.reload.seller_id
    assert_equal [ @product1.id ], cart.cart_items.pluck(:product_id)
  end

  test "failed confirmed replacement rolls back the original cart" do
    cart = CustomerCartService.add_item(customer: @customer, product_id: @product1.id, quantity: 1)

    assert_raises ActiveRecord::RecordInvalid do
      CustomerCartService.add_item(
        customer: @customer,
        product_id: @product2.id,
        quantity: 3,
        replace_confirmed: true
      )
    end

    assert_equal @seller1.id, cart.reload.seller_id
    assert_equal [ @product1.id ], cart.cart_items.pluck(:product_id)
  end

  test "updates quantity and zero removes the item" do
    cart = CustomerCartService.add_item(customer: @customer, product_id: @product1.id, quantity: 1)
    item = cart.cart_items.first

    CustomerCartService.update_item(customer: @customer, item_id: item.id, quantity: 4)
    assert_equal 4, item.reload.quantity

    CustomerCartService.update_item(customer: @customer, item_id: item.id, quantity: 0)
    refute CartItem.exists?(item.id)
    assert_nil cart.reload.seller_id
  end

  test "clears all items while retaining the persistent cart" do
    cart = CustomerCartService.add_item(customer: @customer, product_id: @product1.id, quantity: 1)

    result = CustomerCartService.clear(customer: @customer)

    assert_equal cart.id, result.id
    assert_empty cart.reload.cart_items
    assert_nil cart.seller_id
  end

  test "removing the last item clears the retained cart seller" do
    cart = CustomerCartService.add_item(customer: @customer, product_id: @product1.id, quantity: 1)
    item = cart.cart_items.first

    CustomerCartService.remove_item(customer: @customer, item_id: item.id)

    assert_empty cart.reload.cart_items
    assert_nil cart.seller_id
  end
end

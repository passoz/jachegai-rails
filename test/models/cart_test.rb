require "test_helper"

class CartTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email: "customer@example.com", password: "password123", full_name: "Customer User")
    @user.role_assignments.create!(role: "customer")
    @seller1 = Seller.create!(name: "Seller 1", moderation_state: "approved")
    @seller2 = Seller.create!(name: "Seller 2", moderation_state: "approved")

    @category1 = Category.create!(seller: @seller1, name: "Cat 1", position: 1)
    @category2 = Category.create!(seller: @seller2, name: "Cat 2", position: 1)

    @prod1 = Product.create!(seller: @seller1, category: @category1, name: "Prod 1", price_cents: 500, currency: "BRL", active: true)
    @prod2 = Product.create!(seller: @seller2, category: @category2, name: "Prod 2", price_cents: 1000, currency: "BRL", active: true)
    @inactive_prod = Product.create!(seller: @seller1, category: @category1, name: "Soda", price_cents: 300, currency: "BRL", active: false)
    @no_stock_prod = Product.create!(seller: @seller1, category: @category1, name: "Water", price_cents: 200, currency: "BRL", active: true)

    InventoryItem.create!(seller: @seller1, product: @prod1, quantity: 10)
    InventoryItem.create!(seller: @seller2, product: @prod2, quantity: 10)
    InventoryItem.create!(seller: @seller1, product: @inactive_prod, quantity: 10)
    InventoryItem.create!(seller: @seller1, product: @no_stock_prod, quantity: 0)
  end

  test "valid cart belongs to a customer and has optional seller" do
    cart = Cart.new(customer: @user.customer)
    assert cart.valid?

    cart.seller = @seller1
    assert cart.valid?

    refute Cart.new(customer: nil).valid?
  end

  test "enforces single seller per customer cart" do
    cart = Cart.create!(customer: @user.customer, seller: @seller1)

    # Valid item from same seller
    item1 = cart.cart_items.build(product: @prod1, seller: @seller1, quantity: 2)
    assert item1.valid?

    # Invalid item from different seller
    item2 = cart.cart_items.build(product: @prod2, seller: @seller2, quantity: 1)
    refute item2.valid?
    assert_includes item2.errors[:product], "must belong to the cart seller"

    # Enforced by database composite foreign keys as well
    assert_raises ActiveRecord::InvalidForeignKey do
      CartItem.insert_all!(
        [ {
          id: ApplicationId.generate,
          cart_id: cart.id,
          product_id: @prod2.id,
          seller_id: @seller2.id,
          quantity: 1,
          created_at: Time.current,
          updated_at: Time.current
        } ]
      )
    end
  end

  test "validates quantity is within 1..100 bounds and inventory stock" do
    cart = Cart.create!(customer: @user.customer, seller: @seller1)

    # Valid
    item = cart.cart_items.build(product: @prod1, seller: @seller1, quantity: 5)
    assert item.valid?

    # Exceeds max quantity bound
    item.quantity = 101
    refute item.valid?
    assert item.errors[:quantity].any?

    # Less than 1
    item.quantity = 0
    refute item.valid?
    assert item.errors[:quantity].any?

    # Exceeds inventory stock (which is 10)
    item.quantity = 15
    refute item.valid?
    assert_includes item.errors[:quantity], "must be less than or equal to available stock (10)"
  end

  test "rejects adding inactive or out of stock products" do
    cart = Cart.create!(customer: @user.customer, seller: @seller1)

    item1 = cart.cart_items.build(product: @inactive_prod, seller: @seller1, quantity: 1)
    refute item1.valid?

    item2 = cart.cart_items.build(product: @no_stock_prod, seller: @seller1, quantity: 1)
    refute item2.valid?
  end
end

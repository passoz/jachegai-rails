require "test_helper"

class CheckoutConcurrencyTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  setup do
    cleanup_checkout_tables
    @seller = Seller.create!(name: "Concurrency Seller", moderation_state: "approved")
    category = Category.create!(seller: @seller, name: "Only", position: 1)
    @product = Product.create!(seller: @seller, category: category, name: "Last Unit", price_cents: 1_000, currency: "BRL", active: true)
    @inventory = InventoryItem.create!(seller: @seller, product: @product, quantity: 1)
    @buyers = 2.times.map { |index| create_buyer(index) }
  end

  teardown do
    cleanup_checkout_tables
  end

  test "two connections buying the last unit produce exactly one complete order" do
    ready = Queue.new
    start = Queue.new

    threads = @buyers.map.with_index do |buyer, index|
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          ready << true
          start.pop
          begin
            order = CheckoutService.new.call(
              customer: buyer.fetch(:customer),
              address_id: buyer.fetch(:address).id,
              idempotency_key: "concurrent-#{index}",
              actor_principal_id: buyer.fetch(:user).id,
              request_id: "concurrent-request-#{index}"
            )
            [ :success, order.id ]
          rescue DomainError => error
            [ :domain_error, error.code ]
          end
        end
      end
    end

    2.times { ready.pop }
    2.times { start << true }
    results = threads.map(&:value)

    assert_equal 1, results.count { |kind, _| kind == :success }
    assert_equal 1, results.count { |kind, code| kind == :domain_error && code == "insufficient_inventory" }
    assert_equal 0, @inventory.reload.quantity
    assert_equal 1, Order.count
    assert_equal 1, Payment.count
    assert_equal 1, InventoryMovement.count
    assert_equal 1, OutboxEvent.count
    assert_equal 1, @buyers.count { |buyer| buyer.fetch(:customer).cart.reload.cart_items.empty? }
    assert_equal 1, @buyers.count { |buyer| buyer.fetch(:customer).cart.reload.cart_items.any? }
  end

  test "concurrent requests with the same principal key create at most one order" do
    buyer = @buyers.first
    ready = Queue.new
    start = Queue.new

    threads = 2.times.map do
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          ready << true
          start.pop
          begin
            order = CheckoutService.new.call(
              customer: buyer.fetch(:customer),
              address_id: buyer.fetch(:address).id,
              idempotency_key: "same-concurrent-key",
              actor_principal_id: buyer.fetch(:user).id
            )
            [ :success, order.id ]
          rescue DomainError => error
            [ :domain_error, error.code ]
          end
        end
      end
    end

    2.times { ready.pop }
    2.times { start << true }
    results = threads.map(&:value)

    assert_equal 1, Order.where(customer: buyer.fetch(:customer)).count
    assert_equal 1, Payment.count
    assert_equal 1, InventoryMovement.count
    assert_equal 1, OutboxEvent.count
    assert_equal 0, results.count { |kind, code| kind == :domain_error && code != "idempotency_conflict" }
    assert_equal 1, results.filter_map { |kind, id| id if kind == :success }.uniq.size
    assert_equal 0, @inventory.reload.quantity
  end

  private

  def create_buyer(index)
    user = User.create!(email: "concurrent-#{index}@example.com", password: "password123", full_name: "Buyer #{index}")
    user.role_assignments.create!(role: "customer")
    customer = user.customer
    address = AddressService.create(customer: customer, params: {
      name: "Home", line1: "Rua #{index}", city: "São Paulo", state: "SP", zip: "01000-00#{index}", country: "BR"
    })
    CustomerCartService.add_item(customer: customer, product_id: @product.id, quantity: 1)
    { user: user, customer: customer, address: address }
  end

  def cleanup_checkout_tables
    [ OutboxEvent, InventoryMovement, Payment, OrderStatusHistory, OrderItem, IdempotencyRecord, Order,
      CartItem, Cart, Address, Favorite, InventoryItem, Product, Category, SellerSettings, SellerMembership,
      Seller, Customer, RoleAssignment, Session, User ].each(&:delete_all)
  end
end

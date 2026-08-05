require "test_helper"

class PublicDiscoveryTest < ActionDispatch::IntegrationTest
  setup do
    @approved_seller = Seller.create!(name: "Approved Store", moderation_state: "approved")
    @pending_seller = Seller.create!(name: "Pending Store", moderation_state: "pending_review")
    @suspended_seller = Seller.create!(name: "Suspended Store", moderation_state: "suspended")

    @cat1 = Category.create!(seller: @approved_seller, name: "Cat 1", position: 1)
    @cat2 = Category.create!(seller: @pending_seller, name: "Cat 2", position: 1)

    @active_prod = Product.create!(seller: @approved_seller, category: @cat1, name: "Beer", price_cents: 500, currency: "BRL", active: true)
    @inactive_prod = Product.create!(seller: @approved_seller, category: @cat1, name: "Soda", price_cents: 300, currency: "BRL", active: false)
    @pending_prod = Product.create!(seller: @pending_seller, category: @cat2, name: "Juice", price_cents: 400, currency: "BRL", active: true)

    InventoryItem.create!(seller: @approved_seller, product: @active_prod, quantity: 5)
    InventoryItem.create!(seller: @approved_seller, product: @inactive_prod, quantity: 10)
    InventoryItem.create!(seller: @pending_seller, product: @pending_prod, quantity: 10)

    @no_stock_prod = Product.create!(seller: @approved_seller, category: @cat1, name: "Water", price_cents: 200, currency: "BRL", active: true)
    InventoryItem.create!(seller: @approved_seller, product: @no_stock_prod, quantity: 0)
  end

  test "GET /api/v1/public/sellers lists only approved sellers" do
    get "/api/v1/public/sellers"
    assert_response :success
    data = JSON.parse(response.body).fetch("data")
    seller_ids = data.map { |s| s["id"] }
    assert_includes seller_ids, @approved_seller.id
    refute_includes seller_ids, @pending_seller.id
    refute_includes seller_ids, @suspended_seller.id
  end

  test "GET /api/v1/public/sellers/:id shows approved seller detail" do
    get "/api/v1/public/sellers/#{@approved_seller.id}"
    assert_response :success
    data = JSON.parse(response.body).fetch("data")
    assert_equal "Approved Store", data["name"]

    get "/api/v1/public/sellers/#{@pending_seller.id}"
    assert_response :not_found

    get "/api/v1/public/sellers/#{@suspended_seller.id}"
    assert_response :not_found
  end

  test "GET /api/v1/public/sellers/:seller_id/products lists active products with stock" do
    get "/api/v1/public/sellers/#{@approved_seller.id}/products"
    assert_response :success
    data = JSON.parse(response.body).fetch("data")
    assert_equal 1, data.size
    assert_equal @active_prod.id, data.first["id"]
    assert_equal 500, data.first["price_cents"]
    assert_equal 5, data.first["available_quantity"]
  end

  test "GET /api/v1/public/sellers/:seller_id/products for pending seller returns 404" do
    get "/api/v1/public/sellers/#{@pending_seller.id}/products"
    assert_response :not_found
  end

  test "public collections use deterministic bounded pagination" do
    30.times do |index|
      seller = Seller.create!(name: format("Approved %02d", index), moderation_state: "approved")
      category = Category.create!(seller: seller, name: "Category", position: 1)
      product = Product.create!(seller: seller, category: category, name: format("Product %02d", index), price_cents: 100, currency: "BRL", active: true)
      InventoryItem.create!(seller: seller, product: product, quantity: 1)
    end

    get "/api/v1/public/sellers?page=2&per_page=25"
    assert_response :success
    seller_data = JSON.parse(response.body)
    assert_equal 6, seller_data.fetch("data").size
    assert_equal 2, seller_data.dig("meta", "pagination", "page")
    assert_equal 25, seller_data.dig("meta", "pagination", "per_page")

    get "/api/v1/public/sellers/#{@approved_seller.id}/products?page=1&per_page=1"
    assert_response :success
    product_data = JSON.parse(response.body)
    assert_equal 1, product_data.fetch("data").size
    assert_equal 1, product_data.dig("meta", "pagination", "per_page")
  end

  test "GET /api/v1/public/products/:id returns product detail with stock" do
    get "/api/v1/public/products/#{@active_prod.id}"
    assert_response :success
    data = JSON.parse(response.body).fetch("data")
    assert_equal @active_prod.id, data["id"]

    get "/api/v1/public/products/#{@inactive_prod.id}"
    assert_response :not_found

    get "/api/v1/public/products/#{@no_stock_prod.id}"
    assert_response :not_found
  end
end

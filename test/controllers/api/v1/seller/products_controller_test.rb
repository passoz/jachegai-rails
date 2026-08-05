require "test_helper"

class Api::V1::Seller::ProductsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = User.create!(email: "prod-owner@example.com", password: "password123", full_name: "Dono")
    RoleAssignment.create!(user: @owner, role: "seller")
    @seller = Seller.create!(name: "Loja de Produtos", moderation_state: "approved")
    SellerMembership.create!(seller: @seller, user: @owner, role: "owner")
    @token = Session.issue_for(@owner)

    @other = User.create!(email: "prod-other@example.com", password: "password123", full_name: "Outro")
    RoleAssignment.create!(user: @other, role: "seller")
    @other_seller = Seller.create!(name: "Loja Alheia de Produtos", moderation_state: "approved")
    SellerMembership.create!(seller: @other_seller, user: @other, role: "owner")
    @other_token = Session.issue_for(@other)
  end

  def auth(token)
    { "Content-Type" => "application/json", "Authorization" => "Bearer #{token}" }
  end

  test "seller creates a product with integer minor-unit price" do
    post "/api/v1/seller/products",
         params: { name: "Café 250g", price_cents: 1990, currency: "BRL" }.to_json,
         headers: auth(@token)
    assert_response :created
    json = JSON.parse(response.body)
    assert_equal "Café 250g", json.dig("data", "name")
    assert_equal 1990, json.dig("data", "price_cents")
    assert_equal "BRL", json.dig("data", "currency")
    assert_equal true, json.dig("data", "active")
  end

  test "seller lists own products with bounded pagination" do
    30.times { |index| Product.create!(seller: @seller, name: "Product #{index}", price_cents: 1500, currency: "BRL") }

    get "/api/v1/seller/products", headers: auth(@token)
    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal 25, json.dig("data", "products").size
    assert_equal({ "count" => 25, "page" => 1, "per_page" => 25, "total" => 30, "total_pages" => 2 }, json["meta"])
  end

  test "seller updates own product" do
    product = Product.create!(seller: @seller, name: "Arroz", price_cents: 1500, currency: "BRL")
    patch "/api/v1/seller/products/#{product.id}",
          params: { price_cents: 1890, name: "Arroz Tipo 1" }.to_json,
          headers: auth(@token)
    assert_response :ok
    product.reload
    assert_equal 1890, product.price_cents
    assert_equal "Arroz Tipo 1", product.name
  end

  test "product with invalid field types, negative price or invalid currency is rejected" do
    post "/api/v1/seller/products",
         params: { name: "Ruim", price_cents: "100", currency: "BRL" }.to_json,
         headers: auth(@token)
    assert_response :unprocessable_content

    post "/api/v1/seller/products",
         params: { name: "Ruim", price_cents: -10, currency: "BRL" }.to_json,
         headers: auth(@token)
    assert_response :unprocessable_content
    json = JSON.parse(response.body)
    assert_equal "invalid_input", json.dig("error", "code")
    assert json.dig("error", "context", "fields", "price_cents").present?

    post "/api/v1/seller/products",
         params: { name: "Ruim", price_cents: 100, currency: "BRLX" }.to_json,
         headers: auth(@token)
    assert_response :unprocessable_content
  end

  test "product with category from another seller is rejected" do
    foreign_category = Category.create!(seller: @other_seller, name: "Alheia")
    post "/api/v1/seller/products",
         params: { name: "Conflito", price_cents: 100, currency: "BRL", category_id: foreign_category.id }.to_json,
         headers: auth(@token)
    assert_response :unprocessable_content
  end

  test "seller activates and deactivates own product" do
    product = Product.create!(seller: @seller, name: "Chá", price_cents: 700, currency: "BRL")
    post "/api/v1/seller/products/#{product.id}/deactivate", headers: auth(@token)
    assert_response :ok
    assert_not product.reload.active?

    post "/api/v1/seller/products/#{product.id}/activate", headers: auth(@token)
    assert_response :ok
    assert product.reload.active?
  end

  test "product with inventory cannot be hard-deleted" do
    product = Product.create!(seller: @seller, name: "Histórico", price_cents: 100, currency: "BRL")
    InventoryItem.create!(seller: @seller, product: product, quantity: 2)
    delete "/api/v1/seller/products/#{product.id}", headers: auth(@token)
    assert_response :conflict
    json = JSON.parse(response.body)
    assert_equal "product_in_use", json.dig("error", "code")
    assert Product.exists?(product.id)
  end

  test "another seller cannot read or mutate private product" do
    product = Product.create!(seller: @seller, name: "Privado", price_cents: 500, currency: "BRL")

    get "/api/v1/seller/products/#{product.id}", headers: auth(@other_token)
    assert_response :not_found

    patch "/api/v1/seller/products/#{product.id}",
          params: { name: "Invadido" }.to_json,
          headers: auth(@other_token)
    assert_response :not_found

    delete "/api/v1/seller/products/#{product.id}", headers: auth(@other_token)
    assert_response :not_found
    assert Product.exists?(product.id)
  end

  test "suspended seller cannot create products" do
    @seller.update!(moderation_state: "suspended")
    post "/api/v1/seller/products",
         params: { name: "Blocked", price_cents: 100, currency: "BRL" }.to_json,
         headers: auth(@token)
    assert_response :forbidden
  end

  test "products require authentication" do
    get "/api/v1/seller/products", headers: { "Content-Type" => "application/json" }
    assert_response :unauthorized
  end
end

require "test_helper"

class Api::V1::Seller::InventoryControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = User.create!(email: "inv-owner@example.com", password: "password123", full_name: "Dono")
    RoleAssignment.create!(user: @owner, role: "seller")
    @seller = Seller.create!(name: "Loja de Estoque", moderation_state: "approved")
    SellerMembership.create!(seller: @seller, user: @owner, role: "owner")
    @product = Product.create!(seller: @seller, name: "Arroz 5kg", price_cents: 2490, currency: "BRL")
    @token = Session.issue_for(@owner)

    @other = User.create!(email: "inv-other@example.com", password: "password123", full_name: "Outro")
    RoleAssignment.create!(user: @other, role: "seller")
    @other_seller = Seller.create!(name: "Loja Alheia", moderation_state: "approved")
    SellerMembership.create!(seller: @other_seller, user: @other, role: "owner")
    @other_token = Session.issue_for(@other)
  end

  def auth(token)
    { "Content-Type" => "application/json", "Authorization" => "Bearer #{token}" }
  end

  test "seller reads inventory with product details and bounded pagination" do
    InventoryItem.create!(seller: @seller, product: @product, quantity: 10)
    29.times do |index|
      product = Product.create!(seller: @seller, name: "Product #{index}", price_cents: 100, currency: "BRL")
      InventoryItem.create!(seller: @seller, product: product, quantity: index)
    end

    get "/api/v1/seller/inventory", headers: auth(@token)
    assert_response :ok
    json = JSON.parse(response.body)
    items = json.dig("data", "inventory")
    assert_equal 25, items.size
    assert_equal({ "count" => 25, "page" => 1, "per_page" => 25, "total" => 30, "total_pages" => 2 }, json["meta"])
  end

  test "seller updates inventory quantity" do
    InventoryItem.create!(seller: @seller, product: @product, quantity: 5)
    patch "/api/v1/seller/inventory/#{@product.id}",
          params: { quantity: 20 }.to_json,
          headers: auth(@token)
    assert_response :ok
    assert_equal 20, @seller.inventory_items.first.quantity
  end

  test "negative inventory is rejected at model and DB level" do
    InventoryItem.create!(seller: @seller, product: @product, quantity: 5)
    patch "/api/v1/seller/inventory/#{@product.id}",
          params: { quantity: -3 }.to_json,
          headers: auth(@token)
    assert_response :unprocessable_content
    json = JSON.parse(response.body)
    assert_equal "invalid_input", json.dig("error", "code")
  end

  test "inventory rejects missing and non-integer quantities without changing inventory" do
    item = InventoryItem.create!(seller: @seller, product: @product, quantity: 5)

    [ {}, { quantity: nil }, { quantity: "abc" }, { quantity: true }, { quantity: 1.5 } ].each do |payload|
      patch "/api/v1/seller/inventory/#{@product.id}", params: payload.to_json, headers: auth(@token)
      assert_response :unprocessable_content, "expected #{payload.inspect} to be rejected"
      assert_equal "invalid_input", JSON.parse(response.body).dig("error", "code")
      assert_equal 5, item.reload.quantity
    end
  end

  test "inventory for a product belonging to another seller returns not found" do
    other_product = Product.create!(seller: @other_seller, name: "Feijão", price_cents: 890, currency: "BRL")
    patch "/api/v1/seller/inventory/#{other_product.id}",
          params: { quantity: 10 }.to_json,
          headers: auth(@token)
    assert_response :not_found
  end

  test "suspended seller cannot update inventory" do
    @seller.update!(moderation_state: "suspended")
    patch "/api/v1/seller/inventory/#{@product.id}",
          params: { quantity: 10 }.to_json,
          headers: auth(@token)
    assert_response :forbidden
  end

  test "inventory requires authentication" do
    get "/api/v1/seller/inventory", headers: { "Content-Type" => "application/json" }
    assert_response :unauthorized
  end
end

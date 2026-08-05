require "test_helper"

class Api::V1::Seller::CategoriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = User.create!(email: "cat-owner@example.com", password: "password123", full_name: "Dono")
    RoleAssignment.create!(user: @owner, role: "seller")
    @seller = Seller.create!(name: "Loja de Categorias", moderation_state: "approved")
    SellerMembership.create!(seller: @seller, user: @owner, role: "owner")
    @token = Session.issue_for(@owner)

    @other = User.create!(email: "cat-other@example.com", password: "password123", full_name: "Outro")
    RoleAssignment.create!(user: @other, role: "seller")
    @other_seller = Seller.create!(name: "Loja Alheia", moderation_state: "approved")
    SellerMembership.create!(seller: @other_seller, user: @other, role: "owner")
    @other_token = Session.issue_for(@other)
  end

  def auth(token)
    { "Content-Type" => "application/json", "Authorization" => "Bearer #{token}" }
  end

  test "seller lists own categories in deterministic bounded pages" do
    categories = 30.times.map { |index| Category.create!(seller: @seller, name: "Category #{index}", position: index) }

    get "/api/v1/seller/categories", headers: auth(@token)
    assert_response :ok
    json = JSON.parse(response.body)
    ids = json.dig("data", "categories").map { |category| category["id"] }
    assert_equal categories.first(25).map(&:id), ids
    assert_equal({ "count" => 25, "page" => 1, "per_page" => 25, "total" => 30, "total_pages" => 2 }, json["meta"])

    get "/api/v1/seller/categories", params: { page: 2, per_page: 10 }, headers: auth(@token)
    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal categories.drop(10).first(10).map(&:id), json.dig("data", "categories").map { |category| category["id"] }
  end

  test "seller creates a category" do
    post "/api/v1/seller/categories", params: { name: "Bebidas" }.to_json, headers: auth(@token)
    assert_response :created
    json = JSON.parse(response.body)
    assert_equal "Bebidas", json.dig("data", "name")
    assert_equal @seller.id, json.dig("data", "seller_id")
  end

  test "category mutations return validation errors for missing or invalid values" do
    post "/api/v1/seller/categories", params: {}.to_json, headers: auth(@token)
    assert_response :unprocessable_content
    assert_equal "invalid_input", JSON.parse(response.body).dig("error", "code")

    post "/api/v1/seller/categories",
         params: { name: "Bebidas", position: "abc" }.to_json,
         headers: auth(@token)
    assert_response :unprocessable_content
    assert_equal "invalid_input", JSON.parse(response.body).dig("error", "code")

    post "/api/v1/seller/categories",
         params: { name: true, position: 0 }.to_json,
         headers: auth(@token)
    assert_response :unprocessable_content
  end

  test "seller updates own category name and position" do
    category = Category.create!(seller: @seller, name: "Bebidas")
    patch "/api/v1/seller/categories/#{category.id}",
          params: { name: "Sucos", position: 3 }.to_json,
          headers: auth(@token)
    assert_response :ok
    category.reload
    assert_equal "Sucos", category.name
    assert_equal 3, category.position
  end

  test "seller reorders own categories" do
    a = Category.create!(seller: @seller, name: "A", position: 0)
    b = Category.create!(seller: @seller, name: "B", position: 1)

    put "/api/v1/seller/categories/order",
        params: { ordered_ids: [ b.id, a.id ] }.to_json,
        headers: auth(@token)
    assert_response :ok
    assert_equal [ b.id, a.id ], @seller.categories.ordered.pluck(:id)
  end

  test "seller removes an unused category" do
    category = Category.create!(seller: @seller, name: "Sem Uso")
    delete "/api/v1/seller/categories/#{category.id}", headers: auth(@token)
    assert_response :ok
    assert_not Category.exists?(category.id)
  end

  test "delete with referenced products returns conflict" do
    category = Category.create!(seller: @seller, name: "Em Uso")
    Product.create!(seller: @seller, category: category, name: "Produto", price_cents: 100, currency: "BRL")
    delete "/api/v1/seller/categories/#{category.id}", headers: auth(@token)
    assert_response :conflict
    json = JSON.parse(response.body)
    assert_equal "category_in_use", json.dig("error", "code")
  end

  test "another seller cannot read or mutate private category" do
    category = Category.create!(seller: @seller, name: "Privada")

    get "/api/v1/seller/categories/#{category.id}", headers: auth(@other_token)
    assert_response :not_found

    patch "/api/v1/seller/categories/#{category.id}",
          params: { name: "Invadida" }.to_json,
          headers: auth(@other_token)
    assert_response :not_found

    delete "/api/v1/seller/categories/#{category.id}", headers: auth(@other_token)
    assert_response :not_found
    assert Category.exists?(category.id)
  end

  test "suspended seller can read but cannot mutate catalog" do
    @seller.update!(moderation_state: "suspended")
    get "/api/v1/seller/categories", headers: auth(@token)
    assert_response :ok

    post "/api/v1/seller/categories", params: { name: "Blocked" }.to_json, headers: auth(@token)
    assert_response :forbidden
  end

  test "categories require authentication" do
    get "/api/v1/seller/categories", headers: { "Content-Type" => "application/json" }
    assert_response :unauthorized
  end
end

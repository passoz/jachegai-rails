require "test_helper"

class Api::V1::Seller::ProfileControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = User.create!(email: "profile@example.com", password: "password123", full_name: "Dono")
    RoleAssignment.create!(user: @owner, role: "seller")
    @seller = Seller.create!(name: "Perfil da Loja")
    SellerMembership.create!(seller: @seller, user: @owner, role: "owner")
    SellerSettings.create!(seller: @seller)
    @token = Session.issue_for(@owner)

    @other = User.create!(email: "profile-other@example.com", password: "password123", full_name: "Outro")
    RoleAssignment.create!(user: @other, role: "seller")
    @other_seller = Seller.create!(name: "Outra Loja")
    SellerMembership.create!(seller: @other_seller, user: @other, role: "owner")
    @other_token = Session.issue_for(@other)

    @customer = User.create!(email: "profile-client@example.com", password: "password123", full_name: "Cliente")
    RoleAssignment.create!(user: @customer, role: "customer")
    @customer_token = Session.issue_for(@customer)
  end

  def auth(token)
    { "Content-Type" => "application/json", "Authorization" => "Bearer #{token}" }
  end

  test "seller reads own profile" do
    get "/api/v1/seller/profile", headers: auth(@token)
    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal @seller.id, json.dig("data", "id")
    assert_equal "Perfil da Loja", json.dig("data", "name")
  end

  test "seller updates own profile" do
    patch "/api/v1/seller/profile",
          params: { description: "Loja renovada", contact_email: "novo@example.com" }.to_json,
          headers: auth(@token)
    assert_response :ok
    @seller.reload
    assert_equal "Loja renovada", @seller.description
    assert_equal "novo@example.com", @seller.contact_email
  end

  test "profile update rejects invalid data" do
    patch "/api/v1/seller/profile",
          params: { contact_email: "invalido" }.to_json,
          headers: auth(@token)
    assert_response :unprocessable_content
    json = JSON.parse(response.body)
    assert_equal "invalid_input", json.dig("error", "code")
  end

  test "seller without a seller profile receives not found" do
    user = User.create!(email: "sem-loja@example.com", password: "password123", full_name: "Sem Loja")
    RoleAssignment.create!(user: user, role: "seller")
    token = Session.issue_for(user)
    get "/api/v1/seller/profile", headers: auth(token)
    assert_response :not_found
  end

  test "a different seller cannot read another seller's profile (scoped to own membership)" do
    # The other seller reads its own (empty) profile — it must never see the first seller's data.
    get "/api/v1/seller/profile", headers: auth(@other_token)
    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal @other_seller.id, json.dig("data", "id")
    assert_not_equal @seller.id, json.dig("data", "id")
  end

  test "customer role is forbidden from seller profile" do
    get "/api/v1/seller/profile", headers: auth(@customer_token)
    assert_response :not_found
  end

  test "profile requires authentication" do
    get "/api/v1/seller/profile", headers: { "Content-Type" => "application/json" }
    assert_response :unauthorized
  end
end

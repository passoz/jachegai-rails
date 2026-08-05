require "test_helper"

module Api
  module V1
    module Customer
      class FavoritesControllerTest < ActionDispatch::IntegrationTest
        setup do
          @customer1 = User.create!(email: "customer1@example.com", password: "password123", full_name: "Customer One")
          @customer1.role_assignments.create!(role: "customer")

          @customer2 = User.create!(email: "customer2@example.com", password: "password123", full_name: "Customer Two")
          @customer2.role_assignments.create!(role: "customer")

          @session_token1 = Session.issue_for(@customer1)
          @session_token2 = Session.issue_for(@customer2)

          @seller1 = ::Seller.create!(name: "Store 1", moderation_state: "approved")
          @seller2 = ::Seller.create!(name: "Store 2", moderation_state: "approved")
          @pending_seller = ::Seller.create!(name: "Pending Store", moderation_state: "pending_review")

          @fav1 = Favorite.create!(customer: @customer1.customer, seller: @seller1)
          @fav2 = Favorite.create!(customer: @customer2.customer, seller: @seller2)
        end

        test "GET /api/v1/customer/favorites lists only customer's own favorites" do
          get "/api/v1/customer/favorites", headers: { "Authorization" => "Bearer #{@session_token1}" }
          assert_response :success
          json = JSON.parse(response.body)
          data = json.dig("data", "favorites")
          assert_equal 1, data.size
          assert_equal @seller1.id, data.first["id"]
          assert_equal({ "count" => 1, "page" => 1, "per_page" => 25, "total" => 1, "total_pages" => 1 }, json["meta"])
        end

        test "GET /api/v1/customer/favorites uses deterministic bounded pagination" do
          sellers = 30.times.map do |index|
            seller = ::Seller.create!(name: format("Favorite %02d", index), moderation_state: "approved")
            Favorite.create!(customer: @customer1.customer, seller: seller)
            seller
          end

          get "/api/v1/customer/favorites", params: { page: 2, per_page: 10 }, headers: { "Authorization" => "Bearer #{@session_token1}" }

          assert_response :success
          json = JSON.parse(response.body)
          expected_ids = sellers.sort_by { |seller| [ seller.name, seller.id ] }.map(&:id).slice(10, 10)
          assert_equal expected_ids, json.dig("data", "favorites").map { |seller| seller["id"] }
          assert_equal({ "count" => 10, "page" => 2, "per_page" => 10, "total" => 31, "total_pages" => 4 }, json["meta"])
        end

        test "POST /api/v1/customer/favorites adds favorite store" do
          post "/api/v1/customer/favorites",
               params: { seller_id: @seller2.id }.to_json,
               headers: { "Authorization" => "Bearer #{@session_token1}", "Content-Type" => "application/json" }
          assert_response :created
          assert Favorite.exists?(customer_id: @customer1.customer.id, seller_id: @seller2.id)
        end

        test "POST /api/v1/customer/favorites is idempotent for a duplicate seller" do
          post "/api/v1/customer/favorites",
               params: { seller_id: @seller1.id }.to_json,
               headers: { "Authorization" => "Bearer #{@session_token1}", "Content-Type" => "application/json" }

          assert_response :created
          assert_equal 1, Favorite.where(customer: @customer1.customer, seller: @seller1).count
        end

        test "POST /api/v1/customer/favorites with non-approved seller fails" do
          post "/api/v1/customer/favorites",
               params: { seller_id: @pending_seller.id }.to_json,
               headers: { "Authorization" => "Bearer #{@session_token1}", "Content-Type" => "application/json" }
          assert_response :unprocessable_content
        end

        test "DELETE /api/v1/customer/favorites/:seller_id removes favorite store" do
          delete "/api/v1/customer/favorites/#{@seller1.id}", headers: { "Authorization" => "Bearer #{@session_token1}" }
          assert_response :success
          refute Favorite.exists?(id: @fav1.id)
        end

        test "customer cannot remove another customer's favorite" do
          delete "/api/v1/customer/favorites/#{@seller2.id}", headers: { "Authorization" => "Bearer #{@session_token1}" }
          assert_response :not_found
          assert Favorite.exists?(id: @fav2.id)
        end
      end
    end
  end
end

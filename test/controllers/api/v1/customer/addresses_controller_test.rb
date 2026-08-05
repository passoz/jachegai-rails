require "test_helper"

module Api
  module V1
    module Customer
      class AddressesControllerTest < ActionDispatch::IntegrationTest
        setup do
          @customer1 = User.create!(email: "customer1@example.com", password: "password123", full_name: "Customer One")
          @customer1.role_assignments.create!(role: "customer")

          @customer2 = User.create!(email: "customer2@example.com", password: "password123", full_name: "Customer Two")
          @customer2.role_assignments.create!(role: "customer")

          @session_token1 = Session.issue_for(@customer1)
          @session_token2 = Session.issue_for(@customer2)

          @addr1 = Address.create!(customer: @customer1.customer, name: "Home", line1: "Rua 1", city: "SP", state: "SP", zip: "01000-000", is_default: true)
          @addr2 = Address.create!(customer: @customer2.customer, name: "Work", line1: "Rua 2", city: "SP", state: "SP", zip: "02000-000", is_default: true)
        end

        test "GET /api/v1/customer/addresses lists only customer's own addresses" do
          get "/api/v1/customer/addresses", headers: { "Authorization" => "Bearer #{@session_token1}" }
          assert_response :success
          json = JSON.parse(response.body)
          data = json.dig("data", "addresses")
          assert_equal 1, data.size
          assert_equal @addr1.id, data.first["id"]
          assert_equal({ "count" => 1, "page" => 1, "per_page" => 25, "total" => 1, "total_pages" => 1 }, json["meta"])
        end

        test "GET /api/v1/customer/addresses uses deterministic bounded pagination" do
          created = 30.times.map do |index|
            Address.create!(
              customer: @customer1.customer,
              name: format("Address %02d", index),
              line1: "Rua #{index}",
              city: "São Paulo",
              state: "SP",
              zip: format("%05d-000", index),
              created_at: Time.zone.parse("2026-01-01 00:00:00") + index.seconds
            )
          end

          get "/api/v1/customer/addresses", params: { page: 2, per_page: 10 }, headers: { "Authorization" => "Bearer #{@session_token1}" }

          assert_response :success
          json = JSON.parse(response.body)
          expected_ids = [ @addr1.id ] + created.reverse.map(&:id)
          assert_equal expected_ids.slice(10, 10), json.dig("data", "addresses").map { |address| address["id"] }
          assert_equal({ "count" => 10, "page" => 2, "per_page" => 10, "total" => 31, "total_pages" => 4 }, json["meta"])
        end

        test "POST /api/v1/customer/addresses creates address and marks as default if it is the first one" do
          @customer1.customer.addresses.destroy_all

          post "/api/v1/customer/addresses",
               params: { name: "Office", line1: "Avenida Paulista", city: "São Paulo", state: "SP", zip: "01311-000", country: "BR" }.to_json,
               headers: { "Authorization" => "Bearer #{@session_token1}", "Content-Type" => "application/json" }
          assert_response :created
          data = JSON.parse(response.body).fetch("data")
          assert data["is_default"]

          addr = @customer1.customer.addresses.find(data["id"])
          assert addr.is_default?
        end

        test "POST /api/v1/customer/addresses does not mark as default if user already has one, unless requested" do
          post "/api/v1/customer/addresses",
               params: { name: "Office", line1: "Avenida Paulista", city: "São Paulo", state: "SP", zip: "01311-000", country: "BR", is_default: false }.to_json,
               headers: { "Authorization" => "Bearer #{@session_token1}", "Content-Type" => "application/json" }
          assert_response :created
          data = JSON.parse(response.body).fetch("data")
          refute data["is_default"]

          # Now make it default explicitly
          post "/api/v1/customer/addresses/#{data["id"]}/default", headers: { "Authorization" => "Bearer #{@session_token1}" }
          assert_response :success
          assert @customer1.customer.addresses.find(data["id"]).is_default?
          refute @addr1.reload.is_default?
        end

        test "PATCH cannot leave existing addresses without a deterministic default" do
          patch "/api/v1/customer/addresses/#{@addr1.id}",
                params: { is_default: false }.to_json,
                headers: { "Authorization" => "Bearer #{@session_token1}", "Content-Type" => "application/json" }

          assert_response :success
          assert @addr1.reload.is_default?
          assert_equal 1, @customer1.customer.addresses.where(is_default: true).count
        end

        test "PATCH /api/v1/customer/addresses/:id updates address" do
          patch "/api/v1/customer/addresses/#{@addr1.id}",
                params: { name: "Updated Home", line1: "Rua Nova" }.to_json,
                headers: { "Authorization" => "Bearer #{@session_token1}", "Content-Type" => "application/json" }
          assert_response :success
          data = JSON.parse(response.body).fetch("data")
          assert_equal "Updated Home", data["name"]
          assert_equal "Rua Nova", data["line1"]
        end

        test "DELETE /api/v1/customer/addresses/:id removes address" do
          delete "/api/v1/customer/addresses/#{@addr1.id}", headers: { "Authorization" => "Bearer #{@session_token1}" }
          assert_response :success
          refute Address.exists?(@addr1.id)
        end

        test "deleting the default address deterministically promotes the newest remaining address" do
          older = Address.create!(
            customer: @customer1.customer,
            name: "Older",
            line1: "Rua Antiga",
            city: "São Paulo",
            state: "SP",
            zip: "03000-000",
            is_default: false,
            created_at: 2.days.ago
          )
          newest = Address.create!(
            customer: @customer1.customer,
            name: "Newest",
            line1: "Rua Nova",
            city: "São Paulo",
            state: "SP",
            zip: "04000-000",
            is_default: false,
            created_at: 1.day.ago
          )

          delete "/api/v1/customer/addresses/#{@addr1.id}", headers: { "Authorization" => "Bearer #{@session_token1}" }

          assert_response :success
          refute Address.exists?(@addr1.id)
          assert newest.reload.is_default?
          refute older.reload.is_default?
          assert_equal 1, @customer1.customer.addresses.where(is_default: true).count
        end

        test "customer cannot access, modify, or delete another customer's address" do
          get "/api/v1/customer/addresses/#{@addr2.id}", headers: { "Authorization" => "Bearer #{@session_token1}" }
          assert_response :not_found

          patch "/api/v1/customer/addresses/#{@addr2.id}",
                params: { name: "Hack" }.to_json,
                headers: { "Authorization" => "Bearer #{@session_token1}", "Content-Type" => "application/json" }
          assert_response :not_found

          delete "/api/v1/customer/addresses/#{@addr2.id}", headers: { "Authorization" => "Bearer #{@session_token1}" }
          assert_response :not_found
        end
      end
    end
  end
end

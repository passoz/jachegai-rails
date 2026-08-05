require "test_helper"

module Api
  module V1
    module Customer
      class ProfileControllerTest < ActionDispatch::IntegrationTest
        setup do
          @customer = User.create!(email: "customer@example.com", password: "password123", full_name: "Customer User")
          @customer.role_assignments.create!(role: "customer")

          @other_user = User.create!(email: "other@example.com", password: "password123", full_name: "Other User")
          @other_user.role_assignments.create!(role: "customer")

          @session_token = Session.issue_for(@customer)
        end

        test "GET /api/v1/customer/profile returns customer profile" do
          get "/api/v1/customer/profile", headers: { "Authorization" => "Bearer #{@session_token}" }
          assert_response :success
          data = JSON.parse(response.body).fetch("data")
          assert_equal @customer.customer.id, data["id"]
          assert_equal @customer.id, data["user_id"]
          refute_equal data["user_id"], data["id"]
          assert_equal "customer@example.com", data["email"]
          assert_equal "Customer User", data["full_name"]
          assert_nil data["phone"]
        end

        test "PATCH /api/v1/customer/profile updates profile" do
          patch "/api/v1/customer/profile",
                params: { full_name: "New Name", email: "new_email@example.com", phone: "+55 11 99999-0000" }.to_json,
                headers: { "Authorization" => "Bearer #{@session_token}", "Content-Type" => "application/json" }
          assert_response :success
          data = JSON.parse(response.body).fetch("data")
          assert_equal "New Name", data["full_name"]
          assert_equal "new_email@example.com", data["email"]
          assert_equal "+55 11 99999-0000", data["phone"]

          @customer.reload
          assert_equal "New Name", @customer.full_name
          assert_equal "new_email@example.com", @customer.email
          assert_equal "New Name", @customer.customer.full_name
          assert_equal "+55 11 99999-0000", @customer.customer.phone
        end

        test "profile update rolls back buyer profile when identity email is invalid" do
          existing = User.create!(email: "taken@example.com", password: "password123", full_name: "Taken")
          existing.role_assignments.create!(role: "customer")

          patch "/api/v1/customer/profile",
                params: { full_name: "Must Roll Back", email: "taken@example.com", phone: "+55 11 90000-0000" }.to_json,
                headers: { "Authorization" => "Bearer #{@session_token}", "Content-Type" => "application/json" }

          assert_response :unprocessable_content
          assert_equal "invalid_input", JSON.parse(response.body).dig("error", "code")
          assert_equal "Customer User", @customer.reload.full_name
          assert_equal "Customer User", @customer.customer.reload.full_name
          assert_nil @customer.customer.phone
        end

        test "authenticated principal without customer role cannot access profile" do
          non_customer = User.create!(email: "seller-only@example.com", password: "password123", full_name: "Seller Only")
          non_customer.role_assignments.create!(role: "seller")
          token = Session.issue_for(non_customer)

          get "/api/v1/customer/profile", headers: { "Authorization" => "Bearer #{token}" }

          assert_response :forbidden
          assert_equal "forbidden", JSON.parse(response.body).dig("error", "code")
        end

        test "unauthenticated request to profile fails with 401" do
          get "/api/v1/customer/profile"
          assert_response :unauthorized
        end

        test "request to profile rejects unknown fields" do
          patch "/api/v1/customer/profile",
                params: { full_name: "Name", email: "email@example.com", active: false }.to_json,
                headers: { "Authorization" => "Bearer #{@session_token}", "Content-Type" => "application/json" }
          assert_response :unprocessable_content
          assert_equal "unknown_fields", JSON.parse(response.body).dig("error", "code")
        end
      end
    end
  end
end

require "test_helper"

module Api
  module V1
    module Customer
      class CartHandoffTest < ActionDispatch::IntegrationTest
        setup do
          @customer = User.create!(email: "customer@example.com", password: "password123", full_name: "Customer User")
          @customer.role_assignments.create!(role: "customer")
          @session_token = Session.issue_for(@customer)

          @seller1 = ::Seller.create!(name: "Seller 1", moderation_state: "approved")
          @seller2 = ::Seller.create!(name: "Seller 2", moderation_state: "approved")

          @cat1 = Category.create!(seller: @seller1, name: "Cat 1", position: 1)
          @cat2 = Category.create!(seller: @seller2, name: "Cat 2", position: 1)

          @prod1 = Product.create!(seller: @seller1, category: @cat1, name: "Beer", price_cents: 500, currency: "BRL", active: true)
          @prod2 = Product.create!(seller: @seller2, category: @cat2, name: "Wine", price_cents: 2000, currency: "BRL", active: true)

          InventoryItem.create!(seller: @seller1, product: @prod1, quantity: 10)
          InventoryItem.create!(seller: @seller2, product: @prod2, quantity: 10)
        end

        test "handoff merges items when cart sellers match" do
          # Create guest cart with prod1
          guest_token, guest_digest = GuestCart.generate_token
          g_cart = GuestCart.create!(token_digest: guest_digest, seller: @seller1)
          g_cart.guest_cart_items.create!(product: @prod1, seller: @seller1, quantity: 2)

          # Create customer cart with prod1
          c_cart = Cart.create!(customer: @customer.customer, seller: @seller1)
          c_cart.cart_items.create!(product: @prod1, seller: @seller1, quantity: 3)

          post "/api/v1/customer/cart/handoff",
               params: { guest_token: guest_token }.to_json,
               headers: { "Authorization" => "Bearer #{@session_token}", "Content-Type" => "application/json" }

          assert_response :success
          data = JSON.parse(response.body).fetch("data")
          assert_equal 1, data["items"].size
          assert_equal @prod1.id, data["items"].first["product_id"]
          assert_equal 5, data["items"].first["quantity"] # Merged quantity (2 + 3)

          refute GuestCart.exists?(g_cart.id)
        end

        test "handoff rejects non-boolean replace_confirmed without consuming the guest cart" do
          guest_token, guest_digest = GuestCart.generate_token
          guest_cart = GuestCart.create!(token_digest: guest_digest, seller: @seller1)
          guest_cart.guest_cart_items.create!(product: @prod1, seller: @seller1, quantity: 1)

          post "/api/v1/customer/cart/handoff",
               params: { guest_token: guest_token, replace_confirmed: "true" }.to_json,
               headers: { "Authorization" => "Bearer #{@session_token}", "Content-Type" => "application/json" }

          assert_response :unprocessable_content
          assert_equal "invalid_input", JSON.parse(response.body).dig("error", "code")
          assert GuestCart.exists?(guest_cart.id)
          refute Cart.exists?(customer: @customer.customer)
        end

        test "handoff returns seller_conflict when cart sellers differ" do
          guest_token, guest_digest = GuestCart.generate_token
          g_cart = GuestCart.create!(token_digest: guest_digest, seller: @seller2)
          g_cart.guest_cart_items.create!(product: @prod2, seller: @seller2, quantity: 1)

          c_cart = Cart.create!(customer: @customer.customer, seller: @seller1)
          c_cart.cart_items.create!(product: @prod1, seller: @seller1, quantity: 1)

          post "/api/v1/customer/cart/handoff",
               params: { guest_token: guest_token }.to_json,
               headers: { "Authorization" => "Bearer #{@session_token}", "Content-Type" => "application/json" }

          assert_response :conflict
          body = JSON.parse(response.body)
          assert_equal "seller_conflict", body.dig("error", "code")

          # Both carts preserved
          assert GuestCart.exists?(g_cart.id)
          assert_equal 1, c_cart.reload.cart_items.count
        end

        test "handoff retry is idempotent after the guest cart was consumed" do
          guest_token, guest_digest = GuestCart.generate_token
          guest_cart = GuestCart.create!(token_digest: guest_digest, seller: @seller1)
          guest_cart.guest_cart_items.create!(product: @prod1, seller: @seller1, quantity: 2)

          2.times do
            post "/api/v1/customer/cart/handoff",
                 params: { guest_token: guest_token }.to_json,
                 headers: { "Authorization" => "Bearer #{@session_token}", "Content-Type" => "application/json" }

            assert_response :success
          end

          cart = @customer.reload.customer.cart
          assert_equal 1, cart.cart_items.count
          assert_equal 2, cart.cart_items.find_by!(product: @prod1).quantity
          refute GuestCart.exists?(guest_cart.id)
        end

        test "failed handoff does not persist an empty customer cart" do
          guest_token, guest_digest = GuestCart.generate_token
          guest_cart = GuestCart.create!(token_digest: guest_digest, seller: @seller1)
          guest_cart.guest_cart_items.create!(product: @prod1, seller: @seller1, quantity: 2)
          @prod1.inventory_item.update!(quantity: 0)

          post "/api/v1/customer/cart/handoff",
               params: { guest_token: guest_token }.to_json,
               headers: { "Authorization" => "Bearer #{@session_token}", "Content-Type" => "application/json" }

          assert_response :unprocessable_content
          assert_equal "invalid_input", JSON.parse(response.body).dig("error", "code")
          refute Cart.exists?(customer: @customer.customer)
          assert GuestCart.exists?(guest_cart.id)
        end

        test "handoff rejects a merged quantity above current stock without changing either cart" do
          guest_token, guest_digest = GuestCart.generate_token
          guest_cart = GuestCart.create!(token_digest: guest_digest, seller: @seller1)
          guest_item = guest_cart.guest_cart_items.create!(product: @prod1, seller: @seller1, quantity: 6)

          customer_cart = Cart.create!(customer: @customer.customer, seller: @seller1)
          customer_item = customer_cart.cart_items.create!(product: @prod1, seller: @seller1, quantity: 5)

          post "/api/v1/customer/cart/handoff",
               params: { guest_token: guest_token }.to_json,
               headers: { "Authorization" => "Bearer #{@session_token}", "Content-Type" => "application/json" }

          assert_response :unprocessable_content
          assert_equal "invalid_input", JSON.parse(response.body).dig("error", "code")
          assert_equal 5, customer_item.reload.quantity
          assert_equal 6, guest_item.reload.quantity
          assert GuestCart.exists?(guest_cart.id)
        end

        test "failed confirmed handoff preserves both carts when guest seller became ineligible" do
          guest_token, guest_digest = GuestCart.generate_token
          guest_cart = GuestCart.create!(token_digest: guest_digest, seller: @seller2)
          guest_cart.guest_cart_items.create!(product: @prod2, seller: @seller2, quantity: 2)

          customer_cart = Cart.create!(customer: @customer.customer, seller: @seller1)
          customer_item = customer_cart.cart_items.create!(product: @prod1, seller: @seller1, quantity: 1)
          @seller2.update!(moderation_state: "suspended")

          post "/api/v1/customer/cart/handoff",
               params: { guest_token: guest_token, replace_confirmed: true }.to_json,
               headers: { "Authorization" => "Bearer #{@session_token}", "Content-Type" => "application/json" }

          assert_response :unprocessable_content
          assert_equal "invalid_input", JSON.parse(response.body).dig("error", "code")
          assert_equal @seller1.id, customer_cart.reload.seller_id
          assert_equal [ customer_item.id ], customer_cart.cart_items.pluck(:id)
          assert GuestCart.exists?(guest_cart.id)
        end

        test "handoff replaces customer cart when replace_confirmed is true" do
          guest_token, guest_digest = GuestCart.generate_token
          g_cart = GuestCart.create!(token_digest: guest_digest, seller: @seller2)
          g_cart.guest_cart_items.create!(product: @prod2, seller: @seller2, quantity: 2)

          c_cart = Cart.create!(customer: @customer.customer, seller: @seller1)
          c_cart.cart_items.create!(product: @prod1, seller: @seller1, quantity: 1)

          post "/api/v1/customer/cart/handoff",
               params: { guest_token: guest_token, replace_confirmed: true }.to_json,
               headers: { "Authorization" => "Bearer #{@session_token}", "Content-Type" => "application/json" }

          assert_response :success
          data = JSON.parse(response.body).fetch("data")
          assert_equal 1, data["items"].size
          assert_equal @prod2.id, data["items"].first["product_id"]
          assert_equal 2, data["items"].first["quantity"]

          refute GuestCart.exists?(g_cart.id)
          assert_equal @seller2.id, c_cart.reload.seller_id
        end
      end
    end
  end
end

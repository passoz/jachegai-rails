require "test_helper"

module Api
  module V1
    module Customer
      class CartsControllerTest < ActionDispatch::IntegrationTest
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
          @inactive_prod = Product.create!(seller: @seller1, category: @cat1, name: "Soda", price_cents: 300, currency: "BRL", active: false)
          @no_stock_prod = Product.create!(seller: @seller1, category: @cat1, name: "Water", price_cents: 200, currency: "BRL", active: true)

          InventoryItem.create!(seller: @seller1, product: @prod1, quantity: 10)
          InventoryItem.create!(seller: @seller2, product: @prod2, quantity: 10)
          InventoryItem.create!(seller: @seller1, product: @inactive_prod, quantity: 10)
          InventoryItem.create!(seller: @seller1, product: @no_stock_prod, quantity: 0)
        end

        test "GET /api/v1/customer/cart returns empty cart when none exists" do
          get "/api/v1/customer/cart", headers: { "Authorization" => "Bearer #{@session_token}" }
          assert_response :success
          data = JSON.parse(response.body).fetch("data")
          assert_nil data["cart_id"]
          assert_equal [], data["items"]
          assert_equal 0, data["subtotal_cents"]
          assert_equal 0, data["delivery_fee_cents"]
          assert_equal 0, data["total_cents"]
        end

        test "POST /api/v1/customer/cart/items creates cart and adds item" do
          assert_difference "Cart.count", 1 do
            post "/api/v1/customer/cart/items",
                 params: { product_id: @prod1.id, quantity: 2 }.to_json,
                 headers: { "Authorization" => "Bearer #{@session_token}", "Content-Type" => "application/json" }
            assert_response :created
            data = JSON.parse(response.body).fetch("data")
            assert_equal 1, data["items"].size
            assert_equal @prod1.id, data["items"].first["product_id"]
            assert_equal 2, data["items"].first["quantity"]
            assert_equal 500, data["items"].first["unit_price_cents"]
            assert_equal "BRL", data["items"].first["currency"]
            assert_equal 1000, data["items"].first["subtotal_cents"]
            assert_equal "BRL", data["currency"]
            assert_equal 1000, data["subtotal_cents"]
            assert_equal 0, data["delivery_fee_cents"]
            assert_equal 1000, data["total_cents"]
          end
        end

        test "POST /api/v1/customer/cart/items rejects a currency mismatch without changing the cart" do
          usd_product = Product.create!(
            seller: @seller1,
            category: @cat1,
            name: "Imported",
            price_cents: 700,
            currency: "USD",
            active: true
          )
          InventoryItem.create!(seller: @seller1, product: usd_product, quantity: 10)
          cart = Cart.create!(customer: @customer.customer, seller: @seller1)
          original_item = cart.cart_items.create!(product: @prod1, seller: @seller1, quantity: 1)

          post "/api/v1/customer/cart/items",
               params: { product_id: usd_product.id, quantity: 1 }.to_json,
               headers: { "Authorization" => "Bearer #{@session_token}", "Content-Type" => "application/json" }

          assert_response :unprocessable_content
          assert_equal "invalid_input", JSON.parse(response.body).dig("error", "code")
          assert_equal [ original_item.id ], cart.reload.cart_items.pluck(:id)
        end

        test "POST /api/v1/customer/cart/items fails with inactive or zero stock product" do
          post "/api/v1/customer/cart/items",
               params: { product_id: @inactive_prod.id, quantity: 1 }.to_json,
               headers: { "Authorization" => "Bearer #{@session_token}", "Content-Type" => "application/json" }
          assert_response :unprocessable_content

          post "/api/v1/customer/cart/items",
               params: { product_id: @no_stock_prod.id, quantity: 1 }.to_json,
               headers: { "Authorization" => "Bearer #{@session_token}", "Content-Type" => "application/json" }
          assert_response :unprocessable_content
          refute Cart.exists?(customer: @customer.customer), "failed cart mutation must not persist an empty cart"
        end

        test "POST /api/v1/customer/cart/items rejects non-integer and above-maximum quantities" do
          [ "1", 101 ].each do |quantity|
            post "/api/v1/customer/cart/items",
                 params: { product_id: @prod1.id, quantity: quantity }.to_json,
                 headers: { "Authorization" => "Bearer #{@session_token}", "Content-Type" => "application/json" }

            assert_response :unprocessable_content
            assert_equal "invalid_input", JSON.parse(response.body).dig("error", "code")
          end

          refute Cart.exists?(customer: @customer.customer)
        end

        test "POST /api/v1/customer/cart/items rejects non-boolean replace_confirmed" do
          post "/api/v1/customer/cart/items",
               params: { product_id: @prod1.id, quantity: 1, replace_confirmed: "true" }.to_json,
               headers: { "Authorization" => "Bearer #{@session_token}", "Content-Type" => "application/json" }

          assert_response :unprocessable_content
          assert_equal "invalid_input", JSON.parse(response.body).dig("error", "code")
          refute Cart.exists?(customer: @customer.customer)
        end

        test "customer cannot mutate another customer's cart item" do
          other_customer = User.create!(email: "other-cart@example.com", password: "password123", full_name: "Other Customer")
          other_customer.role_assignments.create!(role: "customer")
          other_cart = Cart.create!(customer: other_customer.customer, seller: @seller1)
          other_item = other_cart.cart_items.create!(product: @prod1, seller: @seller1, quantity: 2)

          patch "/api/v1/customer/cart/items/#{other_item.id}",
                params: { quantity: 4 }.to_json,
                headers: { "Authorization" => "Bearer #{@session_token}", "Content-Type" => "application/json" }

          assert_response :not_found
          assert_equal 2, other_item.reload.quantity
        end

        test "POST /api/v1/customer/cart/items with different seller without replace_confirmed returns 409 conflict" do
          cart = Cart.create!(customer: @customer.customer, seller: @seller1)
          cart.cart_items.create!(product: @prod1, seller: @seller1, quantity: 1)

          post "/api/v1/customer/cart/items",
               params: { product_id: @prod2.id, quantity: 1 }.to_json,
               headers: { "Authorization" => "Bearer #{@session_token}", "Content-Type" => "application/json" }
          assert_response :conflict
          body = JSON.parse(response.body)
          assert_equal "seller_conflict", body.dig("error", "code")
        end

        test "failed confirmed replacement preserves the original cart atomically" do
          cart = Cart.create!(customer: @customer.customer, seller: @seller1)
          original_item = cart.cart_items.create!(product: @prod1, seller: @seller1, quantity: 2)

          post "/api/v1/customer/cart/items",
               params: { product_id: @prod2.id, quantity: 11, replace_confirmed: true }.to_json,
               headers: { "Authorization" => "Bearer #{@session_token}", "Content-Type" => "application/json" }

          assert_response :unprocessable_content
          assert_equal "invalid_input", JSON.parse(response.body).dig("error", "code")
          assert_equal @seller1.id, cart.reload.seller_id
          assert_equal [ original_item.id ], cart.cart_items.pluck(:id)
          assert_equal 2, original_item.reload.quantity
        end

        test "POST /api/v1/customer/cart/items with different seller with replace_confirmed replaces cart seller atomically" do
          cart = Cart.create!(customer: @customer.customer, seller: @seller1)
          cart.cart_items.create!(product: @prod1, seller: @seller1, quantity: 1)

          post "/api/v1/customer/cart/items",
               params: { product_id: @prod2.id, quantity: 1, replace_confirmed: true }.to_json,
               headers: { "Authorization" => "Bearer #{@session_token}", "Content-Type" => "application/json" }
          assert_response :created
          data = JSON.parse(response.body).fetch("data")
          assert_equal 1, data["items"].size
          assert_equal @prod2.id, data["items"].first["product_id"]

          assert_equal @seller2.id, cart.reload.seller_id
        end

        test "PATCH /api/v1/customer/cart/items/:id updates quantity" do
          cart = Cart.create!(customer: @customer.customer, seller: @seller1)
          item = cart.cart_items.create!(product: @prod1, seller: @seller1, quantity: 1)

          patch "/api/v1/customer/cart/items/#{item.id}",
                params: { quantity: 5 }.to_json,
                headers: { "Authorization" => "Bearer #{@session_token}", "Content-Type" => "application/json" }
          assert_response :success
          assert_equal 5, item.reload.quantity
        end

        test "DELETE /api/v1/customer/cart clears cart items" do
          cart = Cart.create!(customer: @customer.customer, seller: @seller1)
          cart.cart_items.create!(product: @prod1, seller: @seller1, quantity: 2)

          delete "/api/v1/customer/cart", headers: { "Authorization" => "Bearer #{@session_token}" }
          assert_response :success
          assert_equal 0, cart.reload.cart_items.count
          assert_nil cart.seller_id
        end
      end
    end
  end
end

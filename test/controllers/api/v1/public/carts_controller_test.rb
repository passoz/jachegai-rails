require "test_helper"

class GuestCartControllerTest < ActionDispatch::IntegrationTest
  setup do
    @seller1 = Seller.create!(name: "Seller 1", moderation_state: "approved")
    @seller2 = Seller.create!(name: "Seller 2", moderation_state: "approved")
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

  test "GET /api/v1/public/cart without token returns empty cart without database creation" do
    assert_no_difference "GuestCart.count" do
      get "/api/v1/public/cart"
      assert_response :success
      data = JSON.parse(response.body).fetch("data")
      assert_nil data["cart_id"]
      assert_equal [], data["items"]
      assert_equal 0, data["total_cents"]
    end
  end

  test "POST /api/v1/public/cart/items creates guest cart and returns token" do
    assert_difference "GuestCart.count", 1 do
      post "/api/v1/public/cart/items", params: { product_id: @prod1.id, quantity: 2 }.to_json, headers: { "Content-Type" => "application/json" }
      assert_response :created
      data = JSON.parse(response.body).fetch("data")
      assert data["token"].present?
      cart = GuestCart.find(data.fetch("cart_id"))
      assert_equal Digest::SHA256.hexdigest(data.fetch("token")), cart.token_digest
      refute_equal data.fetch("token"), cart.token_digest
      assert_equal 1, data["items"].size
      assert_equal @prod1.id, data["items"].first["product_id"]
      assert_equal 2, data["items"].first["quantity"]
      assert_equal 1000, data["total_cents"]
    end
  end

  test "cart mutation accepts only strict JSON payloads" do
    post "/api/v1/public/cart/items", params: { product_id: @prod1.id, quantity: 1 }.to_json, headers: { "Content-Type" => "text/plain" }
    assert_response :bad_request
    assert_equal "invalid_content_type", JSON.parse(response.body).dig("error", "code")

    post "/api/v1/public/cart/items", params: "{", headers: { "Content-Type" => "application/json" }
    assert_response :bad_request
    assert_equal "invalid_json", JSON.parse(response.body).dig("error", "code")

    post "/api/v1/public/cart/items", params: { product_id: @prod1.id, quantity: 1, ignored: true }.to_json, headers: { "Content-Type" => "application/json" }
    assert_response :unprocessable_content
    assert_equal "unknown_fields", JSON.parse(response.body).dig("error", "code")
  end

  test "POST /api/v1/public/cart/items with inactive or zero stock product fails" do
    post "/api/v1/public/cart/items", params: { product_id: @inactive_prod.id, quantity: 1 }.to_json, headers: { "Content-Type" => "application/json" }
    assert_response :unprocessable_content

    post "/api/v1/public/cart/items", params: { product_id: @no_stock_prod.id, quantity: 1 }.to_json, headers: { "Content-Type" => "application/json" }
    assert_response :unprocessable_content
  end

  test "POST /api/v1/public/cart/items with different seller without replace_confirmed returns 409 conflict" do
    token, digest = GuestCart.generate_token
    cart = GuestCart.create!(token_digest: digest, seller: @seller1)
    cart.guest_cart_items.create!(product: @prod1, seller: @seller1, quantity: 1)

    post "/api/v1/public/cart/items", params: { product_id: @prod2.id, quantity: 1 }.to_json, headers: { "Content-Type" => "application/json", "X-Guest-Token" => token }
    assert_response :conflict
    body = JSON.parse(response.body)
    assert_equal "seller_conflict", body.dig("error", "code")

    # Cart remains unchanged
    assert_equal 1, cart.reload.guest_cart_items.count
    assert_equal @seller1.id, cart.seller_id
  end

  test "POST /api/v1/public/cart/items with different seller with replace_confirmed replaces cart seller atomically" do
    token, digest = GuestCart.generate_token
    cart = GuestCart.create!(token_digest: digest, seller: @seller1)
    cart.guest_cart_items.create!(product: @prod1, seller: @seller1, quantity: 1)

    post "/api/v1/public/cart/items", params: { product_id: @prod2.id, quantity: 1, replace_confirmed: true }.to_json, headers: { "Content-Type" => "application/json", "X-Guest-Token" => token }
    assert_response :created
    data = JSON.parse(response.body).fetch("data")
    assert_equal 1, data["items"].size
    assert_equal @prod2.id, data["items"].first["product_id"]

    cart.reload
    assert_equal @seller2.id, cart.seller_id
  end

  test "POST replacement rolls back the original cart when adding its new item fails" do
    token, digest = GuestCart.generate_token
    cart = GuestCart.create!(token_digest: digest, seller: @seller1)
    original_item = cart.guest_cart_items.create!(product: @prod1, seller: @seller1, quantity: 1)

    GuestCartItem.class_eval do
      alias_method :save_before_phase04_failure_probe!, :save!
      define_method(:save!) { |**| raise "injected item persistence failure" }
    end

    post "/api/v1/public/cart/items", params: { product_id: @prod2.id, quantity: 1, replace_confirmed: true }.to_json, headers: { "Content-Type" => "application/json", "X-Guest-Token" => token }
    assert_response :internal_server_error

    cart.reload
    assert_equal @seller1.id, cart.seller_id
    assert GuestCartItem.exists?(original_item.id)
  ensure
    GuestCartItem.class_eval do
      remove_method :save!
      alias_method :save!, :save_before_phase04_failure_probe!
      remove_method :save_before_phase04_failure_probe!
    end
  end

  test "POST /api/v1/public/cart/items rejects cumulative quantity above stock or the cart maximum" do
    token, digest = GuestCart.generate_token
    cart = GuestCart.create!(token_digest: digest, seller: @seller1)
    cart.guest_cart_items.create!(product: @prod1, seller: @seller1, quantity: 6)

    post "/api/v1/public/cart/items", params: { product_id: @prod1.id, quantity: 5 }.to_json, headers: { "Content-Type" => "application/json", "X-Guest-Token" => token }
    assert_response :unprocessable_content
    assert_equal 6, cart.guest_cart_items.find_by!(product: @prod1).quantity

    InventoryItem.find_by!(product: @prod1).update!(quantity: 1000)
    post "/api/v1/public/cart/items", params: { product_id: @prod1.id, quantity: GuestCartItem::MAX_QUANTITY }.to_json, headers: { "Content-Type" => "application/json", "X-Guest-Token" => token }
    assert_response :unprocessable_content
    assert_equal 6, cart.guest_cart_items.find_by!(product: @prod1).quantity
  end

  test "PATCH /api/v1/public/cart/items/:id updates quantity or removes when 0" do
    token, digest = GuestCart.generate_token
    cart = GuestCart.create!(token_digest: digest, seller: @seller1)
    item = cart.guest_cart_items.create!(product: @prod1, seller: @seller1, quantity: 1)

    patch "/api/v1/public/cart/items/#{item.id}", params: { quantity: 5 }.to_json, headers: { "Content-Type" => "application/json", "X-Guest-Token" => token }
    assert_response :success
    assert_equal 5, item.reload.quantity

    patch "/api/v1/public/cart/items/#{item.id}", params: { quantity: 0 }.to_json, headers: { "Content-Type" => "application/json", "X-Guest-Token" => token }
    assert_response :success
    refute GuestCartItem.exists?(item.id)
  end

  test "expired cart tokens cannot mutate existing carts" do
    token, digest = GuestCart.generate_token
    cart = GuestCart.create!(token_digest: digest, seller: @seller1, expires_at: 1.minute.ago)
    item = cart.guest_cart_items.create!(product: @prod1, seller: @seller1, quantity: 1)
    headers = { "Content-Type" => "application/json", "X-Guest-Token" => token }

    patch "/api/v1/public/cart/items/#{item.id}", params: { quantity: 2 }.to_json, headers: headers
    assert_response :gone
    assert_equal 1, item.reload.quantity

    delete "/api/v1/public/cart/items/#{item.id}", headers: { "X-Guest-Token" => token }
    assert_response :gone
    assert GuestCartItem.exists?(item.id)

    delete "/api/v1/public/cart", headers: { "X-Guest-Token" => token }
    assert_response :gone
    assert GuestCartItem.exists?(item.id)
  end

  test "PATCH rejects a product that becomes inactive, unavailable, or belongs to a non-public seller" do
    token, digest = GuestCart.generate_token
    cart = GuestCart.create!(token_digest: digest, seller: @seller1)
    item = cart.guest_cart_items.create!(product: @prod1, seller: @seller1, quantity: 1)
    headers = { "Content-Type" => "application/json", "X-Guest-Token" => token }

    @prod1.update!(active: false)
    patch "/api/v1/public/cart/items/#{item.id}", params: { quantity: 2 }.to_json, headers: headers
    assert_response :unprocessable_content
    assert_equal 1, item.reload.quantity

    @prod1.update!(active: true)
    @seller1.update!(moderation_state: "suspended")
    patch "/api/v1/public/cart/items/#{item.id}", params: { quantity: 2 }.to_json, headers: headers
    assert_response :unprocessable_content
    assert_equal 1, item.reload.quantity
  end

  test "cart mutations are rate limited by IP and opaque cart token" do
    token, digest = GuestCart.generate_token
    cart = GuestCart.create!(token_digest: digest, seller: @seller1)
    item = cart.guest_cart_items.create!(product: @prod1, seller: @seller1, quantity: 1)
    headers = { "Content-Type" => "application/json", "X-Guest-Token" => token }

    GuestCartItem::MUTATION_RATE_LIMIT.times do
      patch "/api/v1/public/cart/items/#{item.id}", params: { quantity: 1 }.to_json, headers: headers
      assert_response :success
    end

    patch "/api/v1/public/cart/items/#{item.id}", params: { quantity: 1 }.to_json, headers: headers
    assert_response :too_many_requests
    assert_equal "rate_limited", JSON.parse(response.body).dig("error", "code")
  end

  test "DELETE /api/v1/public/cart clears cart items" do
    token, digest = GuestCart.generate_token
    cart = GuestCart.create!(token_digest: digest, seller: @seller1)
    cart.guest_cart_items.create!(product: @prod1, seller: @seller1, quantity: 2)

    delete "/api/v1/public/cart", headers: { "X-Guest-Token" => token }
    assert_response :success
    assert_equal 0, cart.reload.guest_cart_items.count
    assert_nil cart.seller_id
  end
end

require "test_helper"

class GuestCartTest < ActiveSupport::TestCase
  setup do
    @seller1 = Seller.create!(name: "Seller 1", moderation_state: "approved")
    @seller2 = Seller.create!(name: "Seller 2", moderation_state: "approved")
    @category1 = Category.create!(seller: @seller1, name: "Cat 1", position: 1)
    @category2 = Category.create!(seller: @seller2, name: "Cat 2", position: 1)
    @product1 = Product.create!(seller: @seller1, category: @category1, name: "Prod 1", price_cents: 100, currency: "BRL", active: true)
    @product2 = Product.create!(seller: @seller2, category: @category2, name: "Prod 2", price_cents: 200, currency: "BRL", active: true)
    InventoryItem.create!(seller: @seller1, product: @product1, quantity: 10)
    InventoryItem.create!(seller: @seller2, product: @product2, quantity: 10)
  end

  test "generate_token returns opaque non-guessable token and token_digest" do
    token, digest = GuestCart.generate_token
    assert token.is_a?(String)
    assert token.bytesize >= 32
    assert_equal Digest::SHA256.hexdigest(token), digest
  end

  test "default expiry is 7 days from creation" do
    token, digest = GuestCart.generate_token
    cart = GuestCart.create!(token_digest: digest)
    assert cart.expires_at > 6.days.from_now
    assert cart.expires_at <= 7.days.from_now + 5.seconds
    refute cart.expired?
  end

  test "expired? returns true when past expires_at" do
    token, digest = GuestCart.generate_token
    cart = GuestCart.create!(token_digest: digest, expires_at: 1.minute.ago)
    assert cart.expired?
  end

  test "model fails closed without a cart seller and rejects a second seller" do
    token, digest = GuestCart.generate_token
    cart = GuestCart.create!(token_digest: digest)

    missing_seller_item = cart.guest_cart_items.build(product: @product1, seller: @seller1, quantity: 2)
    refute missing_seller_item.valid?
    assert_includes missing_seller_item.errors[:product], "must belong to the cart seller"

    cart.guest_cart_items.reset
    cart.update!(seller: @seller1)
    cart.guest_cart_items.create!(product: @product1, seller: @seller1, quantity: 2)
    other_seller_item = cart.guest_cart_items.build(product: @product2, seller: @seller2, quantity: 1)
    refute other_seller_item.valid?
    assert_includes other_seller_item.errors[:product], "must belong to the cart seller"

    assert_raises ActiveRecord::InvalidForeignKey do
      GuestCartItem.insert_all!(
        [ {
          id: ApplicationId.generate,
          guest_cart_id: cart.id,
          product_id: @product2.id,
          seller_id: @seller2.id,
          quantity: 1,
          created_at: Time.current,
          updated_at: Time.current
        } ]
      )
    end
    assert_equal [ @product1.id ], cart.reload.guest_cart_items.pluck(:product_id)
  end

  test "quantity is bounded in model and database" do
    token, digest = GuestCart.generate_token
    cart = GuestCart.create!(token_digest: digest, seller: @seller1)

    item = cart.guest_cart_items.build(product: @product1, quantity: GuestCartItem::MAX_QUANTITY + 1)
    refute item.valid?
    assert item.errors[:quantity].any?

    assert_raises ActiveRecord::StatementInvalid do
      GuestCartItem.insert_all!(
        [ {
          id: ApplicationId.generate,
          guest_cart_id: cart.id,
          product_id: @product1.id,
          seller_id: @seller1.id,
          quantity: GuestCartItem::MAX_QUANTITY + 1,
          created_at: Time.current,
          updated_at: Time.current
        } ]
      )
    end
  end
end

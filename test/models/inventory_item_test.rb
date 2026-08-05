require "test_helper"

class InventoryItemTest < ActiveSupport::TestCase
  setup do
    @seller = Seller.create!(name: "Loja de Estoque")
    @product = Product.create!(seller: @seller, name: "Arroz 5kg", price_cents: 2490, currency: "BRL")
  end

  test "inventory defaults to zero quantity" do
    item = InventoryItem.create!(seller: @seller, product: @product)
    assert_equal 0, item.quantity
  end

  test "quantity cannot be negative at model level" do
    item = InventoryItem.new(seller: @seller, product: @product, quantity: -1)
    assert_not item.valid?
    assert item.errors[:quantity].any?
  end

  test "one inventory item per product" do
    InventoryItem.create!(seller: @seller, product: @product, quantity: 5)
    duplicate = InventoryItem.new(seller: @seller, product: @product, quantity: 3)
    assert_not duplicate.valid?
    assert duplicate.errors[:product_id].any?
  end

  test "product must belong to the same seller" do
    other_seller = Seller.create!(name: "Estoque Alheio")
    other_product = Product.create!(seller: other_seller, name: "Feijão", price_cents: 890, currency: "BRL")
    item = InventoryItem.new(seller: @seller, product: other_product, quantity: 1)
    assert_not item.valid?
    assert item.errors[:product_id].any?
  end

  test "database rejects negative quantity" do
    item = InventoryItem.create!(seller: @seller, product: @product, quantity: 5)
    assert_raises(ActiveRecord::StatementInvalid) do
      item.update_columns(quantity: -3)
    end
  end
end

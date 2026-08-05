require "test_helper"

class InventoryServiceTest < ActiveSupport::TestCase
  setup do
    @seller = Seller.create!(name: "Loja de Inventário")
    @product = Product.create!(seller: @seller, name: "Arroz", price_cents: 2000, currency: "BRL")
  end

  test "sets quantity and creates the inventory item on first update" do
    item = InventoryService.set_quantity(seller: @seller, product: @product, quantity: 10)
    assert item.persisted?
    assert_equal 10, item.quantity
    assert_equal @seller.id, item.seller_id
  end

  test "updates quantity atomically on subsequent updates" do
    InventoryService.set_quantity(seller: @seller, product: @product, quantity: 10)
    item = InventoryService.set_quantity(seller: @seller, product: @product, quantity: 7)
    assert_equal 7, item.quantity
    assert_equal 1, InventoryItem.where(product: @product).count
  end

  test "negative quantity raises a model error" do
    assert_raises(ActiveRecord::RecordInvalid) do
      InventoryService.set_quantity(seller: @seller, product: @product, quantity: -1)
    end
  end
end

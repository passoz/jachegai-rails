require "test_helper"

class ProductServiceTest < ActiveSupport::TestCase
  setup do
    @seller = Seller.create!(name: "Loja de Serviços de Produto")
  end

  test "creates a product with price in minor units" do
    product = ProductService.create(
      seller: @seller,
      params: { name: "Café", price_cents: 1590, currency: "BRL" }
    )
    assert product.persisted?
    assert_equal 1590, product.price_cents
    assert product.active?
  end

  test "updates a product" do
    product = Product.create!(seller: @seller, name: "Café", price_cents: 1000, currency: "BRL")
    ProductService.update(product: product, params: { name: "Café Gourmet", price_cents: 2500 })
    product.reload
    assert_equal "Café Gourmet", product.name
    assert_equal 2500, product.price_cents
  end

  test "activates and deactivates a product" do
    product = Product.create!(seller: @seller, name: "Chá", price_cents: 700, currency: "BRL")
    ProductService.set_active(product: product, active: false)
    assert_not product.reload.active?
    ProductService.set_active(product: product, active: true)
    assert product.reload.active?
  end

  test "destroy raises conflict when product has inventory or media history" do
    product = Product.create!(seller: @seller, name: "Histórico", price_cents: 100, currency: "BRL")
    InventoryItem.create!(seller: @seller, product: product, quantity: 3)

    error = assert_raises(DomainError) { ProductService.destroy(product: product) }
    assert_equal "product_in_use", error.code
    assert_equal :conflict, error.http_status
    assert Product.exists?(product.id)
  end

  test "destroy removes a product with no operational history" do
    product = Product.create!(seller: @seller, name: "Novo", price_cents: 100, currency: "BRL")
    ProductService.destroy(product: product)
    assert_not Product.exists?(product.id)
  end
end

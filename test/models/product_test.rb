require "test_helper"

class ProductTest < ActiveSupport::TestCase
  setup do
    @seller = Seller.create!(name: "Loja de Produtos")
  end

  test "product requires a name and defaults to active" do
    product = Product.create!(seller: @seller, name: "Café 250g", price_cents: 1990, currency: "BRL")
    assert product.id.present?
    assert product.active?
  end

  test "price must use non-negative integer minor units" do
    negative = Product.new(seller: @seller, name: "Negativo", price_cents: -1, currency: "BRL")
    assert_not negative.valid?
    assert negative.errors[:price_cents].any?

    fractional = Product.new(seller: @seller, name: "Fracionário", price_cents: 1.5, currency: "BRL")
    assert_not fractional.valid?
  end

  test "currency must be a three-letter code" do
    product = Product.new(seller: @seller, name: "Moeda", price_cents: 100, currency: "BRLR")
    assert_not product.valid?
    assert product.errors[:currency].any?
  end

  test "category must belong to the same seller" do
    other_seller = Seller.create!(name: "Outra Loja")
    foreign_category = Category.create!(seller: other_seller, name: "Alheia")
    product = Product.new(seller: @seller, name: "Conflito", price_cents: 100, currency: "BRL", category: foreign_category)
    assert_not product.valid?
    assert product.errors[:category_id].any?
  end
end

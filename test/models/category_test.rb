require "test_helper"

class CategoryTest < ActiveSupport::TestCase
  setup do
    @seller = Seller.create!(name: "Loja de Categorias")
  end

  test "category requires a name and belongs to a seller" do
    category = Category.create!(seller: @seller, name: "Bebidas")
    assert category.id.present?
    assert_equal 0, category.position
  end

  test "category name is unique per seller" do
    Category.create!(seller: @seller, name: "Bebidas")
    duplicate = Category.new(seller: @seller, name: "Bebidas")
    assert_not duplicate.valid?
    assert duplicate.errors[:name].any?
  end

  test "category position is non-negative and unique per seller" do
    category = Category.new(seller: @seller, name: "Doces", position: -1)
    assert_not category.valid?
    assert category.errors[:position].any?

    Category.create!(seller: @seller, name: "First", position: 0)
    duplicate = Category.new(seller: @seller, name: "Second", position: 0)
    assert_not duplicate.valid?
    assert duplicate.errors[:position].any?
  end

  test "category ordering is deterministic by position then id" do
    a = Category.create!(seller: @seller, name: "A", position: 2)
    b = Category.create!(seller: @seller, name: "B", position: 0)
    c = Category.create!(seller: @seller, name: "C", position: 1)
    assert_equal [ b.id, c.id, a.id ], @seller.categories.ordered.pluck(:id)
  end
end

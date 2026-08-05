require "test_helper"

class CategoryServiceTest < ActiveSupport::TestCase
  setup do
    @seller = Seller.create!(name: "Loja de Serviços")
  end

  test "creates a category for the seller" do
    category = CategoryService.create(seller: @seller, params: { name: "Padaria" })
    assert category.persisted?
    assert_equal @seller.id, category.seller_id
    assert_equal 0, category.position
  end

  test "updates name and position" do
    category = Category.create!(seller: @seller, name: "Padaria")
    CategoryService.update(category: category, params: { name: "Confeitaria", position: 2 })
    category.reload
    assert_equal "Confeitaria", category.name
    assert_equal 2, category.position
  end

  test "destroy raises conflict when category has products" do
    category = Category.create!(seller: @seller, name: "Bebidas")
    Product.create!(seller: @seller, category: category, name: "Suco", price_cents: 500, currency: "BRL")

    error = assert_raises(DomainError) { CategoryService.destroy(category: category) }
    assert_equal "category_in_use", error.code
    assert_equal :conflict, error.http_status
    assert Category.exists?(category.id)
  end

  test "destroy removes an unused category" do
    category = Category.create!(seller: @seller, name: "Sem Uso")
    CategoryService.destroy(category: category)
    assert_not Category.exists?(category.id)
  end

  test "reorder assigns sequential positions and validates ownership" do
    a = Category.create!(seller: @seller, name: "A", position: 0)
    b = Category.create!(seller: @seller, name: "B", position: 1)
    c = Category.create!(seller: @seller, name: "C", position: 2)

    CategoryService.reorder(seller: @seller, ordered_ids: [ c.id, a.id, b.id ])
    assert_equal [ c.id, a.id, b.id ], @seller.categories.ordered.pluck(:id)
    assert_equal [ 0, 1, 2 ], @seller.categories.ordered.pluck(:position)
  end

  test "reorder rejects ids that do not belong to the seller" do
    other = Seller.create!(name: "Alheio")
    foreign = Category.create!(seller: other, name: "Estranha")
    own = Category.create!(seller: @seller, name: "Própria")

    assert_raises(DomainError) { CategoryService.reorder(seller: @seller, ordered_ids: [ foreign.id, own.id ]) }
  end
end

# ProductService implements seller-owned product operations and lifecycle
# rules (SEL-005/006). Products with operational history (inventory or media)
# cannot be hard-deleted; use deactivate instead.
class ProductService
  CREATE_PARAMS = %i[name description price_cents currency category_id].freeze
  UPDATE_PARAMS = %i[name description price_cents currency category_id active].freeze

  def self.create(seller:, params:)
    seller.products.create!(**params.slice(*CREATE_PARAMS))
  end

  def self.update(product:, params:)
    product.update!(**params.slice(*UPDATE_PARAMS))
    product
  end

  def self.set_active(product:, active:)
    product.update!(active: active)
    product
  end

  def self.destroy(product:)
    if product.inventory_item.present? || product.uploads.exists?
      raise DomainError.new(code: :product_in_use, context: { product_id: product.id })
    end

    product.destroy!
    product
  end
end

# CategoryService implements seller-owned category operations with
# referential conflict rules (SEL-004).
class CategoryService
  def self.create(seller:, params:)
    attributes = params.slice(:name, :position)
    unless attributes.key?(:position)
      maximum_position = seller.categories.maximum(:position)
      attributes[:position] = maximum_position ? maximum_position + 1 : 0
    end
    seller.categories.create!(**attributes)
  end

  def self.update(category:, params:)
    category.update!(**params.slice(:name, :position))
    category
  end

  def self.destroy(category:)
    if category.products.exists?
      raise DomainError.new(code: :category_in_use, context: { category_id: category.id })
    end

    category.destroy!
    category
  end

  # Reorders a seller's categories. The ordered_ids list MUST contain exactly
  # the seller's own category ids (no duplicates, no foreign ids).
  def self.reorder(seller:, ordered_ids:)
    ids = Array(ordered_ids).map(&:to_s)
    owned = seller.categories.pluck(:id)
    unless ids.uniq.size == ids.size && ids.sort == owned.sort
      raise DomainError.new(code: :invalid_input, context: { reason: "ordered_ids must contain exactly the seller's categories" })
    end

    seller.transaction do
      temporary_offset = seller.categories.maximum(:position).to_i + ids.size + 1
      timestamp = Time.current
      ids.each_with_index do |id, index|
        seller.categories.where(id: id).update_all(position: temporary_offset + index, updated_at: timestamp)
      end
      ids.each_with_index do |id, index|
        seller.categories.where(id: id).update_all(position: index, updated_at: timestamp)
      end
    end
  end
end

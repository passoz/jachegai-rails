# InventoryService manages inventory for a seller's products (SEL-007/008).
# Quantity is validated >= 0 at the model and enforced by a DB check
# constraint; each product has exactly one inventory item.
class InventoryService
  def self.set_quantity(seller:, product:, quantity:)
    item = seller.inventory_items.find_by(product: product)
    return update_existing!(item, quantity) if item

    seller.inventory_items.create!(product: product, quantity: quantity)
  rescue ActiveRecord::RecordNotUnique
    update_existing!(seller.inventory_items.find_by!(product: product), quantity)
  end

  def self.update_existing!(item, quantity)
    item.with_lock do
      item.update!(quantity: quantity)
    end
    item
  end
  private_class_method :update_existing!
end

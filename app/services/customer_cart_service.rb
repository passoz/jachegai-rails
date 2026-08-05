class CustomerCartService
  def self.add_item(customer:, product_id:, quantity:, replace_confirmed: false)
    product = available_product(product_id)
    raise invalid_product_error unless product

    cart = nil
    ActiveRecord::Base.transaction do
      cart = Cart.create_or_find_by!(customer: customer)
      cart.lock!

      if cart.seller_id.present? && cart.seller_id != product.seller_id
        raise seller_conflict(cart, product) unless replace_confirmed

        cart.cart_items.destroy_all
        cart.update!(seller: product.seller)
      elsif cart.seller_id.nil?
        cart.update!(seller: product.seller)
      end

      item = cart.cart_items.find_or_initialize_by(product: product, seller: product.seller)
      item.quantity = (item.quantity || 0) + quantity
      item.save!
    end

    cart
  end

  def self.update_item(customer:, item_id:, quantity:)
    cart = customer.cart || raise(ActiveRecord::RecordNotFound)

    cart.with_lock do
      item = cart.cart_items.find_by(id: item_id) || raise(ActiveRecord::RecordNotFound)
      if quantity.zero?
        item.destroy!
        cart.update!(seller: nil) if cart.cart_items.reload.empty?
      else
        item.update!(quantity: quantity)
      end
    end

    cart
  end

  def self.remove_item(customer:, item_id:)
    cart = customer.cart || raise(ActiveRecord::RecordNotFound)

    cart.with_lock do
      item = cart.cart_items.find_by(id: item_id) || raise(ActiveRecord::RecordNotFound)
      item.destroy!
      cart.update!(seller: nil) if cart.cart_items.reload.empty?
    end

    cart
  end

  def self.clear(customer:)
    cart = customer.cart
    return nil unless cart

    cart.with_lock do
      cart.cart_items.destroy_all
      cart.update!(seller: nil)
    end
    cart
  end

  def self.available_product(product_id)
    Product.joins(:seller).where(sellers: { moderation_state: "approved" }, active: true).find_by(id: product_id)
  end
  private_class_method :available_product

  def self.invalid_product_error
    DomainError.new(
      code: :invalid_input,
      http_status: :unprocessable_content,
      context: { fields: { product_id: [ I18n.t("errors.messages.invalid") ] } }
    )
  end
  private_class_method :invalid_product_error

  def self.seller_conflict(cart, product)
    DomainError.new(
      code: :seller_conflict,
      http_status: :conflict,
      context: { current_seller_id: cart.seller_id, new_seller_id: product.seller_id }
    )
  end
  private_class_method :seller_conflict
end

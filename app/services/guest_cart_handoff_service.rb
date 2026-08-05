class GuestCartHandoffService
  def self.handoff(customer:, guest_token:, replace_confirmed: false)
    guest_cart = find_guest_cart(guest_token)
    return customer.cart if guest_cart.nil? || guest_cart.expired?

    cart = nil
    ActiveRecord::Base.transaction do
      cart = Cart.create_or_find_by!(customer: customer)
      cart.lock!
      guest_cart.lock!

      if guest_cart.seller_id.present? && cart.seller_id.present? && cart.seller_id != guest_cart.seller_id
        raise seller_conflict(cart, guest_cart) unless replace_confirmed

        cart.cart_items.destroy_all
        cart.update!(seller: guest_cart.seller)
      elsif cart.seller_id.nil? && guest_cart.seller_id.present?
        cart.update!(seller: guest_cart.seller)
      end

      guest_cart.guest_cart_items.each do |guest_item|
        customer_item = cart.cart_items.find_or_initialize_by(product: guest_item.product, seller: guest_item.seller)
        customer_item.quantity = (customer_item.quantity || 0) + guest_item.quantity
        customer_item.save!
      end

      guest_cart.destroy!
    end

    cart
  end

  def self.find_guest_cart(token)
    return nil if token.blank?

    GuestCart.find_by(token_digest: Digest::SHA256.hexdigest(token))
  end
  private_class_method :find_guest_cart

  def self.seller_conflict(cart, guest_cart)
    DomainError.new(
      code: :seller_conflict,
      http_status: :conflict,
      context: { current_seller_id: cart.seller_id, new_seller_id: guest_cart.seller_id }
    )
  end
  private_class_method :seller_conflict
end

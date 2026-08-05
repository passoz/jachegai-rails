class Api::V1::Customer::CartsController < Api::V1::BaseController
  before_action :require_customer!

  # GET /api/v1/customer/cart
  def show
    cart = current_customer.cart
    if cart.nil?
      return render_success(data: empty_cart_payload)
    end

    render_success data: serialize_cart(cart)
  end

  # DELETE /api/v1/customer/cart
  def destroy
    cart = CustomerCartService.clear(customer: current_customer)
    render_success data: empty_cart_payload(cart_id: cart&.id)
  end

  private

  def require_customer!
    raise Forbidden unless Current.principal&.has_role?(:customer)
  end

  def current_customer
    Current.principal&.user&.customer || raise(ActiveRecord::RecordNotFound)
  end

  def empty_cart_payload(cart_id: nil)
    {
      cart_id: cart_id,
      seller_id: nil,
      currency: nil,
      items: [],
      subtotal_cents: 0,
      delivery_fee_cents: 0,
      total_cents: 0
    }
  end

  def serialize_cart(cart)
    items = cart.cart_items.includes(:product).order(:created_at, :id)
    subtotal_cents = items.sum { |item| item.product.price_cents * item.quantity }
    delivery_fee_cents = 0

    {
      cart_id: cart.id,
      seller_id: cart.seller_id,
      currency: items.first&.product&.currency,
      items: items.map { |item|
        {
          id: item.id,
          product_id: item.product_id,
          product_name: item.product.name,
          quantity: item.quantity,
          unit_price_cents: item.product.price_cents,
          currency: item.product.currency,
          subtotal_cents: item.product.price_cents * item.quantity
        }
      },
      subtotal_cents: subtotal_cents,
      delivery_fee_cents: delivery_fee_cents,
      total_cents: subtotal_cents + delivery_fee_cents
    }
  end
end

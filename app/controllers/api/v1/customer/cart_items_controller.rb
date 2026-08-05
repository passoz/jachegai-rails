class Api::V1::Customer::CartItemsController < Api::V1::BaseController
  before_action :require_customer!

  # POST /api/v1/customer/cart/items
  def create
    return if parse_payload!(allowed_fields: [ :product_id, :quantity, :replace_confirmed ]) == false
    require_payload_fields!(:product_id, :quantity)
    require_string_field!(:product_id)
    require_cart_quantity!(:quantity, minimum: 1)
    require_boolean_field!(:replace_confirmed)

    cart = CustomerCartService.add_item(
      customer: current_customer,
      product_id: @payload[:product_id],
      quantity: @payload[:quantity],
      replace_confirmed: @payload[:replace_confirmed] == true
    )
    render_success data: serialize_cart(cart), status: :created
  end

  # PATCH /api/v1/customer/cart/items/:id
  def update
    return if parse_payload!(allowed_fields: [ :quantity ]) == false
    require_payload_fields!(:quantity)
    require_cart_quantity!(:quantity, minimum: 0)

    cart = CustomerCartService.update_item(
      customer: current_customer,
      item_id: params[:id],
      quantity: @payload[:quantity]
    )
    render_success data: serialize_cart(cart)
  end

  # DELETE /api/v1/customer/cart/items/:id
  def destroy
    cart = CustomerCartService.remove_item(customer: current_customer, item_id: params[:id])
    render_success data: serialize_cart(cart)
  end

  # POST /api/v1/customer/cart/handoff
  def handoff
    return if parse_payload!(allowed_fields: [ :guest_token, :replace_confirmed ]) == false
    require_payload_fields!(:guest_token)
    require_string_field!(:guest_token)
    require_boolean_field!(:replace_confirmed)

    cart = GuestCartHandoffService.handoff(
      customer: current_customer,
      guest_token: @payload[:guest_token],
      replace_confirmed: @payload[:replace_confirmed] == true
    )
    render_success data: cart ? serialize_cart(cart) : empty_cart_payload
  end

  private

  def require_customer!
    raise Forbidden unless Current.principal&.has_role?(:customer)
  end

  def current_customer
    Current.principal&.user&.customer || raise(ActiveRecord::RecordNotFound)
  end

  def empty_cart_payload
    {
      cart_id: nil,
      seller_id: nil,
      currency: nil,
      items: [],
      subtotal_cents: 0,
      delivery_fee_cents: 0,
      total_cents: 0
    }
  end

  def require_cart_quantity!(field, minimum:)
    quantity = require_integer_field!(field, minimum: minimum)
    return quantity if quantity <= ::CartItem::MAX_QUANTITY

    invalid_payload_field!(field)
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

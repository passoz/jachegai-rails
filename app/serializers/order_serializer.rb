class OrderSerializer
  def self.as_json(order)
    items = if order.association(:order_items).loaded?
      order.order_items.sort_by { |item| [ item.created_at, item.id ] }
    else
      order.order_items.order(:created_at, :id).to_a
    end
    payment = order.payment

    {
      id: order.id,
      customer_id: order.customer_id,
      seller_id: order.seller_id,
      courier_id: order.courier_id,
      order_state: order.status,
      payment_state: payment&.state,
      currency: order.currency,
      subtotal_cents: order.subtotal_cents,
      delivery_fee_cents: order.delivery_fee_cents,
      discount_cents: order.discount_cents,
      courier_fee_cents: order.courier_fee_cents,
      total_cents: order.total_cents,
      items: items.map { |item|
        {
          id: item.id,
          product_id: item.product_id,
          product_name: item.product_name,
          quantity: item.quantity,
          unit_price_cents: item.unit_price_cents,
          subtotal_cents: item.subtotal_cents,
          currency: item.currency
        }
      },
      delivery_address: {
        name: order.address_name,
        line1: order.address_line1,
        city: order.address_city,
        state: order.address_state,
        zip: order.address_zip,
        country: order.address_country
      },
      history: (order.association(:order_status_histories).loaded? ? order.order_status_histories : order.order_status_histories.order(:created_at)).map { |h|
        {
          from_status: h.from_status,
          to_status: h.to_status,
          reason: h.reason,
          created_at: h.created_at.iso8601
        }
      },
      created_at: order.created_at.iso8601
    }
  end
end

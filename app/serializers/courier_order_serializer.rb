class CourierOrderSerializer
  def self.eligible(order)
    {
      id: order.id,
      seller_id: order.seller_id,
      order_state: order.status,
      currency: order.currency,
      courier_fee_cents: order.courier_fee_cents,
      created_at: order.created_at.iso8601
    }
  end
end

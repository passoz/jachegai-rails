class CheckoutService
  LOCK_RETRY_DELAYS = [ 0.01, 0.025, 0.05 ].freeze

  def initialize(payment_gateway: Payments::SimulatedGateway.new)
    @payment_gateway = payment_gateway
  end

  def call(customer:, address_id:, idempotency_key:, actor_principal_id:, request_id: nil)
    IdempotencyService.execute(
      principal_id: customer.id,
      operation: "checkout",
      key: idempotency_key,
      payload: { address_id: address_id }
    ) do |idempotency_record|
      with_sqlite_lock_retry do
        perform_checkout(
          customer: customer,
          address_id: address_id,
          idempotency_key: idempotency_key,
          idempotency_record: idempotency_record,
          actor_principal_id: actor_principal_id,
          request_id: request_id
        )
      end
    end
  end

  private

  def perform_checkout(customer:, address_id:, idempotency_key:, idempotency_record:, actor_principal_id:, request_id:)
    order = nil

    ActiveRecord::Base.transaction do
      address = customer.addresses.find(address_id)
      cart = customer.cart || raise_invalid(:cart_id)
      cart.lock!
      items = cart.cart_items.includes(product: [ :seller, :inventory_item ]).order(:created_at, :id).to_a
      raise_invalid(:cart_id) if items.empty?

      seller = validate_cart!(cart, items)
      currency = validate_currency!(items)
      totals = OrderTotals.calculate(
        lines: items.map { |item| { unit_price_cents: item.product.price_cents, quantity: item.quantity } },
        currency: currency
      )

      order = create_order(customer: customer, seller: seller, address: address, totals: totals)
      create_item_snapshots(order, items, currency)
      decrement_inventory(order, items)
      create_initial_history(order, actor_principal_id, request_id)
      create_payment(order, idempotency_key, totals.total)
      create_outbox_event(order)

      cart.cart_items.destroy_all
      cart.update!(seller: nil)
      IdempotencyService.complete!(idempotency_record, resource: order, response_status: 201)
    end

    order
  end

  def validate_cart!(cart, items)
    seller = cart.seller
    raise_invalid(:seller_id) unless seller&.approved?

    items.each do |item|
      product = item.product
      valid = product && product.active? && product.seller_id == seller.id && item.seller_id == seller.id &&
        item.quantity.is_a?(Integer) && item.quantity.between?(1, CartItem::MAX_QUANTITY)
      raise_invalid(:product_id, product_id: item.product_id) unless valid
    end

    seller
  end

  def validate_currency!(items)
    currencies = items.map { |item| item.product.currency }.uniq
    raise_invalid(:currency) unless currencies.one? && currencies.first.match?(/\A[A-Z]{3}\z/)

    currencies.first
  end

  def create_order(customer:, seller:, address:, totals:)
    Order.create!(
      customer: customer,
      seller: seller,
      source_address: address,
      status: "pending",
      currency: totals.currency,
      subtotal_cents: totals.subtotal.cents,
      delivery_fee_cents: totals.delivery_fee.cents,
      discount_cents: totals.discount.cents,
      courier_fee_cents: totals.courier_fee.cents,
      total_cents: totals.total.cents,
      address_name: address.name,
      address_line1: address.line1,
      address_city: address.city,
      address_state: address.state,
      address_zip: address.zip,
      address_country: address.country
    )
  end

  def create_item_snapshots(order, items, currency)
    items.each do |item|
      order.order_items.create!(
        product: item.product,
        seller: order.seller,
        product_name: item.product.name,
        quantity: item.quantity,
        unit_price_cents: item.product.price_cents,
        subtotal_cents: item.product.price_cents * item.quantity,
        currency: currency
      )
    end
  end

  def decrement_inventory(order, items)
    items.each do |item|
      now = Time.current
      affected = InventoryItem
        .where(product_id: item.product_id, seller_id: order.seller_id)
        .where("quantity >= ?", item.quantity)
        .update_all([ "quantity = quantity - ?, updated_at = ?", item.quantity, now ])

      raise_insufficient_inventory(item.product_id) unless affected == 1

      balance = InventoryItem.where(product_id: item.product_id).pick(:quantity)
      order.inventory_movements.create!(
        product: item.product,
        seller: order.seller,
        kind: "checkout_decrement",
        quantity: item.quantity,
        balance_after: balance
      )
    end
  end

  def create_initial_history(order, actor_principal_id, request_id)
    order.order_status_histories.create!(
      from_status: nil,
      to_status: "pending",
      actor_principal_id: actor_principal_id,
      request_id: request_id,
      occurred_at: Time.current
    )
  end

  def create_payment(order, idempotency_key, amount)
    intent = @payment_gateway.create(
      Payments::CreateCommand.new(order_id: order.id, amount: amount, idempotency_key: idempotency_key)
    )
    unless intent.state == "pending" && intent.amount == amount
      raise DomainError.new(code: :external_dependency_unavailable, http_status: :service_unavailable)
    end

    order.create_payment!(
      state: intent.state,
      provider: intent.provider,
      method: intent.method,
      external_reference: intent.external_reference,
      amount_cents: intent.amount.cents,
      currency: intent.amount.currency
    )
  end

  def create_outbox_event(order)
    OutboxEvent.create!(
      event_key: "order:#{order.id}:created",
      event_type: "order.created",
      aggregate_type: "Order",
      aggregate_id: order.id,
      payload: JSON.generate(order_id: order.id, customer_id: order.customer_id, seller_id: order.seller_id),
      state: "pending",
      available_at: Time.current
    )
  end

  def with_sqlite_lock_retry
    attempts = 0
    begin
      yield
    rescue ActiveRecord::StatementTimeout => error
      cause = error.cause
      locked = cause&.class&.name == "SQLite3::BusyException" || error.message.include?("database is locked")
      raise unless locked && attempts < LOCK_RETRY_DELAYS.length

      sleep(LOCK_RETRY_DELAYS.fetch(attempts))
      attempts += 1
      retry
    end
  end

  def raise_invalid(field, context = {})
    raise DomainError.new(
      code: :invalid_input,
      context: { fields: { field => [ I18n.t("errors.messages.invalid") ] } }.merge(context)
    )
  end

  def raise_insufficient_inventory(product_id)
    raise DomainError.new(code: :insufficient_inventory, context: { product_id: product_id })
  end
end

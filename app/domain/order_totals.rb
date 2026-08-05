class OrderTotals
  attr_reader :subtotal, :delivery_fee, :discount, :courier_fee, :total, :currency

  def self.calculate(lines:, currency:, delivery_fee_cents: 0, discount_cents: 0, courier_fee_cents: 0)
    raise ArgumentError, "lines must not be empty" unless lines.is_a?(Array) && lines.any?

    subtotal_cents = lines.sum do |line|
      unit_price = line.fetch(:unit_price_cents)
      quantity = line.fetch(:quantity)
      raise ArgumentError, "quantity must be a positive integer" unless quantity.is_a?(Integer) && quantity.positive?

      Money.new(cents: unit_price, currency: currency)
      line_total = unit_price * quantity
      raise RangeError, "cents overflow" if line_total > Money::MAX_CENTS

      line_total
    end
    raise RangeError, "cents overflow" if subtotal_cents > Money::MAX_CENTS

    new(
      subtotal: Money.new(cents: subtotal_cents, currency: currency),
      delivery_fee: Money.new(cents: delivery_fee_cents, currency: currency),
      discount: Money.new(cents: discount_cents, currency: currency),
      courier_fee: Money.new(cents: courier_fee_cents, currency: currency)
    )
  end

  def initialize(subtotal:, delivery_fee:, discount:, courier_fee:)
    @currency = subtotal.currency
    [ delivery_fee, discount, courier_fee ].each do |amount|
      raise ArgumentError, "currency mismatch" unless amount.currency == currency
    end

    @subtotal = subtotal
    @delivery_fee = delivery_fee
    @discount = discount
    @courier_fee = courier_fee
    @total = subtotal + delivery_fee - discount
    freeze
  end
end

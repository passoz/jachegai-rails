class Money
  MAX_CENTS = (2**63) - 1

  attr_reader :cents, :currency

  def initialize(cents:, currency:)
    raise ArgumentError, "cents must be a non-negative integer" unless cents.is_a?(Integer) && cents >= 0
    raise RangeError, "cents overflow" if cents > MAX_CENTS
    raise ArgumentError, "currency must be an ISO-style uppercase code" unless currency.is_a?(String) && currency.match?(/\A[A-Z]{3}\z/)

    @cents = cents
    @currency = currency
    freeze
  end

  def +(other)
    ensure_same_currency!(other)
    self.class.new(cents: checked_add(cents, other.cents), currency: currency)
  end

  def -(other)
    ensure_same_currency!(other)
    result = cents - other.cents
    raise ArgumentError, "money cannot become negative" if result.negative?

    self.class.new(cents: result, currency: currency)
  end

  def ==(other)
    other.is_a?(Money) && cents == other.cents && currency == other.currency
  end
  alias eql? ==

  def hash
    [ cents, currency ].hash
  end

  private

  def ensure_same_currency!(other)
    raise ArgumentError, "currency mismatch" unless other.is_a?(Money) && other.currency == currency
  end

  def checked_add(left, right)
    result = left + right
    raise RangeError, "cents overflow" if result > MAX_CENTS

    result
  end
end

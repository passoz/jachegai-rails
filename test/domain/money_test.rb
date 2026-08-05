require "test_helper"

class MoneyTest < ActiveSupport::TestCase
  test "adds and subtracts immutable amounts in the same currency" do
    first = Money.new(cents: 1_000, currency: "BRL")
    second = Money.new(cents: 250, currency: "BRL")

    assert_equal Money.new(cents: 1_250, currency: "BRL"), first + second
    assert_equal Money.new(cents: 750, currency: "BRL"), first - second
    assert_equal 1_000, first.cents
    assert first.frozen?
  end

  test "rejects negative, non-integer, invalid currency and overflow" do
    assert_raises(ArgumentError) { Money.new(cents: -1, currency: "BRL") }
    assert_raises(ArgumentError) { Money.new(cents: "1", currency: "BRL") }
    assert_raises(ArgumentError) { Money.new(cents: 1, currency: "brl") }
    assert_raises(RangeError) { Money.new(cents: Money::MAX_CENTS + 1, currency: "BRL") }
  end

  test "rejects currency mismatch and negative subtraction" do
    brl = Money.new(cents: 100, currency: "BRL")

    assert_raises(ArgumentError) { brl + Money.new(cents: 1, currency: "USD") }
    assert_raises(ArgumentError) { brl - Money.new(cents: 101, currency: "BRL") }
  end
end

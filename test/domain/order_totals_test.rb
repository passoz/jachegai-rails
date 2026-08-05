require "test_helper"

class OrderTotalsTest < ActiveSupport::TestCase
  test "calculates authoritative subtotal fees discount courier fee and total" do
    totals = OrderTotals.calculate(
      lines: [ { unit_price_cents: 500, quantity: 2 }, { unit_price_cents: 250, quantity: 1 } ],
      currency: "BRL",
      delivery_fee_cents: 300,
      discount_cents: 50,
      courier_fee_cents: 100
    )

    assert_equal 1_250, totals.subtotal.cents
    assert_equal 300, totals.delivery_fee.cents
    assert_equal 50, totals.discount.cents
    assert_equal 100, totals.courier_fee.cents
    assert_equal 1_500, totals.total.cents
    assert_equal "BRL", totals.currency
    assert totals.frozen?
  end

  test "defaults discount and fees to zero" do
    totals = OrderTotals.calculate(lines: [ { unit_price_cents: 500, quantity: 2 } ], currency: "BRL")

    assert_equal 1_000, totals.subtotal.cents
    assert_equal 0, totals.delivery_fee.cents
    assert_equal 0, totals.discount.cents
    assert_equal 0, totals.courier_fee.cents
    assert_equal 1_000, totals.total.cents
  end

  test "rejects invalid quantity negative total and multiplication overflow" do
    assert_raises(ArgumentError) do
      OrderTotals.calculate(lines: [ { unit_price_cents: 100, quantity: 0 } ], currency: "BRL")
    end
    assert_raises(ArgumentError) do
      OrderTotals.calculate(lines: [ { unit_price_cents: 100, quantity: 1 } ], currency: "BRL", discount_cents: 101)
    end
    assert_raises(RangeError) do
      OrderTotals.calculate(lines: [ { unit_price_cents: Money::MAX_CENTS, quantity: 2 } ], currency: "BRL")
    end
  end
end

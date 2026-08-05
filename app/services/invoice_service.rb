class InvoiceService
  attr_reader :seller, :period_start, :period_end

  def initialize(seller:, period_start:, period_end:)
    @seller = seller
    @period_start = period_start.to_date
    @period_end = period_end.to_date
  end

  def generate!
    existing = Invoice.find_by(seller: seller, period_start: period_start, period_end: period_end)
    return existing if existing.present?

    delivered_orders = Order.where(seller: seller, status: "delivered")
                            .where(created_at: period_start.beginning_of_day..period_end.end_of_day)

    gross_cents = delivered_orders.sum(:subtotal_cents)
    # Standard marketplace fee (e.g. 10% or configured fee)
    fee_percent = (MarketplaceSetting.get("platform_fee_percent") || "10.0").to_f
    fee_cents = (gross_cents * (fee_percent / 100.0)).round
    net_cents = [ gross_cents - fee_cents, 0 ].max

    currency = delivered_orders.first&.currency || "BRL"

    Invoice.create!(
      seller: seller,
      period_start: period_start,
      period_end: period_end,
      gross_amount_cents: gross_cents,
      fee_amount_cents: fee_cents,
      net_amount_cents: net_cents,
      currency: currency,
      state: "pending"
    )
  rescue ActiveRecord::RecordNotUnique
    Invoice.find_by!(seller: seller, period_start: period_start, period_end: period_end)
  end
end

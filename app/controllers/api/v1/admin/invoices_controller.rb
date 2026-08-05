class Api::V1::Admin::InvoicesController < Api::V1::BaseController
  before_action :require_admin!

  def index
    authorize!(Invoice, action: :index)
    scope = Invoice.includes(:seller).order(period_start: :desc, created_at: :desc)
    pagination = paginate(scope)

    render_success(
      data: pagination.records.map { |invoice| serialize_invoice(invoice) },
      meta: pagination.meta
    )
  end

  def show
    invoice = Invoice.includes(:seller).find(params[:id])
    authorize!(invoice, action: :show)

    render_success(data: serialize_invoice(invoice))
  end

  def generate
    return unless parse_payload!(allowed_fields: [ :seller_id, :period_start, :period_end ])
    require_string_field!(:seller_id)
    require_string_field!(:period_start)
    require_string_field!(:period_end)

    authorize!(Invoice, action: :generate)

    seller = Seller.find(@payload[:seller_id])
    invoice = InvoiceService.new(
      seller: seller,
      period_start: @payload[:period_start],
      period_end: @payload[:period_end]
    ).generate!

    AuditRecord.record!(
      actor: Current.principal&.user || current_user,
      action: "generate_invoice",
      resource_type: "Invoice",
      resource_id: invoice.id,
      result: "success",
      request_id: Current.request_id
    )

    render_success(data: serialize_invoice(invoice), status: :created)
  end

  private

  def serialize_invoice(invoice)
    {
      id: invoice.id,
      seller_id: invoice.seller_id,
      period_start: invoice.period_start.to_s,
      period_end: invoice.period_end.to_s,
      gross_amount_cents: invoice.gross_amount_cents,
      fee_amount_cents: invoice.fee_amount_cents,
      net_amount_cents: invoice.net_amount_cents,
      currency: invoice.currency,
      state: invoice.state,
      paid_at: invoice.paid_at&.iso8601,
      created_at: invoice.created_at.iso8601,
      updated_at: invoice.updated_at.iso8601
    }
  end
end

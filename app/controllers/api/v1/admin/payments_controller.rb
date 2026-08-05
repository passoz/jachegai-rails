class Api::V1::Admin::PaymentsController < Api::V1::BaseController
  before_action :require_admin!

  def index
    authorize!(Payment, action: :index)
    scope = Payment.includes(:order).order(created_at: :desc, id: :desc)
    pagination = paginate(scope)

    render_success(
      data: pagination.records.map { |payment| serialize_payment(payment) },
      meta: pagination.meta
    )
  end

  def show
    payment = Payment.includes(:order).find(params[:id])
    authorize!(payment, action: :show)

    render_success(data: serialize_payment(payment))
  end

  def confirm
    payment = Payment.find(params[:id])
    authorize!(payment, action: :confirm)

    PaymentConfirmationService.new(payment, actor: Current.principal).confirm_payment!

    render_success(data: {
      state: payment.state,
      amount_cents: payment.amount_cents,
      currency: payment.currency,
      updated_at: payment.updated_at
    })
  end

  private

  def serialize_payment(payment)
    {
      id: payment.id,
      order_id: payment.order_id,
      state: payment.state,
      amount_cents: payment.amount_cents,
      currency: payment.currency,
      provider: payment.provider,
      provider_payment_id: payment.external_reference,
      created_at: payment.created_at.iso8601,
      updated_at: payment.updated_at.iso8601
    }
  end
end

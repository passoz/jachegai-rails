class Api::V1::Customer::TicketsController < Api::V1::BaseController
  before_action :require_customer!

  def index
    tickets = current_customer.tickets.order(created_at: :desc, id: :desc).includes(:ticket_messages)
    render_success(data: tickets.map { |ticket| TicketSerializer.as_json(ticket, include_messages: false) })
  end

  def show
    ticket = current_customer.tickets.includes(:ticket_messages).find(params[:id])
    render_success(data: TicketSerializer.as_json(ticket))
  end

  def create
    return unless parse_payload!(allowed_fields: [ :subject, :initial_message, :order_id ])
    require_string_field!(:subject)
    require_string_field!(:initial_message)
    require_string_field!(:order_id, allow_nil: true)

    ticket = TicketService.new(Current.principal).create_ticket(
      subject: @payload[:subject],
      initial_message: @payload[:initial_message],
      order_id: @payload[:order_id]
    )

    render_success(data: TicketSerializer.as_json(ticket.reload), status: :created)
  end

  def create_message
    return unless parse_payload!(allowed_fields: [ :body ])
    require_string_field!(:body)

    message = TicketService.new(Current.principal).add_customer_message(ticket_id: params[:id], body: @payload[:body])
    render_success(data: TicketSerializer.message_as_json(message), status: :created)
  end

  private

  def require_customer!
    raise Forbidden unless Current.principal&.has_role?(:customer)
  end

  def current_customer
    customer = Current.principal.user.customer
    raise ActiveRecord::RecordNotFound, "Customer profile not found" unless customer

    customer
  end
end

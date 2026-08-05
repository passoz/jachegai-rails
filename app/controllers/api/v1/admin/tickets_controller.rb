class Api::V1::Admin::TicketsController < Api::V1::BaseController
  before_action :require_admin!

  def index
    tickets = Ticket.order(created_at: :desc, id: :desc).includes(:ticket_messages)
    render_success(data: tickets.map { |ticket| TicketSerializer.as_json(ticket, include_messages: false) })
  end

  def show
    ticket = Ticket.includes(:ticket_messages).find(params[:id])
    render_success(data: TicketSerializer.as_json(ticket))
  end

  def create_message
    return unless parse_payload!(allowed_fields: [ :body ])
    require_string_field!(:body)

    message = AdminTicketService.new(Current.principal).add_message(ticket_id: params[:id], body: @payload[:body])
    render_success(data: TicketSerializer.message_as_json(message), status: :created)
  end

  def start_progress
    transition(:start_progress)
  end

  def resolve
    transition(:resolve)
  end

  def reopen
    transition(:reopen)
  end

  def close
    transition(:close)
  end

  private

  def transition(action)
    ticket = AdminTicketService.new(Current.principal).transition(ticket_id: params[:id], action: action)
    render_success(data: TicketSerializer.as_json(ticket, include_messages: false))
  end
end

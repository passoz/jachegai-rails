class OutboxDispatchJob < ApplicationJob
  queue_as :default

  BATCH_SIZE = 100

  def perform
    processor = OutboxProcessor.new(handlers: handlers)
    OutboxEvent
      .where(state: [ "pending", "processing" ])
      .where("available_at <= ?", Time.current)
      .order(:available_at, :id)
      .limit(BATCH_SIZE)
      .pluck(:id)
      .each { |event_id| processor.process(event_id) }
  end

  private

  def handlers
    {
      "order.created" => ->(event, payload) {
        Rails.logger.info(
          {
            event: "outbox_order_created_consumed",
            outbox_event_id: event.id,
            order_id: payload.fetch("order_id")
          }.to_json
        )
      },
      "payment.confirmed" => ->(event, payload) {
        Rails.logger.info(
          {
            event: "outbox_payment_confirmed_consumed",
            outbox_event_id: event.id,
            payment_id: payload.fetch("payment_id"),
            order_id: payload.fetch("order_id"),
            state: payload.fetch("state")
          }.to_json
        )
      }
    }
  end
end

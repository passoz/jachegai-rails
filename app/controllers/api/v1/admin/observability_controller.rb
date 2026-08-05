class Api::V1::Admin::ObservabilityController < Api::V1::BaseController
  before_action :require_admin!

  def summary
    authorize!(:observability, action: :summary)
    render_success(data: {
      system: {
        environment: Rails.env,
        db_adapter: ActiveRecord::Base.connection.adapter_name,
        time: Time.current.iso8601
      },
      outbox: {
        pending_events: OutboxEvent.where(completed_at: nil).count,
        failed_events: OutboxEvent.where.not(last_error: nil).count,
        dead_letter_events: OutboxEvent.where(state: "dead_letter").count
      }
    })
  end

  def requests
    authorize!(:observability, action: :requests)
    render_success(data: {
      total_sessions: Session.active.count,
      audit_records_count: AuditRecord.count
    })
  end

  def orders
    authorize!(:observability, action: :orders)
    render_success(data: {
      active_orders_count: Order.where.not(status: [ "delivered", "cancelled" ]).count,
      pending_payment_count: Payment.where(state: "pending").count
    })
  end

  def jobs
    authorize!(:observability, action: :jobs)
    oldest = OutboxEvent.where(completed_at: nil).minimum(:created_at)
    oldest_seconds = oldest ? (Time.current - oldest.to_time).to_i : 0

    render_success(data: {
      outbox_backlog: OutboxEvent.where(completed_at: nil).count,
      oldest_unprocessed_seconds: oldest_seconds
    })
  end
end

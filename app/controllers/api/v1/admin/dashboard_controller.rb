class Api::V1::Admin::DashboardController < Api::V1::BaseController
  before_action :require_admin!

  def show
    authorize!(:dashboard, action: :show)

    metrics = {
      users: {
        total: User.count,
        active: User.where(disabled_at: nil).count,
        disabled: User.where.not(disabled_at: nil).count
      },
      sellers: {
        total: Seller.count,
        pending: Seller.where(moderation_state: "pending").count,
        approved: Seller.where(moderation_state: "approved").count,
        rejected: Seller.where(moderation_state: "rejected").count,
        suspended: Seller.where(moderation_state: "suspended").count
      },
      couriers: {
        total: Courier.count,
        pending: Courier.where(moderation_state: "pending").count,
        approved: Courier.where(moderation_state: "approved").count,
        suspended: Courier.where(moderation_state: "suspended").count,
        available: Courier.where(operational_state: "available").count
      },
      orders: {
        total: Order.count,
        by_status: Order.group(:status).count
      },
      tickets: {
        total: Ticket.count,
        by_state: Ticket.group(:state).count
      },
      payments: {
        total: Payment.count,
        by_state: Payment.group(:state).count
      }
    }

    render_success(data: metrics)
  end
end

class PendingPaymentExpirationJob < ApplicationJob
  queue_as :default

  class SystemPrincipal
    def admin?
      false
    end

    def system?
      true
    end

    def has_role?(role)
      false
    end

    def user
      nil
    end
  end

  def perform
    # Busca pedidos com status pending com mais de 30 minutos
    cutoff = 30.minutes.ago
    orders = Order.where(status: "pending").where("created_at <= ?", cutoff)

    actor = SystemPrincipal.new

    orders.find_each do |order|
      # Verifica se o pagamento está pendente (se for pago, não expira)
      payment = order.payment
      next if payment.nil? || payment.state != "pending"

      begin
        OrderTransitionService.new(order, actor: actor).transition_to!(
          "cancelled",
          reason: "payment_expired"
        )
      rescue => e
        # Loga falha individual para que outros pedidos continuem
        Rails.logger.error("Failed to expire order #{order.id}: #{e.message}")
      end
    end
  end
end

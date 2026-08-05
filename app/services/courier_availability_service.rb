class CourierAvailabilityService
  ACTIVE_ORDER_STATES = %w[assigned picked_up].freeze
  TARGET_STATES = %w[available offline].freeze

  def initialize(principal)
    @principal = principal
  end

  def set_availability!(state:)
    unless @principal&.has_role?("courier")
      raise DomainError.new(code: :forbidden, message: "Forbidden", http_status: :forbidden)
    end

    target_state = state.to_s.strip
    unless TARGET_STATES.include?(target_state)
      raise DomainError.new(
        code: :invalid_input,
        message: "Invalid operational state. Allowed: available, offline",
        http_status: :unprocessable_content
      )
    end

    Courier.transaction do
      courier = Courier.lock.find_by(user_id: @principal.user.id)
      unless courier
        raise DomainError.new(code: :not_found, message: "Courier profile not found", http_status: :not_found)
      end

      if target_state == "available" && !courier.approved?
        raise DomainError.new(
          code: :courier_not_approved,
          message: "Only approved couriers can become available",
          http_status: :unprocessable_content
        )
      end

      active_delivery = Order.where(courier_id: courier.id, status: ACTIVE_ORDER_STATES).exists?
      if active_delivery || (target_state == "offline" && courier.on_delivery?)
        raise DomainError.new(
          code: :active_delivery_in_progress,
          message: "Cannot switch to offline while active delivery is in progress",
          http_status: :conflict
        )
      end

      courier.update!(operational_state: target_state)
      courier
    end
  end
end

class CourierLocationService
  ACTIVE_ORDER_STATES = %w[assigned picked_up].freeze

  def initialize(principal)
    @principal = principal
  end

  def record_location!(latitude:, longitude:, accuracy_meters: nil)
    unless @principal&.has_role?("courier")
      raise DomainError.new(code: :forbidden, message: "Forbidden", http_status: :forbidden)
    end

    courier = @principal.user.courier
    unless courier
      raise DomainError.new(code: :not_found, message: "Courier profile not found", http_status: :not_found)
    end

    unless courier.location_consent_given_at.present?
      raise DomainError.new(
        code: :location_consent_required,
        message: "Location consent must be given before publishing location",
        http_status: :unprocessable_content
      )
    end

    has_active_delivery = Order.where(courier_id: courier.id, status: ACTIVE_ORDER_STATES).exists?
    unless has_active_delivery
      raise DomainError.new(
        code: :active_delivery_required,
        message: "Location can only be published during an active delivery",
        http_status: :conflict
      )
    end

    last_location = CourierLocation.where(courier_id: courier.id).order(recorded_at: :desc).first
    if last_location && last_location.recorded_at > 5.seconds.ago
      raise DomainError.new(
        code: :rate_limited,
        message: "Location updates must be at least 5 seconds apart",
        http_status: :too_many_requests
      )
    end

    location = CourierLocation.new(
      courier: courier,
      latitude: latitude,
      longitude: longitude,
      accuracy_meters: accuracy_meters,
      recorded_at: Time.current
    )

    unless location.save
      raise DomainError.new(
        code: :invalid_input,
        message: location.errors.full_messages.join(", "),
        http_status: :unprocessable_content,
        context: { fields: location.errors.to_hash }
      )
    end

    location
  end
end

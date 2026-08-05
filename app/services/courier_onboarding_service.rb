class CourierOnboardingService
  def initialize(principal)
    @principal = principal
  end

  def onboard!(payload)
    unless @principal.has_role?("courier")
      raise DomainError.new(
        code: :forbidden,
        message: "Forbidden",
        http_status: :forbidden
      )
    end

    if @principal.user.courier.present?
      raise DomainError.new(
        code: :courier_already_exists,
        message: "Courier profile already exists for this user",
        http_status: :unprocessable_content
      )
    end

    consent_at = payload[:location_consent] == true ? Time.current : nil

    courier = Courier.new(
      user: @principal.user,
      phone: payload[:phone],
      document_number: payload[:document_number],
      vehicle_type: payload[:vehicle_type],
      vehicle_plate: payload[:vehicle_plate],
      location_consent_given_at: consent_at
    )

    unless courier.save
      raise DomainError.new(
        code: :invalid_input,
        message: courier.errors.full_messages.join(", "),
        http_status: :unprocessable_content,
        context: { fields: courier.errors.to_hash }
      )
    end

    courier
  end
end

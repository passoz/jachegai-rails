class CourierSerializer
  def self.render(courier)
    {
      id: courier.id,
      user_id: courier.user_id,
      phone: courier.phone,
      document_number: courier.document_number,
      vehicle_type: courier.vehicle_type,
      vehicle_plate: courier.vehicle_plate,
      moderation_state: courier.moderation_state,
      operational_state: courier.operational_state,
      location_consent_given_at: courier.location_consent_given_at&.iso8601,
      created_at: courier.created_at.iso8601,
      updated_at: courier.updated_at.iso8601
    }
  end
end

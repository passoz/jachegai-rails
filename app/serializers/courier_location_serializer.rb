class CourierLocationSerializer
  def self.render(location)
    {
      id: location.id,
      courier_id: location.courier_id,
      latitude: location.latitude,
      longitude: location.longitude,
      accuracy_meters: location.accuracy_meters,
      recorded_at: location.recorded_at.iso8601,
      created_at: location.created_at.iso8601
    }
  end
end

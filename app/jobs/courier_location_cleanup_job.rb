class CourierLocationCleanupJob < ApplicationJob
  queue_as :default

  RETENTION_WINDOW = 24.hours

  def perform
    threshold = RETENTION_WINDOW.ago
    deleted_count = CourierLocation.where("recorded_at < ?", threshold).delete_all

    Rails.logger.info({ event: "courier_location_cleanup", deleted_count: deleted_count, threshold: threshold.iso8601 }.to_json)
    deleted_count
  end
end

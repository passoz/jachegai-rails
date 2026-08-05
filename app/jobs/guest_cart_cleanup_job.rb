class GuestCartCleanupJob < ApplicationJob
  queue_as :default

  def perform
    GuestCart.where("expires_at <= ?", Time.current).find_in_batches(batch_size: 500) do |batch|
      GuestCart.where(id: batch.map(&:id)).destroy_all
    end
  end
end

module ServerGeneratedId
  extend ActiveSupport::Concern

  included do
    self.primary_key = "id"
    before_create :set_server_generated_id
  end

  private

  def set_server_generated_id
    self.id ||= ApplicationId.generate
  end
end

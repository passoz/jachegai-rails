class Current < ActiveSupport::CurrentAttributes
  attribute :request_id
  attribute :principal
  attribute :user_agent
  attribute :remote_ip
end

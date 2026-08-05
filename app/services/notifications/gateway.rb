module Notifications
  # Provider-neutral notifications gateway contract.
  # Adapters (SMTP, push, SMS) implement #send_message and translate provider
  # exceptions into DomainError so they never leak to domain/API.
  class Gateway
    def send_message(_command)
      raise NotImplementedError
    end
  end
end

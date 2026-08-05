module Notifications
  # Validated input command for sending a notification.
  SendCommand = Data.define(:channel, :recipient, :template, :locale) do
    def initialize(channel:, recipient:, template:, locale:)
      raise ArgumentError, "channel is required" if channel.blank?
      raise ArgumentError, "recipient is required" if recipient.blank?
      raise ArgumentError, "template is required" if template.blank?
      raise ArgumentError, "locale is required" if locale.blank?

      super
    end
  end
end

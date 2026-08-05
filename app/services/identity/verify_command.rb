module Identity
  # Validated input command for identity verification.
  VerifyCommand = Data.define(:token) do
    def initialize(token:)
      raise ArgumentError, "token is required" if token.blank?

      super
    end
  end
end

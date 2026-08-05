class ApplicationId
  def self.generate
    SecureRandom.uuid_v7
  end
end

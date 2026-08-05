module Storage
  # Provider-neutral storage gateway contract.
  # Adapters (Disk, S3, GCS) implement #store and translate provider
  # exceptions into DomainError so they never leak to domain/API.
  class Gateway
    def store(_command)
      raise NotImplementedError
    end
  end
end

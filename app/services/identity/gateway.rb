module Identity
  # Provider-neutral identity gateway contract.
  # Adapters (local JWT, OAuth2, Keycloak) implement #verify and translate
  # provider exceptions into DomainError so they never leak to domain/API.
  class Gateway
    def verify(_command)
      raise NotImplementedError
    end
  end
end

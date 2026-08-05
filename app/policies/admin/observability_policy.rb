module Admin
  class ObservabilityPolicy < BasePolicy
    def summary?
      admin?
    end

    def requests?
      admin?
    end

    def orders?
      admin?
    end

    def jobs?
      admin?
    end
  end
end

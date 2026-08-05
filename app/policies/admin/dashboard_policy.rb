module Admin
  class DashboardPolicy < BasePolicy
    def show?
      admin?
    end
  end
end

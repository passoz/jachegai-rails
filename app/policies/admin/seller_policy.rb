module Admin
  # Admin::SellerPolicy governs admin moderation endpoints. Only admin
  # principals can list, inspect, and moderate sellers.
  class SellerPolicy < BasePolicy
    def index?
      admin?
    end

    def show?
      admin?
    end

    def approve?
      admin?
    end

    def reject?
      admin?
    end

    def suspend?
      admin?
    end

    def reinstate?
      admin?
    end
  end
end

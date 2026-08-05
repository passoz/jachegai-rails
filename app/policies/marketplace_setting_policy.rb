class MarketplaceSettingPolicy < BasePolicy
  def index?
    admin?
  end

  def create?
    admin?
  end
end

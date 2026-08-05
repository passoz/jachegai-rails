class PaymentPolicy < BasePolicy
  def index?
    admin?
  end

  def show?
    admin?
  end

  def confirm?
    admin?
  end
end

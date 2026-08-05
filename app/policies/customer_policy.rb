class CustomerPolicy < BasePolicy
  def show?
    owner?
  end

  def update?
    owner?
  end

  private

  def owner?
    principal&.has_role?(:customer) && principal.user.customer&.id == record&.id
  end
end

class UserPolicy < BasePolicy
  def index?
    admin?
  end

  def show?
    admin? || owner?
  end

  def disable?
    admin?
  end

  def enable?
    admin?
  end

  private

  def owner?
    principal&.user_id.present? && record.is_a?(User) && principal.user_id == record.id
  end
end

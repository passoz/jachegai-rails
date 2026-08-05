# BasePolicy defines the authorization contract for all resources.
# Subclasses override permission checks.
class BasePolicy
  attr_reader :principal, :record

  def initialize(principal, record = nil)
    @principal = principal
    @record = record
  end

  # Reads require authentication. Writes deny by default so a missing policy
  # cannot accidentally authorize a protected mutation.
  def index?
    authenticated?
  end

  def show?
    authenticated?
  end

  def create?
    false
  end

  def update?
    false
  end

  def destroy?
    false
  end

  # Admin-only shortcuts
  def admin?
    principal&.admin?
  end

  private

  def authenticated?
    principal.present?
  end
end

# Test policy: only sellers can create test records.
class TestApiPolicy < BasePolicy
  def create?
    principal&.has_role?(:seller)
  end
end

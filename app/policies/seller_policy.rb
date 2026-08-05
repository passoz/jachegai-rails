# SellerPolicy governs access to a seller profile. Only members of the
# seller can read or update its profile.
class SellerPolicy < BasePolicy
  def show?
    member?
  end

  def update?
    member?
  end

  private

  def member?
    principal&.member_of_seller?(record.id)
  end
end

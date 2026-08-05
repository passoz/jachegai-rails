# InventoryPolicy governs seller inventory. Mutations are scoped to the
# current seller, so the policy only needs to confirm membership.
class InventoryPolicy < BasePolicy
  def index?
    seller_member?
  end

  def update?
    seller_member? && principal&.seller&.approved?
  end

  private

  def seller_member?
    return principal&.seller.present? if record.nil?

    principal&.member_of_seller?(record.seller_id)
  end
end

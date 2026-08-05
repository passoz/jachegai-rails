# ProductPolicy governs seller-owned products. Mutations are additionally
# scoped to the current seller, so the policy only needs to confirm membership.
class ProductPolicy < BasePolicy
  def index?
    seller_member?
  end

  def show?
    seller_member?
  end

  def create?
    operational_seller_member?
  end

  def update?
    operational_seller_member?
  end

  def destroy?
    operational_seller_member?
  end

  def activate?
    operational_seller_member?
  end

  def deactivate?
    operational_seller_member?
  end

  private

  def seller_member?
    return principal&.seller.present? if record.nil?

    principal&.member_of_seller?(record.seller_id)
  end

  def operational_seller_member?
    seller = record&.seller || principal&.seller
    seller_member? && seller&.approved?
  end
end

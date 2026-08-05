class OrderPolicy < BasePolicy
  def index?
    admin?
  end

  def show?
    admin? || owner_customer? || seller_member? || assigned_courier?
  end

  def cancel?
    admin? || owner_customer?
  end

  private

  def owner_customer?
    principal&.customer_id.present? && record.is_a?(Order) && principal.customer_id == record.customer_id
  end

  def seller_member?
    principal&.user_id.present? && record.is_a?(Order) && principal.user.member_of_seller?(record.seller_id)
  end

  def assigned_courier?
    principal&.courier_id.present? && record.is_a?(Order) && principal.courier_id == record.courier_id
  end
end

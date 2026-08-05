class InvoicePolicy < BasePolicy
  def index?
    admin?
  end

  def show?
    admin? || seller_member?
  end

  def generate?
    admin?
  end

  private

  def seller_member?
    principal&.user_id.present? && record.is_a?(Invoice) && principal.user.member_of_seller?(record.seller_id)
  end
end

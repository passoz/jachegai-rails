class UploadPolicy < BasePolicy
  def create?
    principal.present? && owner_authorized?
  end

  def index?
    principal.present? && owner_authorized?
  end

  private

  def owner_authorized?
    record = context_record
    return false if record.nil?

    case record
    when Seller
      principal.admin? || principal.user&.member_of_seller?(record.id)
    when Product
      principal.admin? || principal.user&.member_of_seller?(record.seller_id)
    else
      false
    end
  end

  def context_record
    record.is_a?(Class) ? nil : record
  end
end

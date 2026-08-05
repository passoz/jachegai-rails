# Principal represents the authenticated actor for the current request.
class Principal
  attr_reader :user, :session

  def initialize(user:, session: nil)
    @user = user
    @session = session
  end

  def id
    user.id
  end

  def roles
    user.roles
  end

  def admin?
    user.admin?
  end

  def system?
    false
  end

  def has_role?(role)
    user.has_role?(role)
  end

  def seller
    user.seller
  end

  def seller_ids
    user.seller_ids
  end

  def member_of_seller?(seller_id)
    user.member_of_seller?(seller_id)
  end

  def active?
    user.active?
  end
end

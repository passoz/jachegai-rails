class FavoriteService
  def self.add(customer:, seller_id:)
    seller = Seller.approved.find_by(id: seller_id)
    unless seller
      raise DomainError.new(
        code: :invalid_input,
        http_status: :unprocessable_content,
        context: { fields: { seller_id: [ I18n.t("errors.messages.invalid") ] } }
      )
    end

    existing = customer.favorites.find_by(seller: seller)
    return existing if existing

    customer.favorites.create!(seller: seller)
  rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
    customer.favorites.find_by(seller: seller) || raise
  end

  def self.remove(customer:, seller_id:)
    favorite = customer.favorites.find_by(seller_id: seller_id)
    raise ActiveRecord::RecordNotFound unless favorite

    favorite.destroy!
  end
end

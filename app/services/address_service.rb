class AddressService
  ALLOWED_PARAMS = %i[name line1 city state zip country is_default].freeze

  def self.create(customer:, params:)
    attributes = params.slice(*ALLOWED_PARAMS)

    customer.with_lock do
      attributes[:is_default] = true if customer.addresses.empty?
      customer.addresses.create!(attributes)
    end
  end

  def self.update(address:, params:)
    customer = address.customer
    attributes = params.slice(*ALLOWED_PARAMS)

    customer.with_lock do
      if address.is_default? && attributes[:is_default] == false
        replacement = replacement_for(customer, excluding: address)
        address.update!(attributes.except(:is_default))
        replacement&.update!(is_default: true)
      else
        address.update!(attributes)
      end
    end

    address.reload
  end

  def self.make_default(address:)
    address.customer.with_lock { address.update!(is_default: true) }
    address.reload
  end

  def self.destroy(address:)
    customer = address.customer

    customer.with_lock do
      was_default = address.is_default?
      address.destroy!
      replacement_for(customer)&.update!(is_default: true) if was_default
    end
  end

  def self.replacement_for(customer, excluding: nil)
    scope = customer.addresses
    scope = scope.where.not(id: excluding.id) if excluding
    scope.order(created_at: :desc, id: :desc).first
  end
  private_class_method :replacement_for
end

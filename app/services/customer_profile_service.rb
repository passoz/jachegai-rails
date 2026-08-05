class CustomerProfileService
  ALLOWED_PARAMS = %i[full_name email phone].freeze

  def self.update(customer:, params:)
    attributes = params.slice(*ALLOWED_PARAMS)

    ActiveRecord::Base.transaction do
      customer.user.update!(email: attributes[:email], full_name: attributes[:full_name])
      customer.update!(attributes.slice(:full_name, :phone))
    end

    customer.reload
  end
end

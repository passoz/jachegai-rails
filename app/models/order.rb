class Order < ApplicationRecord
  include ServerGeneratedId

  STATUSES = %w[pending accepted rejected preparing ready assigned picked_up delivered cancelled].freeze
  SNAPSHOT_ATTRIBUTES = %i[
    customer_id seller_id source_address_id currency subtotal_cents delivery_fee_cents discount_cents
    courier_fee_cents total_cents address_name address_line1 address_city address_state address_zip address_country
  ].freeze

  attr_readonly(*SNAPSHOT_ATTRIBUTES)

  belongs_to :customer
  belongs_to :seller
  belongs_to :courier, optional: true
  belongs_to :source_address, class_name: "Address", optional: true
  has_many :order_items, dependent: :restrict_with_error
  has_many :order_status_histories, dependent: :restrict_with_error
  has_many :inventory_movements, dependent: :restrict_with_error
  has_one :payment, dependent: :restrict_with_error

  validates :status, inclusion: { in: STATUSES }
  validates :currency, presence: true, format: { with: /\A[A-Z]{3}\z/ }
  validates :subtotal_cents, :delivery_fee_cents, :discount_cents, :courier_fee_cents, :total_cents,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :address_name, :address_line1, :address_city, :address_state, :address_zip, :address_country, presence: true
  validate :total_is_consistent
  validate :courier_has_at_most_one_active_order

  private

  def courier_has_at_most_one_active_order
    return unless has_attribute?(:courier_id)
    return if courier_id.blank? || !%w[assigned picked_up].include?(status)

    active_scope = Order.where(courier_id: courier_id, status: %w[assigned picked_up]).where.not(id: id)
    errors.add(:courier_id, "already has an active delivery") if active_scope.exists?
  end

  def total_is_consistent
    amounts = [ subtotal_cents, delivery_fee_cents, discount_cents, total_cents ]
    return unless amounts.all? { |amount| amount.is_a?(Integer) }

    expected = subtotal_cents + delivery_fee_cents - discount_cents
    errors.add(:total_cents, "must match authoritative components") unless total_cents == expected
  end
end

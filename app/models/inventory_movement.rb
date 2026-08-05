class InventoryMovement < ApplicationRecord
  include ServerGeneratedId
  include AppendOnlyRecord

  KINDS = %w[checkout_decrement restore].freeze

  belongs_to :order
  belongs_to :product
  belongs_to :seller

  validates :kind, inclusion: { in: KINDS }
  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :balance_after, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :kind, uniqueness: { scope: [ :order_id, :product_id ] }
end

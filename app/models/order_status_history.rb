class OrderStatusHistory < ApplicationRecord
  include ServerGeneratedId
  include AppendOnlyRecord

  belongs_to :order

  validates :to_status, inclusion: { in: Order::STATUSES }
  validates :from_status, inclusion: { in: Order::STATUSES }, allow_nil: true
  validates :actor_principal_id, :occurred_at, presence: true
end

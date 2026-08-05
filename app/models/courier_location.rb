class CourierLocation < ApplicationRecord
  include ServerGeneratedId

  belongs_to :courier

  validates :latitude, presence: true, numericality: { greater_than_or_equal_to: -90.0, less_than_or_equal_to: 90.0 }
  validates :longitude, presence: true, numericality: { greater_than_or_equal_to: -180.0, less_than_or_equal_to: 180.0 }
  validates :recorded_at, presence: true
end

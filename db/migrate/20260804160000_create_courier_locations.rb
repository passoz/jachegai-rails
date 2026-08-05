class CreateCourierLocations < ActiveRecord::Migration[8.1]
  def change
    create_table :courier_locations, id: :string, primary_key: :id do |t|
      t.string :courier_id, null: false
      t.float :latitude, null: false
      t.float :longitude, null: false
      t.float :accuracy_meters
      t.datetime :recorded_at, null: false

      t.timestamps
    end

    add_index :courier_locations, [ :courier_id, :recorded_at ], name: "index_courier_locations_on_courier_and_recorded_at"
    add_foreign_key :courier_locations, :couriers, column: :courier_id

    add_check_constraint :courier_locations,
      "latitude >= -90.0 AND latitude <= 90.0 AND longitude >= -180.0 AND longitude <= 180.0",
      name: "courier_locations_coordinates_check"
  end
end

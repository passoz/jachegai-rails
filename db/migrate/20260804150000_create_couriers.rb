class CreateCouriers < ActiveRecord::Migration[8.1]
  def change
    create_table :couriers, id: :string, primary_key: :id do |t|
      t.string :user_id, null: false
      t.string :phone, null: false
      t.string :document_number, null: false
      t.string :vehicle_type, null: false
      t.string :vehicle_plate
      t.string :moderation_state, null: false, default: "pending_review"
      t.string :operational_state, null: false, default: "offline"
      t.datetime :location_consent_given_at

      t.timestamps
    end

    add_index :couriers, :user_id, unique: true
    add_index :couriers, :document_number, unique: true
    add_foreign_key :couriers, :users, column: :user_id

    add_check_constraint :couriers,
      "moderation_state IN ('pending_review', 'approved', 'rejected', 'suspended')",
      name: "couriers_moderation_state_check"

    add_check_constraint :couriers,
      "operational_state IN ('offline', 'available', 'on_delivery')",
      name: "couriers_operational_state_check"

    add_check_constraint :couriers,
      "vehicle_type IN ('motorcycle', 'bicycle', 'car', 'foot')",
      name: "couriers_vehicle_type_check"
  end
end

class EnforceCourierStateConsistency < ActiveRecord::Migration[8.1]
  def change
    add_check_constraint :couriers,
      "moderation_state = 'approved' OR operational_state = 'offline'",
      name: "couriers_unapproved_must_be_offline"
  end
end

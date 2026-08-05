class CreateRoleAssignments < ActiveRecord::Migration[8.1]
  def change
    create_table :role_assignments, id: :string, primary_key: :id do |t|
      t.references :user, type: :string, null: false, foreign_key: true
      t.string :role, null: false
      t.timestamps
    end

    add_index :role_assignments, [ :user_id, :role ], unique: true
  end
end

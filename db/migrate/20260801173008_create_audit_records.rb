class CreateAuditRecords < ActiveRecord::Migration[8.1]
  def change
    create_table :audit_records, id: :string, primary_key: :id do |t|
      t.string :actor_principal_id, null: false
      t.string :action, null: false
      t.string :resource_type, null: false
      t.string :resource_id, null: false
      t.string :result, null: false, default: "success"
      t.string :reason
      t.string :correlation_id
      t.text :metadata
      t.timestamps
    end

    add_index :audit_records, [ :resource_type, :resource_id ]
    add_index :audit_records, :actor_principal_id
    add_index :audit_records, :correlation_id
  end
end

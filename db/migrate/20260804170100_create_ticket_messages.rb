class CreateTicketMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :ticket_messages, id: false do |t|
      t.string :id, null: false, primary_key: true
      t.references :ticket, null: false, type: :string, foreign_key: true
      t.references :sender, null: false, type: :string, foreign_key: { to_table: :users }
      t.string :sender_role, null: false
      t.text :body, null: false
      t.timestamps null: false
    end

    add_index :ticket_messages, [ :ticket_id, :created_at, :id ]
    add_index :ticket_messages, [ :sender_id, :created_at, :id ]

    add_check_constraint :ticket_messages,
                         "sender_role IN ('customer', 'admin')",
                         name: "ticket_messages_sender_role_allowed"
  end
end

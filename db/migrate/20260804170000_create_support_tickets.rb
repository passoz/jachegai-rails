class CreateSupportTickets < ActiveRecord::Migration[8.1]
  def change
    create_table :tickets, id: false do |t|
      t.string :id, null: false, primary_key: true
      t.references :customer, null: false, type: :string, foreign_key: true
      t.references :order, null: true, type: :string, foreign_key: true
      t.string :subject, null: false
      t.string :state, null: false, default: "open"
      t.timestamps null: false
    end

    add_index :tickets, [ :customer_id, :created_at, :id ]
    add_index :tickets, :state

    add_check_constraint :tickets,
                         "state IN ('open', 'in_progress', 'resolved', 'closed')",
                         name: "tickets_state_allowed"
  end
end

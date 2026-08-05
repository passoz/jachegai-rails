class CreateInvoices < ActiveRecord::Migration[8.1]
  def change
    create_table :invoices, id: :string do |t|
      t.string :seller_id, null: false
      t.date :period_start, null: false
      t.date :period_end, null: false
      t.integer :gross_amount_cents, null: false, default: 0
      t.integer :fee_amount_cents, null: false, default: 0
      t.integer :net_amount_cents, null: false, default: 0
      t.string :currency, null: false, default: "BRL"
      t.string :state, null: false, default: "pending"
      t.datetime :paid_at

      t.timestamps
    end

    add_index :invoices, [ :seller_id, :period_start, :period_end ], unique: true, name: "idx_invoices_seller_period"
    add_foreign_key :invoices, :sellers, column: :seller_id
  end
end

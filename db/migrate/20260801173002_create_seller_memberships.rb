class CreateSellerMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :seller_memberships, id: :string, primary_key: :id do |t|
      t.references :seller, type: :string, null: false, foreign_key: true
      t.references :user, type: :string, null: false, foreign_key: true
      t.string :role, null: false, default: "owner"
      t.timestamps
    end

    add_index :seller_memberships, [ :seller_id, :user_id ], unique: true
  end
end

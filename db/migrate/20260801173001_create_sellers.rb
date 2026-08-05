class CreateSellers < ActiveRecord::Migration[8.1]
  def change
    create_table :sellers, id: :string, primary_key: :id do |t|
      t.string :slug, null: false
      t.string :name, null: false
      t.text :description
      t.string :contact_email
      t.string :contact_phone
      t.string :address_line1
      t.string :address_city
      t.string :address_state
      t.string :address_zip
      t.string :address_country, null: false, default: "BR"
      t.string :moderation_state, null: false, default: "pending_review"
      t.datetime :moderated_at
      t.timestamps
    end

    add_index :sellers, :slug, unique: true
    add_index :sellers, :moderation_state
  end
end

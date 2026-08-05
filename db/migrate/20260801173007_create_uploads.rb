class CreateUploads < ActiveRecord::Migration[8.1]
  def change
    create_table :uploads, id: :string, primary_key: :id do |t|
      t.references :owner, type: :string, polymorphic: true, null: false, index: false
      t.string :storage_key, null: false
      t.string :filename, null: false
      t.string :content_type, null: false
      t.integer :byte_size, null: false, default: 0
      t.timestamps
    end

    add_index :uploads, :storage_key, unique: true
    add_index :uploads, [ :owner_type, :owner_id ]
  end
end

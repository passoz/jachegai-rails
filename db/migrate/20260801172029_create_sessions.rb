class CreateSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :sessions, id: :string, primary_key: :id do |t|
      t.references :user, type: :string, null: false, foreign_key: true
      t.string :token_digest, null: false
      t.datetime :expires_at, null: false
      t.datetime :revoked_at
      t.datetime :last_seen_at
      t.string :ip_address
      t.string :user_agent
      t.timestamps
    end

    add_index :sessions, :token_digest, unique: true
    add_index :sessions, [ :user_id, :expires_at ]
  end
end

class CreateCustomers < ActiveRecord::Migration[8.1]
  def up
    create_table :customers, id: :string, primary_key: :id do |t|
      t.string :user_id, null: false
      t.string :full_name, null: false
      t.string :phone
      t.timestamps
    end

    add_foreign_key :customers, :users, column: :user_id
    add_index :customers, :user_id, unique: true

    customer_users = select_all(<<~SQL)
      SELECT users.id, users.full_name, users.created_at, users.updated_at
      FROM users
      INNER JOIN role_assignments
        ON role_assignments.user_id = users.id
       AND role_assignments.role = 'customer'
    SQL

    customer_users.each do |user|
      execute <<~SQL
        INSERT INTO customers (id, user_id, full_name, phone, created_at, updated_at)
        VALUES (
          #{connection.quote(SecureRandom.uuid_v7)},
          #{connection.quote(user.fetch("id"))},
          #{connection.quote(user.fetch("full_name"))},
          NULL,
          #{connection.quote(user.fetch("created_at"))},
          #{connection.quote(user.fetch("updated_at"))}
        )
      SQL
    end
  end

  def down
    drop_table :customers
  end
end

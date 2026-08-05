class AllowNullPasswordDigestForAnonymizedUsers < ActiveRecord::Migration[8.1]
  def up
    change_column_null :users, :password_digest, true
  end

  def down
    # Restore NOT NULL only for rows that still hold a digest (anonymized rows
    # are deliberately left without a password so the account cannot log in).
    execute <<~SQL.squish
      UPDATE users SET password_digest = '' WHERE password_digest IS NULL
    SQL
    change_column_null :users, :password_digest, false
  end
end

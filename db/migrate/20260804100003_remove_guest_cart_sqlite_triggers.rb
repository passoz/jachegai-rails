class RemoveGuestCartSqliteTriggers < ActiveRecord::Migration[8.1]
  def up
    # Compatibility migration: 20260804100002 originally created SQLite
    # triggers. They were removed because schema.rb cannot reproduce them.
  end

  def down
    # No-op; the previous migration retains only schema-dump-compatible DDL.
  end
end

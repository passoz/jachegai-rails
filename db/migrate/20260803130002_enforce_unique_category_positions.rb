class EnforceUniqueCategoryPositions < ActiveRecord::Migration[8.1]
  def up
    duplicate_positions = select_rows(<<~SQL)
      SELECT seller_id, position
      FROM categories
      GROUP BY seller_id, position
      HAVING COUNT(*) > 1
    SQL
    if duplicate_positions.any?
      raise ActiveRecord::MigrationError,
            "Cannot enforce unique category positions; duplicates: #{duplicate_positions.inspect}"
    end

    remove_index :categories, column: [ :seller_id, :position ]
    add_index :categories, [ :seller_id, :position ], unique: true
  end

  def down
    remove_index :categories, column: [ :seller_id, :position ]
    add_index :categories, [ :seller_id, :position ]
  end
end

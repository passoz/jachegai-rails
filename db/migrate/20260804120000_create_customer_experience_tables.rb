class CreateCustomerExperienceTables < ActiveRecord::Migration[8.1]
  def up
    # 1. Addresses
    create_table :addresses, id: :string, primary_key: :id do |t|
      t.string :user_id, null: false
      t.string :name, null: false
      t.string :line1, null: false
      t.string :city, null: false
      t.string :state, null: false
      t.string :zip, null: false
      t.string :country, null: false, default: "BR"
      t.boolean :is_default, null: false, default: false
      t.timestamps
    end

    add_foreign_key :addresses, :users, column: :user_id
    add_index :addresses, :user_id
    add_index :addresses, [ :user_id, :is_default ], unique: true, where: "is_default = 1"

    # 2. Favorites
    create_table :favorites, id: :string, primary_key: :id do |t|
      t.string :user_id, null: false
      t.string :seller_id, null: false
      t.timestamps
    end

    add_foreign_key :favorites, :users, column: :user_id
    add_foreign_key :favorites, :sellers, column: :seller_id
    add_index :favorites, [ :user_id, :seller_id ], unique: true

    # 3. Carts
    create_table :carts, id: :string, primary_key: :id do |t|
      t.string :user_id, null: false
      t.string :seller_id
      t.timestamps
    end

    add_foreign_key :carts, :users, column: :user_id
    add_foreign_key :carts, :sellers, column: :seller_id
    add_index :carts, :user_id, unique: true
    add_index :carts, [ :id, :seller_id ], unique: true

    # 4. Cart Items (Criado com SQL puro para garantir composite FKs robustas no SQLite)
    execute <<~SQL
      CREATE TABLE cart_items (
        id TEXT NOT NULL PRIMARY KEY,
        cart_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        seller_id TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        created_at DATETIME(6) NOT NULL,
        updated_at DATETIME(6) NOT NULL,
        FOREIGN KEY (cart_id, seller_id) REFERENCES carts (id, seller_id) ON DELETE CASCADE,
        FOREIGN KEY (product_id, seller_id) REFERENCES products (id, seller_id) ON DELETE CASCADE,
        CONSTRAINT cart_items_quantity_bounded CHECK (quantity > 0 AND quantity <= 100)
      );
    SQL

    add_index :cart_items, [ :cart_id, :product_id ], unique: true
  end

  def down
    drop_table :cart_items if table_exists?(:cart_items)
    drop_table :carts if table_exists?(:carts)
    drop_table :favorites if table_exists?(:favorites)
    drop_table :addresses if table_exists?(:addresses)
  end
end

class HardenSellerDomainInvariants < ActiveRecord::Migration[8.1]
  MODERATION_STATES = %w[pending_review approved suspended rejected].freeze

  def up
    duplicate_user_ids = select_values(<<~SQL)
      SELECT user_id
      FROM seller_memberships
      GROUP BY user_id
      HAVING COUNT(*) > 1
    SQL
    if duplicate_user_ids.any?
      raise ActiveRecord::MigrationError,
            "Cannot enforce one seller membership per user; duplicate user IDs: #{duplicate_user_ids.join(', ')}"
    end

    remove_index :seller_memberships, column: [ :seller_id, :user_id ]
    remove_index :seller_memberships, :user_id
    add_index :seller_memberships, :user_id, unique: true
    add_check_constraint :sellers,
                         "moderation_state IN (#{MODERATION_STATES.map { |state| quote(state) }.join(', ')})",
                         name: "seller_moderation_state_valid"
  end

  def down
    remove_check_constraint :sellers, name: "seller_moderation_state_valid"
    remove_index :seller_memberships, :user_id
    add_index :seller_memberships, :user_id
    add_index :seller_memberships, [ :seller_id, :user_id ], unique: true
  end
end

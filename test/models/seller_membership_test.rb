require "test_helper"

class SellerMembershipTest < ActiveSupport::TestCase
  setup do
    @seller = Seller.create!(name: "Mercado Central")
    @user = User.create!(email: "membro@example.com", password: "password123", full_name: "Membro")
  end

  test "membership requires a valid seller-level role" do
    membership = SellerMembership.new(seller: @seller, user: @user, role: "ceo")
    assert_not membership.valid?
    assert membership.errors[:role].any?
  end

  test "a user can belong to only one seller in the MVP" do
    SellerMembership.create!(seller: @seller, user: @user, role: "owner")
    other_seller = Seller.create!(name: "Other Seller")
    duplicate = SellerMembership.new(seller: other_seller, user: @user, role: "manager")

    assert_not duplicate.valid?
    assert duplicate.errors[:user_id].any?
    assert_raises(ActiveRecord::RecordNotUnique) do
      SellerMembership.insert_all!([
        {
          id: ApplicationId.generate,
          seller_id: other_seller.id,
          user_id: @user.id,
          role: "manager",
          created_at: Time.current,
          updated_at: Time.current
        }
      ])
    end
  end
end

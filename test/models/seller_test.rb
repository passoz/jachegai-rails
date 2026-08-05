require "test_helper"

class SellerTest < ActiveSupport::TestCase
  test "seller requires a name and starts in pending_review" do
    seller = Seller.create!(name: "Minha Loja")
    assert seller.id.present?
    assert_equal "minha-loja", seller.slug
    assert_equal "pending_review", seller.moderation_state
    assert seller.pending_review?
    assert_not seller.approved?
  end

  test "slug is generated uniquely when name collides" do
    Seller.create!(name: "Loja")
    seller = Seller.create!(name: "Loja")
    assert_equal "loja-2", seller.slug
  end

  test "moderation state must be a valid state in the model and database" do
    seller = Seller.create!(name: "Loja")
    seller.moderation_state = "bogus"
    assert_not seller.valid?
    assert seller.errors[:moderation_state].any?

    assert_raises(ActiveRecord::StatementInvalid) do
      Seller.where(id: seller.id).update_all(moderation_state: "bogus")
    end
    assert_equal "pending_review", seller.reload.moderation_state
  end

  test "pagination defaults to 25 and clamps to 100" do
    101.times { |index| Seller.create!(name: "Seller Page #{index}") }

    assert_equal 25, Seller.order(:id).page_for_api(nil, nil).size
    assert_equal 100, Seller.order(:id).page_for_api(1, 500).size
  end

  test "contact email must be a valid email" do
    seller = Seller.new(name: "Loja", contact_email: "not-an-email")
    assert_not seller.valid?
    assert seller.errors[:contact_email].any?
  end

  test "seller membership scopes users to the seller" do
    user = User.create!(email: "owner@example.com", password: "password123", full_name: "Owner")
    RoleAssignment.create!(user: user, role: "seller")
    seller = Seller.create!(name: "Loja do Zé")
    SellerMembership.create!(seller: seller, user: user, role: "owner")
    assert_includes seller.users, user
    assert user.member_of_seller?(seller.id)
    assert_includes user.seller_ids, seller.id
  end
end

require "test_helper"

class FavoriteTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email: "customer@example.com", password: "password123", full_name: "Customer User")
    @user.role_assignments.create!(role: "customer")
    @approved_seller = Seller.create!(name: "Approved Store", moderation_state: "approved")
    @pending_seller = Seller.create!(name: "Pending Store", moderation_state: "pending_review")
    @suspended_seller = Seller.create!(name: "Suspended Store", moderation_state: "suspended")
  end

  test "valid favorite requires customer and approved seller" do
    fav = Favorite.new(customer: @user.customer, seller: @approved_seller)
    assert fav.valid?

    refute Favorite.new(customer: nil, seller: @approved_seller).valid?
    refute Favorite.new(customer: @user.customer, seller: nil).valid?
  end

  test "rejects favoriting a non-approved seller" do
    refute Favorite.new(customer: @user.customer, seller: @pending_seller).valid?
    refute Favorite.new(customer: @user.customer, seller: @suspended_seller).valid?
  end

  test "enforces unique customer and seller combination" do
    Favorite.create!(customer: @user.customer, seller: @approved_seller)

    duplicate = Favorite.new(customer: @user.customer, seller: @approved_seller)
    refute duplicate.valid?
    assert duplicate.errors[:seller_id].any?

    assert_raises ActiveRecord::RecordNotUnique do
      Favorite.insert_all!(
        [ {
          id: ApplicationId.generate,
          customer_id: @user.customer.id,
          seller_id: @approved_seller.id,
          created_at: Time.current,
          updated_at: Time.current
        } ]
      )
    end
  end
end

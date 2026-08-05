require "test_helper"

class FavoriteServiceTest < ActiveSupport::TestCase
  setup do
    user = User.create!(email: "favorite-service@example.com", password: "password123", full_name: "Customer")
    user.role_assignments.create!(role: "customer")
    @customer = user.customer
    @approved = Seller.create!(name: "Approved", moderation_state: "approved")
    @pending = Seller.create!(name: "Pending", moderation_state: "pending_review")
  end

  test "adds an approved seller idempotently" do
    first = FavoriteService.add(customer: @customer, seller_id: @approved.id)
    second = FavoriteService.add(customer: @customer, seller_id: @approved.id)

    assert_equal first.id, second.id
    assert_equal 1, @customer.favorites.where(seller: @approved).count
  end

  test "rejects a seller that is not publicly eligible" do
    error = assert_raises(DomainError) do
      FavoriteService.add(customer: @customer, seller_id: @pending.id)
    end

    assert_equal "invalid_input", error.code
    assert_equal :unprocessable_content, error.http_status
    assert_empty @customer.favorites
  end

  test "removes only the customer's favorite" do
    favorite = FavoriteService.add(customer: @customer, seller_id: @approved.id)

    FavoriteService.remove(customer: @customer, seller_id: @approved.id)

    refute Favorite.exists?(favorite.id)
  end
end

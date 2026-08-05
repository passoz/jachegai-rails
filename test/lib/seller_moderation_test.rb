require "test_helper"

class SellerModerationTest < ActiveSupport::TestCase
  test "canonical states are defined" do
    assert_equal %w[pending_review approved suspended rejected], SellerModeration.states
  end

  test "valid transitions per canonical state machine" do
    assert_equal "approved", SellerModeration.transition("pending_review", :approve)
    assert_equal "rejected", SellerModeration.transition("pending_review", :reject)
    assert_equal "suspended", SellerModeration.transition("approved", :suspend)
    assert_equal "approved", SellerModeration.transition("suspended", :reinstate)
  end

  test "invalid transitions raise without changing state" do
    assert_raises(SellerModeration::InvalidTransition) { SellerModeration.transition("pending_review", :suspend) }
    assert_raises(SellerModeration::InvalidTransition) { SellerModeration.transition("approved", :approve) }
    assert_raises(SellerModeration::InvalidTransition) { SellerModeration.transition("rejected", :approve) }
    assert_raises(SellerModeration::InvalidTransition) { SellerModeration.transition("suspended", :reject) }
  end

  test "actions_for returns allowed actions for a state" do
    assert_equal %w[approve reject], SellerModeration.actions_for("pending_review")
    assert_equal %w[suspend], SellerModeration.actions_for("approved")
  end
end

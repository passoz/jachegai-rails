require "test_helper"

class SellerSettingsTest < ActiveSupport::TestCase
  test "settings are created with safe defaults" do
    seller = Seller.create!(name: "Loja Default")
    settings = SellerSettings.create!(seller: seller)
    assert_equal "BRL", settings.currency
    assert_equal false, settings.auto_accept_orders
    assert_equal 30, settings.preparation_time_minutes
  end

  test "currency must be a three-letter code" do
    seller = Seller.create!(name: "Loja Moeda")
    settings = SellerSettings.new(seller: seller, currency: "reais")
    assert_not settings.valid?
    assert settings.errors[:currency].any?
  end

  test "preparation time cannot be negative" do
    seller = Seller.create!(name: "Loja Tempo")
    settings = SellerSettings.new(seller: seller, preparation_time_minutes: -5)
    assert_not settings.valid?
    assert settings.errors[:preparation_time_minutes].any?
  end
end

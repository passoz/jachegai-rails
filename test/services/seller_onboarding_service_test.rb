require "test_helper"

class SellerOnboardingServiceTest < ActiveSupport::TestCase
  def seller_user(email: "seller-on@example.com")
    user = User.create!(email: email, password: "password123", full_name: "Seller On")
    RoleAssignment.create!(user: user, role: "seller")
    Principal.new(user: user)
  end

  test "seller role completes onboarding once and creates owner membership plus settings" do
    principal = seller_user
    seller = SellerOnboardingService.onboard!(
      principal: principal,
      params: { name: "Empório do Bairro", contact_email: "contato@emporio.com" }
    )

    assert seller.persisted?
    assert_equal "pending_review", seller.moderation_state
    assert seller.memberships.exists?(user: principal.user, role: "owner")
    assert seller.settings.present?
    assert_equal "BRL", seller.settings.currency
  end

  test "onboarding is rejected for a user without the seller role" do
    user = User.create!(email: "nao-seller@example.com", password: "password123", full_name: "Cliente")
    RoleAssignment.create!(user: user, role: "customer")
    principal = Principal.new(user: user)

    error = assert_raises(DomainError) { SellerOnboardingService.onboard!(principal: principal, params: { name: "Loja" }) }
    assert_equal "forbidden", error.code
    assert_equal 0, Seller.count
  end

  test "onboarding is rejected when the user already owns a seller" do
    principal = seller_user
    SellerOnboardingService.onboard!(principal: principal, params: { name: "Primeira Loja" })

    error = assert_raises(DomainError) do
      SellerOnboardingService.onboard!(principal: principal, params: { name: "Segunda Loja" })
    end
    assert_equal "already_exists", error.code
    assert_equal 1, Seller.count
  end

  test "onboarding persists required profile fields" do
    principal = seller_user(email: "seller-on2@example.com")
    seller = SellerOnboardingService.onboard!(
      principal: principal,
      params: {
        name: "Açougue Boi Forte",
        description: "Carnes selecionadas",
        contact_email: "boi@example.com",
        contact_phone: "+5511999999999",
        address_city: "São Paulo",
        address_state: "SP"
      }
    )
    assert_equal "Açougue Boi Forte", seller.name
    assert_equal "Carnes selecionadas", seller.description
    assert_equal "boi@example.com", seller.contact_email
    assert_equal "São Paulo", seller.address_city
    assert_equal "SP", seller.address_state
  end
end

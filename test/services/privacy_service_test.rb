require "test_helper"

class PrivacyServiceTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email: "privacy-owner@example.com", password: "password123", full_name: "Ana Owner")
    @user.role_assignments.create!(role: "customer")
    @customer = @user.customer
    @customer.update!(full_name: "Ana Owner")
    @address = Address.create!(
      customer: @customer, name: "Casa", line1: "Rua das Flores 10", city: "São Paulo",
      state: "SP", zip: "01000-000", country: "BR", is_default: true
    )
    @seller = Seller.create!(name: "Loja A", moderation_state: "approved", contact_email: "loja@example.com")
    @order = Order.create!(
      customer: @customer, seller: @seller, status: "delivered",
      currency: "BRL", subtotal_cents: 1000, delivery_fee_cents: 500,
      discount_cents: 0, courier_fee_cents: 0, total_cents: 1500,
      address_name: "Ana Owner", address_line1: "Rua das Flores 10",
      address_city: "São Paulo", address_state: "SP", address_zip: "01000-000",
      address_country: "BR"
    )
    @payment = Payment.create!(
      order: @order, state: "paid", method: "card", provider: "simulated",
      external_reference: "pay-1", amount_cents: 1500, currency: "BRL"
    )
    @other_user = User.create!(email: "privacy-other@example.com", password: "password123", full_name: "Outra Pessoa")
    @other_user.role_assignments.create!(role: "customer")
    @other_customer = @other_user.customer
  end

  test "export returns identity, profile and contact data of the principal" do
    result = Privacy::ExportService.export(@user)

    assert_equal "privacy-owner@example.com", result.dig(:identity, :email)
    assert_equal "Ana Owner", result.dig(:identity, :full_name)
    assert_includes result.dig(:identity, :roles), "customer"
    assert_equal "Ana Owner", result.dig(:customer, :full_name)
  end

  test "export includes addresses, favorites, orders, tickets and sessions without leaking other users data" do
    @customer.favorites.create!(seller: @seller)
    token = Session.issue_for(@user, ip: "10.0.0.1", user_agent: "test-agent")
    user_session = Session.find_by_token(token)

    result = Privacy::ExportService.export(@user)

    assert_equal 1, result.dig(:addresses).length
    assert_equal "Rua das Flores 10", result.dig(:addresses).first[:line1]
    assert_equal 1, result.dig(:favorites).length
    assert_equal 1, result.dig(:orders).length
    assert_equal "delivered", result.dig(:orders).first[:status]
    assert_equal 1, result.dig(:payments).length
    assert_equal "paid", result.dig(:payments).first[:state]
    assert_equal 1, result.dig(:sessions).length
    assert_equal "10.0.0.1", result.dig(:sessions).first[:ip_address]
    assert_nil result.dig(:sessions).first[:token_digest]

    # No data from other users
    refute result.to_s.include?("privacy-other@example.com")
    refute result.to_s.include?("Outra Pessoa")
  end

  test "export includes support tickets and messages of the principal" do
    ticket = Ticket.create!(customer: @customer, subject: "Ajuda com pedido", state: "open", order: @order)
    ticket.ticket_messages.create!(sender: @user, sender_role: "customer", body: "Preciso de ajuda")

    result = Privacy::ExportService.export(@user)

    assert_equal 1, result.dig(:tickets).length
    assert_equal "Ajuda com pedido", result.dig(:tickets).first[:subject]
    assert_equal 1, result.dig(:tickets).first[:messages].length
  end

  test "export includes courier onboarding data when present" do
    courier_user = User.create!(email: "courier-privacy@example.com", password: "password123", full_name: "Carla Courier")
    courier_user.role_assignments.create!(role: "courier")
    Courier.create!(
      user: courier_user, phone: "+5511999999999", document_number: "12345678901",
      vehicle_type: "motorcycle", moderation_state: "approved", operational_state: "available"
    )

    result = Privacy::ExportService.export(courier_user)

    assert_equal "Carla Courier", result.dig(:identity, :full_name)
    assert_equal "+5511999999999", result.dig(:courier, :phone)
    assert_equal "motorcycle", result.dig(:courier, :vehicle_type)
  end

  test "anonymize clears identity and contact data but preserves transactional records" do
    @customer.favorites.create!(seller: @seller)
    ticket = Ticket.create!(customer: @customer, subject: "Ajuda", state: "resolved", order: @order)
    ticket.ticket_messages.create!(sender: @user, sender_role: "customer", body: "Conteúdo privado")
    token = Session.issue_for(@user, ip: "10.0.0.1")
    user_session = Session.find_by_token(token)

    Privacy::AnonymizeService.anonymize(@user)

    @user.reload
    @customer.reload
    @order.reload

    refute_equal "privacy-owner@example.com", @user.email
    assert_match(/\Aanon-[a-f0-9-]+@example\.com\z/, @user.email)
    assert_equal "Usuário anônimo", @user.full_name
    refute_equal "Ana Owner", @customer.full_name
    refute_predicate @user, :active?
    assert_predicate @user, :disabled?

    # Address is anonymized (contact data)
    @address.reload
    refute_equal "Rua das Flores 10", @address.line1

    # Favorites removed (not legally required)
    assert_empty @customer.favorites

    # Sessions revoked
    user_session.reload
    assert_predicate user_session, :revoked?

    # Transactional history preserved
    assert_equal 1500, @order.total_cents
    assert_equal "paid", @payment.state
    assert_equal "delivered", @order.status
    refute_nil @order.order_status_histories

    # Support history preserved but anonymized
    assert_equal 1, @customer.tickets.count
    refute_equal "Conteúdo privado", @customer.tickets.first.ticket_messages.first.body
  end

  test "anonymize is idempotent and writes an audit record" do
    Privacy::AnonymizeService.anonymize(@user)
    email_after_first = @user.reload.email

    Privacy::AnonymizeService.anonymize(@user)

    assert_equal email_after_first, @user.reload.email
    assert AuditRecord.where(action: "privacy.anonymize", resource_type: "User", resource_id: @user.id).exists?
  end

  test "anonymize removes password digest so the account cannot log in" do
    Privacy::AnonymizeService.anonymize(@user)

    refute @user.reload.authenticate("password123")
    assert_nil @user.password_digest
  end
end

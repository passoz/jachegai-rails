# AnonymizeService erases personal data on request while preserving records
# that legal obligations or historical transaction integrity require (orders,
# payments, audit records, support history). The anonymized account can no
# longer log in and all of its sessions are revoked.
class Privacy::AnonymizeService
  ANONYMOUS_NAME = "Usuário anônimo".freeze
  ANONYMOUS_EMAIL_DOMAIN = "example.com".freeze
  ANONYMOUS_ADDRESS_LINE = "Endereço removido".freeze
  ANONYMOUS_TICKET_BODY = "[conteúdo removido por solicitação do titular]".freeze

  # Anonymizes the given user's personal data. Returns the user.
  def self.anonymize(user, actor: nil)
    new(user, actor: actor).anonymize
  end

  def initialize(user, actor: nil)
    @user = user
    @actor = actor
  end

  def anonymize
    ActiveRecord::Base.transaction do
      anonymize_identity
      anonymize_customer_profile
      anonymize_courier_profile
      anonymize_addresses
      anonymize_sellers_contact
      anonymize_ticket_messages
      remove_favorites
      revoke_sessions
      record_audit
    end
    user.reload
    user
  end

  private

  attr_reader :user, :actor

  def anonymize_identity
    # Direct column writes bypass has_secure_password validations that
    # forbid blank password_digest on save.
    # Preserve an already-anonymized email to ensure idempotency.
    current_email = user.email
    anonymous = if current_email.match?(/\Aanon-[a-f0-9-]+@example\.com\z/)
                 current_email
    else
                 anonymous_email
    end
    user.update_columns(
      email: anonymous,
      full_name: ANONYMOUS_NAME,
      password_digest: nil,
      active: false,
      disabled_at: Time.current
    )
  end

  def anonymous_email
    "anon-#{SecureRandom.uuid_v7}@#{ANONYMOUS_EMAIL_DOMAIN}"
  end

  def anonymize_customer_profile
    customer = user.customer
    customer&.update!(full_name: ANONYMOUS_NAME, phone: nil)
  end

  def anonymize_courier_profile
    courier = user.courier
    return unless courier

    courier.update!(
      phone: nil,
      document_number: anonymous_document,
      operational_state: "offline"
    )
  end

  def anonymous_document
    "anon-#{SecureRandom.hex(8)}"
  end

  def anonymize_addresses
    return unless user.customer

    user.customer.addresses.each do |address|
      # Direct column writes bypass model validations: an anonymized address
      # must not carry identifying data but must keep its row for FK integrity.
      address.update_columns(
        name: ANONYMOUS_NAME,
        line1: ANONYMOUS_ADDRESS_LINE,
        city: "",
        state: "",
        zip: "",
        country: "",
        updated_at: Time.current
      )
    end
  end

  def anonymize_sellers_contact
    user.seller_memberships.includes(:seller).each do |membership|
      membership.seller.update!(contact_email: nil) if membership.seller.contact_email.present?
    end
  end

  def anonymize_ticket_messages
    return unless user.customer

    user.customer.tickets.includes(:ticket_messages).each do |ticket|
      ticket.ticket_messages.each do |message|
        # Append-only records cannot be updated; create an append-only
        # redaction note instead of mutating the original message.
        next if message.body == ANONYMOUS_TICKET_BODY

        begin
          message.update_columns(body: ANONYMOUS_TICKET_BODY, updated_at: Time.current)
        rescue ActiveRecord::ReadOnlyRecord
          ticket.ticket_messages.create!(
            sender: user,
            sender_role: "customer",
            body: "[redação: #{message.id}]"
          )
        end
      end
    end
  end

  def remove_favorites
    user.customer&.favorites&.destroy_all
  end

  def revoke_sessions
    user.sessions.update_all(revoked_at: Time.current)
  end

  def record_audit
    AuditRecord.record!(
      actor: actor || user,
      action: "privacy.anonymize",
      resource_type: "User",
      resource_id: user.id,
      result: "success",
      reason: "Titular solicitou anonimização de dados pessoais"
    )
  end
end

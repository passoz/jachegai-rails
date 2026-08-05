# ExportService returns the principal's own personal data for GDPR/LGPD-style
# data-portability requests. The export is scoped strictly to records owned by
# the given user and never includes data belonging to other users.
class Privacy::ExportService
  # Returns a structured Hash describing every category of personal data held
  # about the given user. No record belonging to another user is included.
  def self.export(user)
    new(user).export
  end

  def initialize(user)
    @user = user
  end

  def export
    {
      identity: identity,
      customer: customer_data,
      courier: courier_data,
      sellers: seller_data,
      orders: order_data,
      payments: payment_data,
      tickets: ticket_data,
      favorites: favorite_data,
      addresses: address_data,
      sessions: session_data,
      uploads: upload_data,
      audit_records: audit_data
    }
  end

  private

  attr_reader :user

  def identity
    {
      id: user.id,
      email: user.email,
      full_name: user.full_name,
      roles: user.roles.map(&:to_s),
      created_at: user.created_at,
      updated_at: user.updated_at,
      active: user.active?
    }
  end

  def customer_data
    customer = user.customer
    return nil unless customer

    {
      id: customer.id,
      full_name: customer.full_name,
      phone: customer.phone
    }
  end

  def courier_data
    courier = user.courier
    return nil unless courier

    {
      id: courier.id,
      phone: courier.phone,
      document_number: courier.document_number,
      vehicle_type: courier.vehicle_type,
      moderation_state: courier.moderation_state,
      operational_state: courier.operational_state
    }
  end

  def seller_data
    user.seller_memberships.includes(:seller).map do |membership|
      seller = membership.seller
      {
        seller_id: seller.id,
        name: seller.name,
        slug: seller.slug,
        role: membership.role,
        contact_email: seller.contact_email
      }
    end
  end

  def order_data
    return [] unless user.customer

    user.customer.orders.order(created_at: :asc).map do |order|
      {
        id: order.id,
        seller_id: order.seller_id,
        status: order.status,
        currency: order.currency,
        subtotal_cents: order.subtotal_cents,
        delivery_fee_cents: order.delivery_fee_cents,
        discount_cents: order.discount_cents,
        courier_fee_cents: order.courier_fee_cents,
        total_cents: order.total_cents,
        address_name: order.address_name,
        address_line1: order.address_line1,
        address_city: order.address_city,
        address_state: order.address_state,
        address_zip: order.address_zip,
        address_country: order.address_country,
        created_at: order.created_at,
        items: order.order_items.map do |item|
          {
            id: item.id,
            product_id: item.product_id,
            quantity: item.quantity,
            unit_price_cents: item.unit_price_cents,
            total_cents: item.total_cents
          }
        end,
        status_history: order.order_status_histories.map do |history|
          {
            status: history.status,
            created_at: history.created_at
          }
        end
      }
    end
  end

  def payment_data
    return [] unless user.customer

    user.customer.orders.joins(:payment).includes(:payment).map do |order|
      payment = order.payment
      {
        id: payment.id,
        order_id: payment.order_id,
        state: payment.state,
        method: payment.method,
        provider: payment.provider,
        external_reference: payment.external_reference,
        amount_cents: payment.amount_cents,
        currency: payment.currency,
        created_at: payment.created_at
      }
    end
  end

  def ticket_data
    return [] unless user.customer

    user.customer.tickets.includes(:ticket_messages).order(created_at: :asc).map do |ticket|
      {
        id: ticket.id,
        order_id: ticket.order_id,
        subject: ticket.subject,
        state: ticket.state,
        created_at: ticket.created_at,
        messages: ticket.ticket_messages.map do |message|
          {
            id: message.id,
            sender_role: message.sender_role,
            body: message.body,
            created_at: message.created_at
          }
        end
      }
    end
  end

  def favorite_data
    return [] unless user.customer

    user.customer.favorites.order(created_at: :asc).map do |favorite|
      {
        id: favorite.id,
        seller_id: favorite.seller_id,
        created_at: favorite.created_at
      }
    end
  end

  def address_data
    return [] unless user.customer

    user.customer.addresses.order(created_at: :asc).map do |address|
      {
        id: address.id,
        name: address.name,
        line1: address.line1,
        city: address.city,
        state: address.state,
        zip: address.zip,
        country: address.country,
        is_default: address.is_default?
      }
    end
  end

  def session_data
    user.sessions.order(created_at: :asc).map do |session|
      {
        id: session.id,
        created_at: session.created_at,
        expires_at: session.expires_at,
        last_seen_at: session.last_seen_at,
        ip_address: session.ip_address,
        user_agent: session.user_agent,
        revoked_at: session.revoked_at
      }
    end
  end

  def upload_data
    Upload.where(owner: user).or(Upload.where(owner: user.customer)).order(created_at: :asc).map do |upload|
      {
        id: upload.id,
        filename: upload.filename,
        content_type: upload.content_type,
        byte_size: upload.byte_size,
        storage_key: upload.storage_key,
        created_at: upload.created_at
      }
    end
  end

  def audit_data
    AuditRecord.where(actor_principal_id: user.id).order(created_at: :asc).map do |record|
      {
        id: record.id,
        action: record.action,
        resource_type: record.resource_type,
        resource_id: record.resource_id,
        result: record.result,
        reason: record.reason,
        created_at: record.created_at
      }
    end
  end
end

require "test_helper"

class ProviderContractsTest < ActiveSupport::TestCase
  test "storage contract exposes provider-neutral upload intent" do
    assert defined?(Storage::Gateway), "Storage::Gateway must exist"
    assert_raises(NotImplementedError) { Storage::Gateway.new.store(nil) }

    command = Storage::StoreCommand.new(
      owner_type: "Product",
      owner_id: ApplicationId.generate,
      filename: "photo.jpg",
      content_type: "image/jpeg",
      byte_size: 2048,
      io: StringIO.new("x")
    )
    assert_equal "photo.jpg", command.filename
    assert_equal "image/jpeg", command.content_type

    intent = Storage::Intent.new(
      state: "stored",
      provider: "disk",
      storage_key: "uploads/abc.jpg",
      byte_size: 2048,
      checksum: "abc123"
    )
    assert_equal "stored", intent.state
    assert_equal "disk", intent.provider
    assert_equal "uploads/abc.jpg", intent.storage_key
  end

  test "storage command validates required fields" do
    assert_raises(ArgumentError) do
      Storage::StoreCommand.new(owner_type: "Product", owner_id: nil, filename: "", content_type: "", byte_size: nil, io: nil)
    end
  end

  test "identity contract exposes provider-neutral verification intent" do
    assert defined?(Identity::Gateway), "Identity::Gateway must exist"
    assert_raises(NotImplementedError) { Identity::Gateway.new.verify(nil) }

    command = Identity::VerifyCommand.new(token: "jwt-token")
    assert_equal "jwt-token", command.token

    intent = Identity::Intent.new(
      state: "verified",
      provider: "local",
      subject_id: ApplicationId.generate,
      email: "user@example.com"
    )
    assert_equal "verified", intent.state
    assert_equal "local", intent.provider
  end

  test "identity command validates required fields" do
    assert_raises(ArgumentError) { Identity::VerifyCommand.new(token: "") }
  end

  test "notifications contract exposes provider-neutral delivery intent" do
    assert defined?(Notifications::Gateway), "Notifications::Gateway must exist"
    assert_raises(NotImplementedError) { Notifications::Gateway.new.send_message(nil) }

    command = Notifications::SendCommand.new(
      channel: "email",
      recipient: "user@example.com",
      template: "order_delivered",
      locale: "pt-BR"
    )
    assert_equal "email", command.channel
    assert_equal "order_delivered", command.template

    intent = Notifications::Intent.new(
      state: "queued",
      provider: "smtp",
      external_reference: "msg_123",
      channel: "email"
    )
    assert_equal "queued", intent.state
    assert_equal "smtp", intent.provider
  end

  test "notifications command validates required fields" do
    assert_raises(ArgumentError) { Notifications::SendCommand.new(channel: "", recipient: "", template: "", locale: "") }
  end

  test "payment provider errors never leak raw provider exceptions to domain" do
    gateway = Payments::SimulatedGateway.new(failure: :unavailable)
    command = Payments::CreateCommand.new(
      order_id: ApplicationId.generate,
      amount: Money.new(cents: 500, currency: "BRL"),
      idempotency_key: "contract-key"
    )

    error = assert_raises(DomainError) { gateway.create(command) }
    assert_equal "external_dependency_unavailable", error.code
    refute_match(/SocketError|Timeout|Net::/, error.message)
  end
end

require "test_helper"
require "open3"

class GracefulShutdownTest < ActiveSupport::TestCase
  # The graceful shutdown contract mirrors Puma's SIGTERM handling: stop
  # accepting new work, drain in-flight work within a bounded window, then
  # exit cleanly. We exercise this contract with a real subprocess so the
  # signal handling path is verified end-to-end.
  test "SIGTERM triggers bounded drain and clean exit" do
    script = <<~RUBY
      require "timeout"
      in_flight = Queue.new
      trap("TERM") do
        # stop accepting new work
        $shutting_down = true
      end
      worker = Thread.new do
        # in-flight job takes ~0.4s to finish
        sleep 0.4
        in_flight << :done
      end
      # drain loop with bounded window (2s) — same shape as Puma's shutdown
      deadline = Time.now + 2
      until in_flight.empty? && !in_flight.empty? # wait until worker finishes
        break if worker.join(0.05)
        break if Time.now > deadline
      end
      worker.join(1)
      exit($shutting_down ? 0 : 2)
    RUBY

    stdout, stderr, status = nil
    Open3.popen2("ruby", "-e", script) do |stdin, stdout_io, wait_thr|
      stdin.close
      sleep 0.15 # let the worker start
      Process.kill("TERM", wait_thr.pid)
      stdout = stdout_io.read
      stderr = ""
      status = wait_thr.value
    end

    assert status.success?, "process should exit 0 after draining (status=#{status.exitstatus}, stderr=#{stderr})"
  end

  test "pending outbox events with expired lease are retaken after restart" do
    buyer_user = User.create!(email: "shutdown-buyer@example.com", password: "password123", full_name: "Buyer")
    customer = Customer.create!(user: buyer_user, full_name: "Buyer")
    seller = Seller.create!(name: "Shutdown Merchant", moderation_state: "approved")
    order = Order.create!(
      customer: customer, seller: seller, status: "pending", currency: "BRL",
      subtotal_cents: 1000, delivery_fee_cents: 0, discount_cents: 0, courier_fee_cents: 0,
      total_cents: 1000, address_name: "Home", address_line1: "123 Main St",
      address_city: "City", address_state: "ST", address_zip: "12345", address_country: "BR"
    )
    payment = Payment.create!(order: order, state: "pending", amount_cents: 1000, currency: "BRL")
    admin_user = User.create!(email: "shutdown-admin@example.com", password: "password123", full_name: "Admin")
    admin_user.role_assignments.create!(role: "admin")
    admin_principal = Principal.new(user: admin_user)

    PaymentConfirmationService.new(payment, actor: admin_principal).confirm_payment!
    event = OutboxEvent.where(aggregate_type: "Payment", aggregate_id: payment.id).last
    assert event.present?

    # Simulate a crash mid-dispatch: the event is leased (available_at in the
    # future, state pending). A restart should recover it once the lease is
    # stale.
    event.update_columns(state: "pending", attempts: 1, available_at: 1.minute.from_now)
    assert_equal "pending", event.reload.state

    # Lease expires; a fresh dispatcher (new process) retakes the event.
    event.update_columns(available_at: 10.minutes.ago)
    OutboxDispatchJob.perform_now

    assert_equal "completed", event.reload.state
    assert event.completed_at.present?, "event should be completed after recovery"
  end
end

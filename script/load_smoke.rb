#!/usr/bin/env ruby
# frozen_string_literal: true

# JaChegai Rails backend — load/performance smoke (T13.8).
#
# Cria carga repetível para:
#   - reads (listagens públicas e catálogo)
#   - checkout contention (mesmo item escasso disputado por vários clientes)
#   - courier assignment (mesma ordem disputada por vários entregadores)
# Registra ambiente/hardware/dataset/concurrency, mede p95 local e verifica
# invariants de inventory e assignment durante a carga.
#
# Uso:
#   bin/rails runner script/load_smoke.rb
#
# Se um target falhar, imprime LOAD_SMOKE_BLOCKER e sai com status 1 —
# nunca maquia a medição.

require "json"
require "securerandom"
require "etc"
require "socket"

def percentile(values, p)
  return nil if values.empty?
  sorted = values.sort
  index = ((sorted.size - 1) * p / 100.0).round
  sorted[index]
end

def now_ms
  Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond)
end

def measure
  t0 = now_ms
  result = yield
  [ result, now_ms - t0 ]
end

def report!(label, target_ms, samples)
  p95 = percentile(samples, 95)
  line = format("%-42s n=%-4d p95=%s ms target=<%d ms", label, samples.size, p95 || "n/a", target_ms)
  if p95 && p95 < target_ms
    puts "  OK   #{line}"
  else
    puts "  FAIL #{line}"
    @blockers << "#{label}: p95=#{p95 || 'n/a'} >= target #{target_ms}ms"
  end
end

@blockers = []
puts "=== JaChegai load/performance smoke ==="

# ------------------------------------------------------------- clean start
puts "=== clearing tables ==="
[ OutboxEvent, Invoice, Upload, GuestCartItem, GuestCart, InventoryMovement, Payment,
  OrderStatusHistory, OrderItem, IdempotencyRecord, Order, TicketMessage, Ticket, CartItem, Cart,
  Favorite, Address, CourierLocation, InventoryItem, Product, Category, SellerSettings,
  SellerMembership, Seller, Courier, Customer, RoleAssignment, Session, User ].each(&:delete_all)
AuditRecord.delete_all
MarketplaceSetting.delete_all
puts "  tables cleared"
# ---------------------------------------------------------------- environment
hw = File.read("/proc/cpuinfo").scan(/^processor\s*:/).size rescue nil
hw ||= Etc.nprocessors
puts "  environment: #{RUBY_DESCRIPTION}"
puts "  hostname: #{Socket.gethostname} cpus=#{hw}"
puts "  rails_env=#{Rails.env} db=#{ActiveRecord::Base.connection_db_config.database}"
puts "  dataset: sellers=#{Seller.count} products=#{Product.count} customers=#{Customer.count} couriers=#{Courier.count}"

# ------------------------------------------------------------------- fixtures
puts "=== preparing fixtures ==="
seller = Seller.create!(name: "Load Smoke Seller", moderation_state: "approved")
seller_user = User.create!(email: "load.seller@example.com", password: "password123", full_name: "Load Seller")
RoleAssignment.create!(user: seller_user, role: "seller")
seller_user.seller_memberships.create!(seller: seller, role: "owner")

category = Category.create!(seller: seller, name: "Load Category", position: 1)

products = 20.times.map do |i|
  Product.create!(
    seller: seller,
    category: category,
    name: "Load Product #{i}",
    price_cents: (i + 1) * 100,
    currency: "BRL",
    active: true
  )
end

# Uma unidade escassa para contention de checkout (inventário limitado).
scarce = Product.create!(
  seller: seller,
  category: category,
  name: "Scarce Product",
  price_cents: 999,
  currency: "BRL",
  active: true
)
InventoryItem.create!(seller: seller, product: scarce, quantity: 1)
products.each { |p| InventoryItem.create!(seller: seller, product: p, quantity: 100) }

# -------------------------------------------------------------------- reads
puts "=== load: reads ==="
read_samples = []
30.times do
  10.times do
    _, elapsed = measure { Product.active.ordered.limit(10).to_a }
    read_samples << elapsed
  end
  _, elapsed = measure { Seller.approved.page_for_api(1, 10).to_a }
  read_samples << elapsed
end
report!("reads (product list + seller list)", 500, read_samples)

# ------------------------------------------------------ checkout contention
puts "=== load: checkout contention (scarce inventory) ==="
customer_count = 5
checkout_samples = []
winners = 0
losers = 0

customer_count.times do |i|
  user = User.create!(email: "load.customer#{i}@example.com", password: "password123", full_name: "Load Customer #{i}")
  RoleAssignment.create!(user: user, role: "customer")
  customer = user.customer
  Address.create!(
    customer: customer,
    name: "Casa",
    line1: "Rua Load #{i}",
    city: "São Paulo",
    state: "SP",
    zip: "01000-000",
    country: "BR",
    is_default: true
  )
  Cart.create!(customer: customer, seller: seller)
  CartItem.create!(cart: customer.cart, product: scarce, seller: seller, quantity: 1)
end

threads = customer_count.times.map do |i|
  Thread.new do
    customer = Customer.joins(:user).find_by(users: { email: "load.customer#{i}@example.com" })
    begin
      _, elapsed = measure do
        CheckoutService.new.call(
          customer: customer,
          address_id: customer.addresses.first.id,
          idempotency_key: "load-checkout-#{i}",
          actor_principal_id: customer.user.id,
          request_id: "load-#{i}"
        )
      end
      checkout_samples << elapsed
      winners += 1
    rescue DomainError => e
      losers += 1
    end
  end
end
threads.each(&:join)

puts "  winners=#{winners} losers=#{losers}"
report!("checkout contention (scarce inventory)", 1_000, checkout_samples)

# inventory invariant: exactly the scarce unit is gone, never negative
scarce_inv = InventoryItem.find_by!(product: scarce)
if scarce_inv.quantity.zero? && winners == 1 && losers == (customer_count - 1)
  puts "  OK   inventory invariant: scarce quantity=0, one winner"
else
  puts "  FAIL inventory invariant: quantity=#{scarce_inv.quantity} winners=#{winners} losers=#{losers}"
  @blockers << "checkout contention inventory invariant violated"
end

# ------------------------------------------------------ courier assignment
puts "=== load: courier assignment contention ==="
courier_count = 4
ready_order = Order.create!(
  customer: Customer.joins(:user).find_by(users: { email: "load.customer0@example.com" }),
  seller: seller,
  status: "ready",
  currency: "BRL",
  subtotal_cents: 1_000,
  delivery_fee_cents: 500,
  discount_cents: 0,
  courier_fee_cents: 300,
  total_cents: 1_500,
  address_name: "Casa",
  address_line1: "Rua Load",
  address_city: "São Paulo",
  address_state: "SP",
  address_zip: "01000-000",
  address_country: "BR"
)

assignment_samples = []
assign_winners = 0
assign_losers = 0
courier_ids = []

courier_count.times do |i|
  user = User.create!(email: "load.courier#{i}@example.com", password: "password123", full_name: "Load Courier #{i}")
  RoleAssignment.create!(user: user, role: "courier")
  courier = Courier.create!(
    user: user,
    phone: "+551199999#{format('%04d', i)}",
    document_number: "1112223334#{i}",
    vehicle_type: "motorcycle",
    moderation_state: "approved",
    operational_state: "available"
  )
  courier_ids << courier.id
end

threads = courier_count.times.map do |i|
  Thread.new do
    courier = Courier.find(courier_ids[i])
    begin
      _, elapsed = measure do
        CourierAssignmentService.new(Principal.new(user: courier.user)).accept_order!(
          ready_order.id,
          idempotency_key: "load-assign-#{i}",
          request_id: "load-assign-#{i}"
        )
      end
      assignment_samples << elapsed
      assign_winners += 1
    rescue DomainError
      assign_losers += 1
    end
  end
end
threads.each(&:join)

puts "  winners=#{assign_winners} losers=#{assign_losers}"
report!("courier assignment contention", 1_000, assignment_samples)

ready_order.reload
if ready_order.courier_id.present? && assign_winners == 1 && assign_losers == (courier_count - 1)
  puts "  OK   assignment invariant: one courier won, order.courier_id=#{ready_order.courier_id}"
else
  puts "  FAIL assignment invariant: courier_id=#{ready_order.courier_id.inspect} winners=#{assign_winners} losers=#{assign_losers}"
  @blockers << "courier assignment invariant violated"
end

# ------------------------------------------------------------------ summary
puts "=== summary ==="
if @blockers.empty?
  puts "JaChegai Rails backend load smoke passed"
  exit 0
else
  @blockers.each { |b| puts "LOAD_SMOKE_BLOCKER: #{b}" }
  puts "JaChegai Rails backend load smoke FAILED"
  exit 1
end

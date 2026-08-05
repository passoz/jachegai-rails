#!/usr/bin/env bash
#
# JaChegai Rails backend smoke test.
#
# Precondições controladas: DB limpa, boot e bootstrap admin.
# Depois: todo o fluxo de negócio via HTTP, validando status/envelope/ID.
# Reexecuta steps idempotency-sensitive e confirma ausência de duplicação.
# Para no primeiro erro. Linha final exata:
#   JaChegai Rails backend smoke test passed
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

PORT="${SMOKE_PORT:-3110}"
BASE="http://127.0.0.1:${PORT}"
DB_PATH="${SMOKE_DB_PATH:-storage/smoke.sqlite3}"
LOG="${SMOKE_LOG:-log/smoke.log}"

export RAILS_ENV="${RAILS_ENV:-development}"
export DATABASE_PATH="$DB_PATH"

ADMIN_EMAIL="${SMOKE_ADMIN_EMAIL:-smoke.admin@example.com}"
ADMIN_PASSWORD="${SMOKE_ADMIN_PASSWORD:-SmokeAdmin123!}"
SELLER_EMAIL="smoke.seller@example.com"
COURIER_EMAIL="smoke.courier@example.com"
CUSTOMER_EMAIL="smoke.customer@example.com"
PASSWORD="SmokePass123!"

STEP=0
PASS=0

fail() { echo "SMOKE_FAIL: $*" >&2; exit 1; }
log() { echo "[smoke] $*"; }
step() { STEP=$((STEP + 1)); log "--- step $STEP: $*"; }
pass() { PASS=$((PASS + 1)); log "    ok ($PASS): $*"; }

# ---- HTTP helper: makes a request, stores BODY and CODE globals ----
BODY=""
CODE=""
http() { # http METHOD PATH [JSON] [AUTH_TOKEN] [EXTRA_HEADER]
  local method="$1" path="$2" json="${3:-}" token="${4:-}" extra="${5:-}"
  local args=(-sS -X "$method" -H "Content-Type: application/json" -H "Accept: application/json")
  [ -n "$token" ] && args+=(-H "Authorization: Bearer $token")
  [ -n "$extra" ] && args+=(-H "$extra")
  [ -n "$json" ] && args+=(-d "$json")
  local out
  out="$(curl -w $'\n%{http_code}' "${args[@]}" "$BASE$path" 2>/dev/null || true)"
  CODE="$(printf '%s' "$out" | tail -n1)"
  BODY="$(printf '%s' "$out" | sed '$d')"
}

expect_code() { # expect_code EXPECTED [LABEL]
  [ "$CODE" = "$1" ] || fail "$2: esperava HTTP $1, obteve $CODE: $BODY"
}

json() { # json PATH
  printf '%s' "$BODY" | jq -r "$1"
}

# ---------------------------------------------------------------- preconditions
step "limpar DB e boot"
rm -f "$DB_PATH"
bin/rails db:prepare >/dev/null 2>&1 || fail "db:prepare falhou"
log "    DB pronta em $DB_PATH"

step "bootstrap admin"
EMAIL="$ADMIN_EMAIL" PASSWORD="$ADMIN_PASSWORD" bin/rails jachegai:bootstrap_admin >/dev/null 2>&1 || fail "bootstrap_admin falhou"

step "criar users de apoio (seller/courier)"
bin/rails runner "
  s = User.create!(email: '$SELLER_EMAIL', password: '$PASSWORD', full_name: 'Smoke Seller')
  RoleAssignment.create!(user: s, role: 'seller')
  c = User.create!(email: '$COURIER_EMAIL', password: '$PASSWORD', full_name: 'Smoke Courier')
  RoleAssignment.create!(user: c, role: 'courier')
" >/dev/null 2>&1 || fail "criacao de users de apoio falhou"

step "subir servidor em :$PORT"
bin/rails server -p "$PORT" >"$LOG" 2>&1 &
SERVER_PID=$!
trap 'kill $SERVER_PID 2>/dev/null || true' EXIT

step "aguardar readiness"
for _ in $(seq 1 60); do
  http GET "/healthz"
  [ "$CODE" = "200" ] && break
  sleep 1
done
[ "$CODE" = "200" ] || fail "healthz não respondeu 200: $BODY"

# -------------------------------------------------------------------- A. auth
step "A. registro e login (customer)"
http POST "/api/v1/auth/register" "{\"email\":\"$CUSTOMER_EMAIL\",\"password\":\"$PASSWORD\",\"full_name\":\"Smoke Customer\"}"
expect_code 201 "register customer"
CUSTOMER_TOKEN="$(json '.data.token')"
[ -n "$CUSTOMER_TOKEN" ] || fail "register não retornou token"
pass "register customer -> token"

http POST "/api/v1/auth/login" "{\"email\":\"$ADMIN_EMAIL\",\"password\":\"$ADMIN_PASSWORD\"}"
expect_code 200 "login admin"
ADMIN_TOKEN="$(json '.data.token')"
[ -n "$ADMIN_TOKEN" ] || fail "login admin não retornou token"
pass "login admin"

http POST "/api/v1/auth/login" "{\"email\":\"$SELLER_EMAIL\",\"password\":\"$PASSWORD\"}"
expect_code 200 "login seller"
SELLER_TOKEN="$(json '.data.token')"
pass "login seller"

http POST "/api/v1/auth/login" "{\"email\":\"$COURIER_EMAIL\",\"password\":\"$PASSWORD\"}"
expect_code 200 "login courier"
COURIER_TOKEN="$(json '.data.token')"
pass "login courier"

http GET "/api/v1/auth/me" "" "$CUSTOMER_TOKEN"
expect_code 200 "auth/me"
[ "$(json '.data.email')" = "$CUSTOMER_EMAIL" ] || fail "auth/me email incorreto"
pass "auth/me"

# ---------------------------------------------------------------- B. seller
step "B. onboarding, aprovação, catálogo e inventário"
http POST "/api/v1/seller/onboarding" "{\"name\":\"Smoke Store\",\"contact_email\":\"store@smoke.example\"}" "$SELLER_TOKEN"
expect_code 201 "seller onboarding"
SELLER_ID="$(json '.data.id')"
[ "$(json '.data.moderation_state')" = "pending_review" ] || fail "onboarding state incorreto"
pass "seller onboarding ($SELLER_ID)"

http POST "/api/v1/admin/sellers/$SELLER_ID/approve" "" "$ADMIN_TOKEN"
expect_code 200 "admin approve seller"
pass "admin aprova seller"

http POST "/api/v1/seller/categories" "{\"name\":\"Smoke Category\",\"position\":1}" "$SELLER_TOKEN"
expect_code 201 "category create"
CATEGORY_ID="$(json '.data.id')"
pass "category criada ($CATEGORY_ID)"

http POST "/api/v1/seller/products" "{\"category_id\":\"$CATEGORY_ID\",\"name\":\"Smoke Product\",\"price_cents\":1000,\"currency\":\"BRL\"}" "$SELLER_TOKEN"
expect_code 201 "product create"
PRODUCT_ID="$(json '.data.id')"
pass "product criado ($PRODUCT_ID)"

http PATCH "/api/v1/seller/inventory/$PRODUCT_ID" "{\"quantity\":10}" "$SELLER_TOKEN"
expect_code 200 "inventory update"
pass "inventory atualizado"

# ------------------------------------------------------------- public A→B
step "B. descoberta pública"
http GET "/api/v1/public/sellers"
expect_code 200 "public sellers"
echo "$BODY" | jq -e --arg id "$SELLER_ID" '.data | any(.id == $id)' >/dev/null || fail "seller não listado publicamente"
pass "public sellers lista a loja"

http GET "/api/v1/public/products/$PRODUCT_ID"
expect_code 200 "public product show"
pass "public product show"

# --------------------------------------------------------------- C. checkout
step "C. carrinho, endereço e checkout"
http POST "/api/v1/customer/cart/items" "{\"product_id\":\"$PRODUCT_ID\",\"quantity\":2}" "$CUSTOMER_TOKEN"
expect_code 201 "cart item add"
pass "item adicionado ao carrinho"

http POST "/api/v1/customer/addresses" "{\"name\":\"Casa\",\"line1\":\"Rua Smoke 100\",\"city\":\"São Paulo\",\"state\":\"SP\",\"zip\":\"01000-000\",\"country\":\"BR\"}" "$CUSTOMER_TOKEN"
expect_code 201 "address create"
ADDRESS_ID="$(json '.data.id')"
pass "endereço criado ($ADDRESS_ID)"

http POST "/api/v1/customer/checkout" "{\"address_id\":\"$ADDRESS_ID\"}" "$CUSTOMER_TOKEN" "Idempotency-Key: smoke-checkout-1"
expect_code 201 "checkout create"
ORDER_ID="$(json '.data.id')"
pass "checkout -> order ($ORDER_ID)"

step "C. replay do checkout com a mesma Idempotency-Key (sem duplicação)"
BEFORE_ORDERS="$(bin/rails runner "puts Order.count" 2>/dev/null)"
http POST "/api/v1/customer/checkout" "{\"address_id\":\"$ADDRESS_ID\"}" "$CUSTOMER_TOKEN" "Idempotency-Key: smoke-checkout-1"
[ "$CODE" = "200" ] || [ "$CODE" = "201" ] || fail "replay checkout: HTTP $CODE: $BODY"
REPLAY_ORDER_ID="$(json '.data.id')"
[ "$REPLAY_ORDER_ID" = "$ORDER_ID" ] || fail "replay retornou order diferente: $REPLAY_ORDER_ID != $ORDER_ID"
AFTER_ORDERS="$(bin/rails runner "puts Order.count" 2>/dev/null)"
[ "$BEFORE_ORDERS" = "$AFTER_ORDERS" ] || fail "replay duplicou order: $BEFORE_ORDERS -> $AFTER_ORDERS"
pass "replay checkout idempotente (mesmo order, sem duplicação)"

# ---------------------------------------------------------------- D. payment
step "D. confirmação de pagamento (admin)"
PAYMENT_ID="$(bin/rails runner "puts Payment.where(order_id: '$ORDER_ID').first&.id" 2>/dev/null)"
[ -n "$PAYMENT_ID" ] || fail "payment não encontrado para order $ORDER_ID"
http POST "/api/v1/admin/payments/$PAYMENT_ID/confirm" "" "$ADMIN_TOKEN"
expect_code 200 "admin confirm payment"
pass "pagamento confirmado ($PAYMENT_ID)"

# ------------------------------------------------------- E. seller fulfilment
step "E. fulfillment do seller"
http POST "/api/v1/seller/orders/$ORDER_ID/accept" "" "$SELLER_TOKEN"
expect_code 200 "seller accept"
pass "seller aceita pedido"

http POST "/api/v1/seller/orders/$ORDER_ID/preparing" "" "$SELLER_TOKEN"
expect_code 200 "seller preparing"
pass "seller preparando"

http POST "/api/v1/seller/orders/$ORDER_ID/ready" "" "$SELLER_TOKEN"
expect_code 200 "seller ready"
pass "seller pronto"

# ------------------------------------------------------------- F. courier
step "F. onboarding, aprovação e entrega"
http POST "/api/v1/courier/onboarding" "{\"phone\":\"+5511988887777\",\"document_number\":\"11122233344\",\"vehicle_type\":\"motorcycle\",\"vehicle_plate\":\"SMK0001\",\"location_consent\":true}" "$COURIER_TOKEN"
expect_code 201 "courier onboarding"
COURIER_ID="$(json '.data.id')"
pass "courier onboarding ($COURIER_ID)"

http POST "/api/v1/admin/couriers/$COURIER_ID/approve" "" "$ADMIN_TOKEN"
expect_code 200 "admin approve courier"
pass "admin aprova courier"

http PATCH "/api/v1/courier/availability" "{\"state\":\"available\"}" "$COURIER_TOKEN"
expect_code 200 "courier availability"
pass "courier disponível"

http GET "/api/v1/courier/orders/eligible" "" "$COURIER_TOKEN"
expect_code 200 "courier eligible"
echo "$BODY" | jq -e --arg id "$ORDER_ID" '.data | any(.id == $id)' >/dev/null || fail "order não elegível para o courier"
pass "order elegível"

http POST "/api/v1/courier/orders/$ORDER_ID/accept" "" "$COURIER_TOKEN" "Idempotency-Key: smoke-accept-1"
expect_code 200 "courier accept"
pass "courier aceita entrega"

http POST "/api/v1/courier/orders/$ORDER_ID/pickup" "" "$COURIER_TOKEN" "Idempotency-Key: smoke-pickup-1"
expect_code 200 "courier pickup"
pass "courier coleta"

http POST "/api/v1/courier/orders/$ORDER_ID/deliver" "" "$COURIER_TOKEN" "Idempotency-Key: smoke-deliver-1"
expect_code 200 "courier deliver"
pass "courier entrega"

# -------------------------------------------------------------- G. tracking
step "G. tracking do cliente"
http GET "/api/v1/customer/orders/$ORDER_ID/tracking" "" "$CUSTOMER_TOKEN"
expect_code 200 "customer tracking"
[ "$(json '.data.order_state')" = "delivered" ] || fail "order_state != delivered: $BODY"
pass "tracking delivered"

# --------------------------------------------------------------- H. support
step "H. ticket de suporte"
http POST "/api/v1/customer/tickets" "{\"subject\":\"Smoke ticket\",\"initial_message\":\"Preciso de ajuda\"}" "$CUSTOMER_TOKEN"
expect_code 201 "customer ticket"
TICKET_ID="$(json '.data.id')"
pass "ticket criado ($TICKET_ID)"

http POST "/api/v1/admin/tickets/$TICKET_ID/start_progress" "" "$ADMIN_TOKEN"
expect_code 200 "admin start_progress"
pass "admin inicia atendimento"

http POST "/api/v1/admin/tickets/$TICKET_ID/resolve" "" "$ADMIN_TOKEN"
expect_code 200 "admin resolve ticket"
pass "admin resolve ticket"

# ------------------------------------------------------------------ I. admin
step "I. operações administrativas"
http GET "/api/v1/admin/dashboard" "" "$ADMIN_TOKEN"
expect_code 200 "admin dashboard"
pass "admin dashboard"

http GET "/api/v1/admin/users" "" "$ADMIN_TOKEN"
expect_code 200 "admin users"
pass "admin users"

http GET "/api/v1/admin/observability/summary" "" "$ADMIN_TOKEN"
expect_code 200 "admin observability"
pass "admin observability"

http POST "/api/v1/admin/settings" "{\"key\":\"platform_fee_percent\",\"value\":\"10.0\",\"reason\":\"smoke\",\"effective_at\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" "$ADMIN_TOKEN"
expect_code 201 "admin settings"
pass "admin settings"

http POST "/api/v1/admin/invoices/generate" "{\"seller_id\":\"$SELLER_ID\",\"period_start\":\"$(date -u +%Y-%m-01)\",\"period_end\":\"$(date -u +%Y-%m-%d)\"}" "$ADMIN_TOKEN"
expect_code 201 "admin invoice generate"
pass "admin invoice generate"

# ------------------------------------------------------------- cross-role
step "J. cross-role denial"
http GET "/api/v1/admin/dashboard" "" "$CUSTOMER_TOKEN"
expect_code 403 "customer->admin forbidden"
pass "customer não acessa admin"

http POST "/api/v1/seller/onboarding" "{\"name\":\"Nope\"}" "$CUSTOMER_TOKEN"
expect_code 403 "customer->seller forbidden"
pass "customer não acessa seller"

http GET "/api/v1/courier/orders/eligible" "" "$CUSTOMER_TOKEN"
expect_code 403 "customer->courier forbidden"
pass "customer não acessa courier"

# ------------------------------------------------------------ disabled user
step "K. disabled user"
http POST "/api/v1/auth/register" "{\"email\":\"smoke.victim@example.com\",\"password\":\"$PASSWORD\",\"full_name\":\"Smoke Victim\"}"
expect_code 201 "register victim"
VICTIM_TOKEN="$(json '.data.token')"
VICTIM_ID="$(json '.data.user.id')"

http POST "/api/v1/admin/users/$VICTIM_ID/disable" "" "$ADMIN_TOKEN"
expect_code 200 "admin disable victim"
pass "admin desabilita usuário"

http GET "/api/v1/auth/me" "" "$VICTIM_TOKEN"
expect_code 401 "disabled token rejected"
pass "token do usuário desabilitado é rejeitado"

# ------------------------------------------------------------------- done
echo
log "Smoke concluído: $STEP steps, $PASS verificações."
echo "JaChegai Rails backend smoke test passed"

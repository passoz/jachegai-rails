# JaChegai MVP Implementation Plan

> **For Hermes:** execute this plan only after Fernando confirms the model/provider for coding. Use vertical slices, not horizontal architecture tourism.

**Goal:** ship a working JaChegai MVP as a single Go binary + single Docker image, with dedicated `landing`, `customer`, `seller`, `courier`, and `admin` apps backed by one `net/http` + SQLite monolith.

**Architecture:** one Go process owns API/BFF, auth/session, static frontend serving, SQLite persistence, local uploads, and internal outbox workers. The frontend is a unified workspace with dedicated apps per actor and shared packages for UI, API client, and config. Legacy code under `legacy/` is evidence only.

**Tech Stack:** Go 1.26+, stdlib `net/http`, SQLite (`WAL`, `foreign_keys=ON`), `sqlc`, UUIDv7, interface-first stores, React + Vite + TypeScript, PWA-first, Capacitor later, Docker single image.

---

## 0. Non-Negotiable Rules

1. **Do not touch `legacy/` except for reading.**
2. **Do not introduce** chi/gin/echo/fiber, GORM/Ent/sqlx, APISIX, Keycloak, NATS, RabbitMQ, Kafka, ELK, Kubernetes, Helm.
3. **Every DB operation goes through `sqlc`.**
4. **Every primary entity uses UUIDv7.**
5. **Every HTTP response follows the repo contract.**
6. **Every phase ends with a demoable vertical slice.**
7. **Keep handlers thin; business rules live in services.**
8. **Prefer one obvious pattern everywhere over framework cleverness.**

---

## 1. Delivery Strategy

Build in this exact order:

1. app shell and operational baseline
2. SQLite + migrations + `sqlc` foundation
3. auth + sessions
4. seller onboarding and profile
5. catalog + public discovery + public cart entry
6. customer account + addresses + authenticated cart + checkout
7. order workflow for seller
8. outbox + internal jobs
9. courier assignment + live tracking
10. admin ops + taxes + support + observability
11. frontend workspace + actor apps
12. single-image build + smoke script + MVP verification

**Why this order:** every new phase stands on a real previous flow. We do not build “platform infrastructure” without product behavior to justify it.

---

## 2. Canonical Directory Shape

```text
cmd/jachegai/
internal/app/
internal/httpapi/
internal/db/
internal/auth/
internal/sellers/
internal/catalog/
internal/customers/
internal/orders/
internal/payments/
internal/couriers/
internal/admin/
internal/support/
internal/taxes/
internal/outbox/
internal/storage/
internal/web/
migrations/sqlite/
queries/sqlite/
web/apps/landing/
web/apps/customer/
web/apps/seller/
web/apps/courier/
web/apps/admin/
web/packages/ui/
web/packages/api/
web/packages/config/
scripts/
```

---

## 3. Canonical Backend Patterns

### 3.1 HTTP handler shape

```go
type Handler struct {
    service *Service
}

func (h *Handler) Create(w http.ResponseWriter, r *http.Request) {
    ctx := r.Context()

    var input CreateInput
    if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
        writeError(w, r, http.StatusBadRequest, "invalid_json", "invalid request body")
        return
    }

    out, err := h.service.Create(ctx, input)
    if err != nil {
        writeDomainError(w, r, err)
        return
    }

    writeJSON(w, http.StatusCreated, map[string]any{
        "ok":   true,
        "data": out,
        "meta": map[string]any{},
    })
}
```

### 3.2 Service shape

```go
type Service struct {
    repo Repository
    clock Clock
    ids   IDGenerator
}
```

The service:
- validates business input
- enforces ownership and transitions
- coordinates repositories
- emits outbox events when needed

The service does **not**:
- know about HTTP
- write raw SQL
- read env vars directly

### 3.3 Repository boundary

```go
type SellerRepository interface {
    Create(ctx context.Context, params CreateSellerParams) (Seller, error)
    GetByUserID(ctx context.Context, userID string) (Seller, error)
    Update(ctx context.Context, params UpdateSellerParams) (Seller, error)
}
```

Concrete implementation lives near `sqlc` queries, but code outside the package depends on the interface.

### 3.4 JSON response contract

Success:

```json
{"ok":true,"data":{},"meta":{}}
```

Error:

```json
{"ok":false,"error":{"code":"validation_error","message":"invalid request","request_id":"..."}}
```

### 3.5 SQL organization

- `migrations/sqlite/*.sql` for schema
- `queries/sqlite/*.sql` for `sqlc`
- generated code under `internal/db/sqlitegen/` or equivalent chosen path
- one query file per domain when possible: `auth.sql`, `sellers.sql`, `catalog.sql`, `orders.sql`, etc.

### 3.6 Testing baseline

For every backend slice:
- service tests for business rules
- handler tests for HTTP contract
- migration test or startup verification when schema changes

Required commands after each slice:

```bash
go test ./...
go build ./...
```

---

## 4. Lean MVP Backlog Cut

To control token burn, not every issue should be treated as the same priority.

### 4.1 Must-have for the first real MVP

These are the only slices that should be implemented before calling the product minimally shippable:

1. MVP-01 — App shell, config, healthcheck, request ID, JSON helpers
2. MVP-02 — SQLite foundation, migrations, `sqlc`, UUIDv7 base schema
3. MVP-03 — Auth, sessions, role guards, admin bootstrap
4. MVP-04 — Seller onboarding, profile, settings
5. MVP-05 — Catalog, inventory, public discovery, public cart entry
6. MVP-06 — Customer profile, addresses, authenticated cart, checkout, payment record
7. MVP-07 — Seller order handling and transition rules
8. MVP-09 — Courier onboarding, delivery workflow, tracking API
9. MVP-10 — Admin dashboard, moderation, basic settings/ops visibility
10. MVP-11 — Minimal frontend surfaces for `landing`, `customer`, `seller`, `courier`, `admin`
11. MVP-12 — Static serving + Docker single image + `/data` layout
12. MVP-13 — Smoke script + MVP completion gate

### 4.2 Should-have if budget and momentum are healthy

These help quality and maintainability, but can wait until after the first end-to-end MVP loop works:

- MVP-08 — SQLite outbox and internal background jobs
- Frontend workspace polish beyond the minimal actor surfaces required by MVP-11

### 4.3 After-MVP / only pull forward if pain appears

The following sub-areas must not expand early unless a real blocker justifies them:

- advanced support workflows beyond ticket minimum
- invoice/fiscal depth beyond basic tax settings and invoice listing
- PWA polish beyond what is needed to prove flow
- any real-time transport more complex than simple polling
- any mobile packaging work with Capacitor

### 4.4 Token cost bands (planning heuristic, not a guarantee)

Use this scale before implementation:

- **XS** — tiny local change, very low context load
- **S** — single package or narrow behavior
- **M** — one vertical slice with 2-4 packages and tests
- **L** — cross-package backend slice with migrations/tests/integration points
- **XL** — backend + frontend or major workflow orchestration

### 4.5 Estimated token pressure by issue

| Issue | Priority | Token pressure | Why |
|---|---|---:|---|
| MVP-01 | must-have | S | low surface area, mostly bootstrap |
| MVP-02 | must-have | L | schema + migrations + `sqlc` setup create broad context |
| MVP-03 | must-have | M | auth/session touches DB + HTTP + tests |
| MVP-04 | must-have | S | narrow seller slice |
| MVP-05 | must-have | L | catalog + public flow + inventory |
| MVP-06 | must-have | XL | checkout is the densest core transaction |
| MVP-07 | must-have | M | transition rules are focused but important |
| MVP-08 | should-have | M | useful, but deferrable until pain exists |
| MVP-09 | must-have | L | courier flow + tracking data path |
| MVP-10 | must-have | L | many endpoints, but can be kept intentionally ugly/simple |
| MVP-11 | must-have | L | frontend exists in MVP, but keep it minimal and avoid workspace polish early |
| MVP-12 | must-have | M | static serving + Docker are bounded |
| MVP-13 | must-have | M | smoke script touches the full API but in one place |

### 4.6 Recommended execution order for cheapest learning

If we optimize for learning-per-token instead of completeness-per-token:

1. MVP-01
2. MVP-02
3. MVP-03
4. MVP-04
5. MVP-05
6. MVP-06
7. Stop and reassess actual token burn
8. MVP-07
9. MVP-09
10. MVP-10
11. MVP-11
12. MVP-12
13. MVP-13
14. Only then consider MVP-08

---

## 5. Issue Map

This plan maps to the following GitHub issues:

1. MVP-01 — App shell, config, healthcheck, request ID, JSON helpers
2. MVP-02 — SQLite foundation, migrations, `sqlc`, UUIDv7 base schema
3. MVP-03 — Auth, sessions, role guards, admin bootstrap
4. MVP-04 — Seller onboarding, profile, settings
5. MVP-05 — Catalog, categories, inventory, public discovery, public cart entry
6. MVP-06 — Customer profile, addresses, authenticated cart, checkout, payment record
7. MVP-07 — Seller order handling and transition rules
8. MVP-08 — SQLite outbox and internal background jobs
9. MVP-09 — Courier onboarding, delivery workflow, live tracking
10. MVP-10 — Admin ops + taxes + support + observability
11. MVP-11 — Frontend workspace + actor apps
12. MVP-12 — Static serving + Docker single image + `/data` layout
13. MVP-13 — Smoke script + MVP completion gate

---

## 6. Phase-by-Phase Plan

## Phase 1 — App Shell and Operational Baseline

**Issue:** MVP-01

**Objective:** start a Go server cleanly, expose `/healthz`, standardize config, request IDs, and JSON/error helpers.

**Files to create**
- `go.mod`
- `cmd/jachegai/main.go`
- `internal/app/app.go`
- `internal/app/config.go`
- `internal/httpapi/server.go`
- `internal/httpapi/middleware.go`
- `internal/httpapi/respond.go`
- `internal/httpapi/errors.go`
- `internal/httpapi/server_test.go`

**Steps**
1. initialize the module and choose the final module path
2. create config loader with sane defaults:
   - `JACHEGAI_ADDR=:8080`
   - `JACHEGAI_ENV=dev`
   - `JACHEGAI_DATA_DIR=/data`
   - `JACHEGAI_DB_PATH=/data/jachegai.db`
3. create app bootstrap that wires config → logger → server
4. implement `/healthz`
5. add request ID middleware and return `X-Request-ID`
6. add structured log output to stdout
7. create JSON response helpers for success and error shapes
8. add tests for `/healthz` and response helpers

**Acceptance criteria**
- `go run ./cmd/jachegai` starts the app
- `GET /healthz` returns 200 with `{"ok":true}` envelope
- every response includes `X-Request-ID`
- logs include method, path, status, duration, request ID
- no dependency on external router/framework

**Verification**

```bash
go test ./...
go run ./cmd/jachegai
curl -i http://localhost:8080/healthz
```

---

## Phase 2 — SQLite Foundation, Migrations, and sqlc

**Issue:** MVP-02

**Objective:** make SQLite the single source of truth for the MVP, with a schema strong enough to support all actor flows.

**Files to create**
- `sqlc.yaml`
- `internal/db/db.go`
- `internal/db/migrate.go`
- `internal/db/tx.go`
- `internal/db/db_test.go`
- `migrations/sqlite/001_init.sql`
- `queries/sqlite/auth.sql`
- `queries/sqlite/sellers.sql`
- `queries/sqlite/catalog.sql`
- `queries/sqlite/customers.sql`
- `queries/sqlite/orders.sql`
- `queries/sqlite/couriers.sql`
- `queries/sqlite/admin.sql`
- `queries/sqlite/support.sql`
- `queries/sqlite/taxes.sql`

**Schema minimum**
- `users`
- `sessions`
- `sellers`
- `seller_users`
- `customers`
- `customer_addresses`
- `couriers`
- `categories`
- `products`
- `inventory_items`
- `carts`
- `cart_items`
- `orders`
- `order_items`
- `order_status_history`
- `payments`
- `favorites`
- `support_tickets`
- `support_messages`
- `tax_settings`
- `invoices`
- `uploads`
- `outbox_events`
- `audit_logs`
- `courier_locations`

**Steps**
1. wire SQLite open/close with WAL and foreign keys enabled
2. implement migration runner and schema version tracking
3. write initial migration with all base tables and indexes
4. define `sqlc` config and generate code
5. create a minimal transaction helper for service orchestration
6. add startup migration execution in app bootstrap
7. test fresh DB startup and migration idempotency

**Acceptance criteria**
- app creates or opens `/data/jachegai.db`
- startup runs migrations automatically
- foreign keys are enforced
- WAL mode is active
- `sqlc generate` succeeds
- queries compile inside `go test ./...`
- all main tables use UUIDv7 string-compatible IDs

**Verification**

```bash
sqlc generate
go test ./...
go run ./cmd/jachegai
```

---

## Phase 3 — Auth, Sessions, Roles, Admin Bootstrap

**Issue:** MVP-03

**Objective:** support login/logout/current-user flows with HttpOnly cookies and role-based route protection.

**Files to create**
- `internal/auth/model.go`
- `internal/auth/store.go`
- `internal/auth/service.go`
- `internal/auth/password.go`
- `internal/auth/session.go`
- `internal/auth/http.go`
- `internal/auth/middleware.go`
- `internal/auth/service_test.go`
- `internal/auth/http_test.go`

**Routes**
- `POST /api/auth/register`
- `POST /api/auth/login`
- `POST /api/auth/logout`
- `GET /api/auth/me`

**Steps**
1. define roles: `customer`, `seller`, `courier`, `admin`
2. implement password hashing and verification
3. create registration service with duplicate-email rejection
4. implement session persistence in SQLite
5. set HttpOnly cookie on login and clear on logout
6. implement current-user lookup middleware
7. add role guard helper for seller/courier/admin routes
8. implement first-admin bootstrap using env vars
9. test auth success/failure paths and cookie behavior

**Acceptance criteria**
- passwords are never stored in plaintext
- duplicate email returns validation error
- session cookie is HttpOnly and server-managed
- protected endpoints can resolve current user from cookie
- admin bootstrap creates the first admin exactly once
- `GET /api/auth/me` returns current user when authenticated

**Verification**

```bash
go test ./...
```

---

## Phase 4 — Seller Onboarding, Profile, Settings

**Issue:** MVP-04

**Objective:** let a seller create a store presence and maintain its core business info.

**Files to create**
- `internal/sellers/model.go`
- `internal/sellers/store.go`
- `internal/sellers/service.go`
- `internal/sellers/http.go`
- `internal/sellers/service_test.go`
- `internal/sellers/http_test.go`

**Routes**
- `POST /api/seller/onboarding`
- `GET /api/seller/profile`
- `PUT /api/seller/profile`
- `GET /api/seller/settings`
- `PUT /api/seller/settings`

**Steps**
1. define seller profile and seller settings structures
2. implement onboarding service linked to authenticated user
3. enforce one seller profile per seller user for MVP
4. implement profile fetch/update
5. implement settings fetch/update
6. add ownership checks in all seller handlers
7. test unauthorized, forbidden, and happy paths

**Acceptance criteria**
- authenticated seller user can complete onboarding
- seller profile persists in SQLite
- seller can read/update own profile only
- seller settings are stored and returned consistently
- admin/customer/courier cannot call seller-only endpoints successfully

---

## Phase 5 — Catalog, Inventory, Public Discovery, Public Cart Entry

**Issue:** MVP-05

**Objective:** let sellers publish products and let the public start shopping without premature login.

**Files to create**
- `internal/catalog/model.go`
- `internal/catalog/store.go`
- `internal/catalog/service.go`
- `internal/catalog/http_seller.go`
- `internal/catalog/http_public.go`
- `internal/catalog/service_test.go`
- `internal/catalog/http_test.go`

**Routes**
- `GET /api/public/sellers`
- `GET /api/public/sellers/{sellerID}/products`
- `GET /api/public/cart`
- `POST /api/public/cart/items`
- `POST /api/seller/categories`
- `GET /api/seller/categories`
- `POST /api/seller/products`
- `GET /api/seller/products`
- `PUT /api/seller/products/{id}`
- `DELETE /api/seller/products/{id}`
- `GET /api/seller/inventory`
- `PUT /api/seller/inventory/{productID}`

**Steps**
1. create category CRUD minimum needed for seller catalog
2. create product CRUD with seller ownership enforcement
3. create inventory records and update endpoint
4. implement public seller list and public product list
5. implement public cart state for pre-auth shopping journey
6. ensure public cart can later be converted into authenticated cart context
7. test product visibility, inventory updates, and public cart basics

**Acceptance criteria**
- seller can create/list/update/delete products
- public API can list sellers and products
- public cart can add and read items before login
- inventory state affects purchasable products
- seller cannot edit another seller’s catalog

---

## Phase 6 — Customer Profile, Addresses, Authenticated Cart, Checkout

**Issue:** MVP-06

**Objective:** let a logged-in customer manage delivery data, build a cart, and place an order.

**Files to create**
- `internal/customers/model.go`
- `internal/customers/store.go`
- `internal/customers/service.go`
- `internal/customers/http.go`
- `internal/orders/cart.go`
- `internal/orders/order.go`
- `internal/orders/service.go`
- `internal/orders/http_customer.go`
- `internal/payments/service.go`
- `internal/orders/service_test.go`
- `internal/orders/http_customer_test.go`

**Routes**
- `GET /api/customer/profile`
- `PUT /api/customer/profile`
- `GET /api/customer/addresses`
- `POST /api/customer/addresses`
- `PUT /api/customer/addresses/{id}`
- `DELETE /api/customer/addresses/{id}`
- `GET /api/customer/cart`
- `POST /api/customer/cart/items`
- `PUT /api/customer/cart/items/{id}`
- `DELETE /api/customer/cart/items/{id}`
- `POST /api/customer/checkout`
- `GET /api/customer/orders`
- `GET /api/customer/orders/{id}`

**Steps**
1. implement customer profile and address storage
2. implement authenticated cart independent from public cart shape
3. define cart validation rules: seller consistency, quantity, inventory
4. implement checkout transaction:
   - snapshot cart into order/order_items
   - create payment record
   - create initial order status history row
   - clear cart on success
5. expose customer order list/detail endpoints
6. test address ownership, cart operations, checkout transaction, and order retrieval

**Acceptance criteria**
- customer can maintain addresses
- customer cart supports add/update/remove
- checkout creates order, items, payment row, and initial status history atomically
- cart clears only after successful order creation
- customer can view own orders and not others’ orders

---

## Phase 7 — Seller Order Handling and Transition Rules

**Issue:** MVP-07

**Objective:** give the seller a real order operations workflow with explicit transition control.

**Files to create**
- `internal/orders/http_seller.go`
- `internal/orders/transitions.go`
- `internal/orders/transitions_test.go`

**Routes**
- `GET /api/seller/orders`
- `GET /api/seller/orders/{id}`
- `POST /api/seller/orders/{id}/accept`
- `POST /api/seller/orders/{id}/reject`
- `POST /api/seller/orders/{id}/preparing`
- `POST /api/seller/orders/{id}/ready`

**Steps**
1. codify valid order transitions in one place
2. enforce seller ownership of the order
3. append `order_status_history` on every change
4. reject invalid transitions with domain errors
5. expose seller order list/detail views
6. test transition matrix thoroughly

**Acceptance criteria**
- seller sees only own orders
- invalid transitions fail deterministically
- every valid transition appends history
- order detail returns current state plus history

---

## Phase 8 — SQLite Outbox and Internal Jobs

**Issue:** MVP-08

**Objective:** add safe internal async processing without introducing external brokers.

**Files to create**
- `internal/outbox/model.go`
- `internal/outbox/store.go`
- `internal/outbox/service.go`
- `internal/outbox/worker.go`
- `internal/outbox/handlers.go`
- `internal/outbox/service_test.go`

**Initial events**
- `order.created`
- `order.status_changed`
- `support.ticket_created`

**Steps**
1. define outbox row format with attempts, status, available_at, last_error
2. create helper to write business change + outbox event in the same transaction
3. implement polling worker with bounded retry
4. implement idempotent handlers for initial events
5. add startup wiring for goroutine worker in main app
6. test retry and idempotency behavior

**Acceptance criteria**
- order creation can persist an outbox event atomically
- worker processes pending events without a separate service
- failures are retried and last error is recorded
- handlers are idempotent
- app still runs as one process

---

## Phase 9 — Courier Workflow and Live Tracking

**Issue:** MVP-09

**Objective:** let couriers operate deliveries and let customers track them.

**Files to create**
- `internal/couriers/model.go`
- `internal/couriers/store.go`
- `internal/couriers/service.go`
- `internal/couriers/http.go`
- `internal/couriers/location.go`
- `internal/couriers/service_test.go`
- `internal/orders/http_courier.go`

**Routes**
- `POST /api/courier/onboarding`
- `GET /api/courier/profile`
- `PUT /api/courier/profile`
- `POST /api/courier/availability`
- `GET /api/courier/deliveries`
- `POST /api/courier/deliveries/{orderID}/accept`
- `POST /api/courier/deliveries/{orderID}/picked-up`
- `POST /api/courier/deliveries/{orderID}/delivered`
- `POST /api/courier/location`
- `GET /api/courier/stats`
- `GET /api/customer/orders/{id}/tracking`

**Steps**
1. implement courier onboarding/profile
2. implement availability toggle
3. expose list of assignable/current deliveries
4. enforce courier delivery transitions
5. create courier location write path
6. create customer tracking read path with latest known location
7. test courier ownership and tracking visibility

**Acceptance criteria**
- courier can onboard and mark availability
- courier can accept and complete valid deliveries
- customer can fetch tracking data for own order
- tracking payload includes delivery status and latest location when available

---

## Phase 10 — Admin Ops, Taxes, Support, Observability

**Issue:** MVP-10

**Objective:** restore the operational spine of the business without dragging in corporate infra.

**Files to create**
- `internal/admin/service.go`
- `internal/admin/http.go`
- `internal/admin/observability.go`
- `internal/support/model.go`
- `internal/support/store.go`
- `internal/support/service.go`
- `internal/support/http.go`
- `internal/taxes/model.go`
- `internal/taxes/store.go`
- `internal/taxes/service.go`
- `internal/taxes/http.go`
- tests for the above

**Routes**
- `GET /api/admin/dashboard`
- `GET /api/admin/users`
- `GET /api/admin/users/{id}`
- `GET /api/admin/sellers`
- `POST /api/admin/sellers/{id}/approve`
- `POST /api/admin/sellers/{id}/block`
- `GET /api/admin/couriers`
- `POST /api/admin/couriers/{id}/approve`
- `POST /api/admin/couriers/{id}/block`
- `GET /api/admin/orders`
- `GET /api/admin/orders/{id}`
- `GET /api/admin/settings`
- `PUT /api/admin/settings`
- `GET /api/admin/tax-settings`
- `PUT /api/admin/tax-settings`
- `GET /api/admin/invoices`
- `GET /api/admin/invoices/{id}`
- `GET /api/admin/support/tickets`
- `GET /api/admin/support/tickets/{id}`
- `GET /api/admin/observability/summary`
- `GET /api/admin/observability/requests`
- `GET /api/admin/observability/orders`

**Steps**
1. implement admin dashboard summary from existing business tables
2. implement seller/courier moderation actions
3. implement basic admin user/order listings
4. implement support ticket list/detail
5. implement tax settings + invoice list minimum
6. implement observability summary using request/order/application counters already available in process or DB
7. test role guards and list/detail endpoints

**Acceptance criteria**
- admin can moderate sellers and couriers
- admin can inspect users and orders
- tax settings are editable
- support tickets are visible to admin
- observability endpoints return useful operational summaries
- non-admin users are blocked from admin APIs

---

## Phase 11 — Frontend Workspace and Actor Apps

**Issue:** MVP-11

**Objective:** create the dedicated product surfaces while keeping one deployable system.

**Files/directories to create**
- `web/package.json`
- `web/pnpm-workspace.yaml` or equivalent chosen package-manager workspace file
- `web/apps/landing/`
- `web/apps/customer/`
- `web/apps/seller/`
- `web/apps/courier/`
- `web/apps/admin/`
- `web/packages/ui/`
- `web/packages/api/`
- `web/packages/config/`

**Frontend standards**
- relative `/api/...` calls only
- no JWT in localStorage
- mobile-first layouts
- shared design tokens/components where helpful
- separate route trees per actor app

**Pages minimum**
- `landing`: home, institutional pages, public seller discovery, public catalog, public cart entry
- `customer`: login/register, sellers, catalog, cart, checkout, orders, order detail, live tracking, favorites, support
- `seller`: login/register/onboarding, dashboard, profile, settings, products, inventory, orders
- `courier`: login/register/onboarding, dashboard, deliveries, current delivery, stats, profile
- `admin`: login, dashboard, users, sellers, couriers, orders, taxes/settings, invoices, support, observability

**Steps**
1. choose package manager and lock it in repo docs/config
2. scaffold workspace and shared packages
3. build a shared API client package matching backend envelopes
4. build each actor app shell and route tree
5. connect pages to live backend endpoints slice by slice
6. add PWA basics after routes work
7. run frontend build verification

**Acceptance criteria**
- all five apps exist in one frontend workspace
- each app has its own route shell and purpose-aligned pages
- apps talk to the Go API with relative paths
- frontend builds successfully
- no microfrontend deployment split

---

## Phase 12 — Static Serving and Single Docker Image

**Issue:** MVP-12

**Objective:** serve built frontend assets from Go and ship the whole stack as one image.

**Files to create**
- `internal/web/static.go`
- `Dockerfile`
- `.dockerignore`
- optional `scripts/build.sh`

**Steps**
1. define frontend build output paths for each app
2. add Go static serving with SPA fallback per actor app
3. keep `/api/*` reserved for API routes
4. add file caching headers for static assets
5. create multi-stage Dockerfile: frontend build → Go build → runtime image
6. ensure DB and uploads live under `/data`
7. verify local `docker run` experience

**Acceptance criteria**
- one container serves API and frontend assets
- actor app routes load correctly via browser refresh
- SQLite DB persists under mounted `/data`
- uploads path is under `/data/uploads`
- local docker run matches the target deployment model

**Verification**

```bash
docker build -t jachegai:local .
docker run --rm -p 8080:8080 -v jachegai_data:/data jachegai:local
```

---

## Phase 13 — Smoke Script and MVP Completion Gate

**Issue:** MVP-13

**Objective:** prove the system works end-to-end without hand-wavy “should work”.

**Files to create**
- `scripts/smoke.sh`
- optional fixture files under `scripts/fixtures/`

**Smoke flow**
1. boot app on a clean DB
2. bootstrap admin
3. register seller user
4. complete seller onboarding
5. approve seller as admin
6. create categories/products/inventory
7. register customer user
8. create customer address
9. create cart and checkout
10. seller accepts/prepares/readies order
11. register courier user
12. approve courier as admin
13. courier accepts/picks-up/delivers
14. customer reads tracking/order detail
15. admin sees final order/support/ops state

**Steps**
1. make the script deterministic and idempotent enough for local reruns on fresh DB
2. use API calls, not direct DB hacks
3. validate every step and stop on first broken contract
4. print a clean final success line

**Acceptance criteria**
- smoke script exits 0 on success
- smoke script fails loudly when any API contract breaks
- final line is `JaChegai MVP smoke test passed`
- MVP is only considered done when this script passes against the single-container app

---

## 6. Commit Strategy

Use small commits aligned to the issue slices. Suggested commit style:

- `feat(app): bootstrap server and healthcheck`
- `feat(db): add sqlite migrations and sqlc config`
- `feat(auth): add cookie sessions and me endpoint`
- `feat(sellers): add onboarding and profile endpoints`
- `feat(catalog): add product and public catalog flows`
- `feat(customers): add addresses cart and checkout`
- `feat(orders): add seller order transitions`
- `feat(outbox): add sqlite outbox worker`
- `feat(couriers): add delivery flow and tracking`
- `feat(admin): add ops dashboard and moderation`
- `feat(web): add actor apps workspace`
- `build(docker): serve frontend from single image`
- `test(smoke): add end-to-end MVP verification`

---

## 7. Definition of Done

JaChegai MVP is only done when all of this is true:

- Go app boots cleanly
- SQLite migrates automatically
- auth works with HttpOnly cookie
- seller can onboard and publish products
- public can browse and start cart assembly
- customer can checkout and create an order
- seller can progress the order
- courier can complete delivery and update location
- customer can view tracking/order detail
- admin can moderate and inspect ops state
- frontend apps build and are served by Go
- Docker single image works with `/data` volume
- smoke script passes end-to-end

If one of those is false, the MVP is not done.

---

## 8. Execution Gate

**Plan complete. Before coding starts, Fernando must confirm the execution model/provider.**

Recommended order by cost:
1. `openai-codex`
2. `DeepSeek`
3. `OpenCode Zen`

After model confirmation, execution should happen issue by issue, slice by slice, with verification after every slice.

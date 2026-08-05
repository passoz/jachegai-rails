# Rebuild Plan

## 2026-07-31 — Portable Technology-Agnostic Product Specification

**Status:** Completed; review required
**Model/provider:** current session model
**Goal:** Create a separate specification from which an implementation plan can be generated for any programming language, framework, identity provider, database, messaging mechanism, storage provider, or deployment platform.

### Plan

1. [x] Use `SPEC.md` as the product/domain source while excluding current implementation status and stack-specific constraints.
2. [x] Create `docs/PORTABLE_PRODUCT_SPEC.md` with product outcomes, actors, domain language, capabilities, workflows, state machines, logical contracts, conceptual data, security, quality attributes, and acceptance scenarios.
3. [x] Express external concerns through capabilities and standards (for example, identity protocols and provider interfaces) rather than named products.
4. [x] Add an implementation-decision worksheet so a planner can map the portable requirements to a chosen stack without changing product rules.
5. [x] Validate that forbidden concrete implementation names do not appear as normative choices and check document integrity.

### Validation outcome

- 29 numbered sections (`0` through `28`) plus a reusable planning prompt were created.
- 197 unique requirement IDs are present across all product, domain, security, reliability, UX, and test areas.
- Structural validation confirmed every requirement prefix is represented.
- Vendor/technology scan found no concrete language, framework, database, identity product, broker, cloud, container, payment, mapping, or UI product mandated.
- References to REST, GraphQL, OAuth, and OpenID Connect are explicitly alternatives or interoperable protocol examples, not mandatory choices.
- `git diff --check` passed.

### Completion evidence required

- The portable spec preserves the customer, seller, courier, and admin product flows.
- No programming language, framework, database product, identity product, broker, cloud, or container product is mandated.
- Product invariants and acceptance criteria are independently testable.
- Architecture selection points and a requirement-to-plan template are included.

---

## 2026-07-31 — System Specification Refresh

**Status:** Completed; review required
**Model/provider:** current session model
**Reason:** `SPEC.md` predates most of the active implementation and no longer records the current module architecture, shared UI contract, route catalog, quality gates, or known compliance gaps.

### Plan

1. [x] Audit `SPEC.md` against `AGENTS.md`, current code, migrations, frontend workspace, roadmap, local tasks, and open GitHub issues.
2. [x] Replace `SPEC.md` with a versioned active specification that separates normative requirements from implementation status.
3. [x] Formalize one unified React build/PWA with five dedicated product surfaces; no independently deployable microfrontends.
4. [x] Add domain vocabulary, role boundaries, functional requirements, order state machine, API route inventory, data rules, security requirements, operations, and acceptance criteria.
5. [x] Add a dated implementation-compliance snapshot that records verified passes and known failures without representing partial work as complete.
6. [x] Synchronize open remote issues into `.todo/issues.md`.
7. [x] Validate documentation consistency and rerun relevant backend/frontend checks.

### Validation outcome

- Backend: `go test ./... -count=1`, `go build ./...`, and `go vet ./...` passed.
- Frontend bundle/PWA: `cd web && npm run build` passed.
- Frontend strict typecheck: `cd web && npx tsc --noEmit` failed; recorded as a release blocker in `SPEC.md`.
- Frontend tests: `cd web && npm test` failed because the script/suite does not exist; recorded as a release blocker in `SPEC.md`.
- Route traceability: all 72 currently registered domain routes are represented in `SPEC.md`.
- Issue traceability: all 12 open remote issues are represented in `.todo/issues.md`.

### Completion evidence required

- `SPEC.md` has explicit version, date, status semantics, requirement IDs, and source-of-truth rules.
- Current routes and database entities are represented.
- Known gaps such as missing `/readyz`, graceful shutdown, structured logging, upload service, frontend typecheck failures, and frontend test coverage are explicit.
- Open GitHub issues are listed locally.
- Exact validation commands and results are recorded in the final handoff.

---

# Archived Implementation Plan: App God Object → Module Encapsulation

**Status:** Implemented, checklist below retained as historical planning evidence · **Original date:** 2025-07-19 · **Candidate:** #1 of the architecture review

---

## Resumo Executivo

**Problema:** `internal/app/app.go` expõe 25+ campos públicos. `New()` tem 100+ linhas de DI manual. `server.go` acessa cada campo individualmente. Adicionar um domínio toca 3 arquivos.

**Solução:** Cada domínio vira um `Module` autocontido com `RegisterRoutes(mux, authMW)`. `main.go` instancia os módulos e itera. `app.go` some.

**Decisões de design (do grilling):**

| Decisão | Escolha |
|---------|---------|
| Contrato do Module | Opção A: `RegisterRoutes(*http.ServeMux, *auth.Middleware)` |
| Wire-up | Opção A: Cada Module faz seu próprio wire-up |
| Dependências cross-module | Opção A: Módulo recebe interfaces mínimas (ex: `catalog.Store`) |
| Agrupamento de handlers | Opção A: Um Module por domínio (múltiplos handlers internos) |
| Middleware de auth | Opção A: Criado em `main.go`, injetado nos módulos |
| Health/SPA/Bootstrap | Opção A: `main.go` orquestra diretamente |
| Ordem de migração | 11 módulos em sequência: folhas primeiro, acoplados por último |

---

## Arquitetura Alvo

```
cmd/jachegai/main.go
  ├── cfg := app.LoadConfig()
  ├── sqlDB := db.Open(...)
  ├── db.Migrate(sqlDB, ...)
  │
  ├── authMod    := auth.NewModule(sqlDB)
  ├── catalogMod := catalog.NewModule(sqlDB)
  ├── sellerMod  := sellers.NewModule(sqlDB)
  ├── courierMod := couriers.NewModule(sqlDB)
  ├── customerMod:= customers.NewModule(sqlDB)
  ├── paymentMod := payments.NewModule()
  ├── outboxMod  := outbox.NewModule(sqlDB)
  ├── supportMod := support.NewModule(sqlDB)
  ├── taxesMod   := taxes.NewModule(sqlDB)
  ├── orderMod   := orders.NewModule(sqlDB, customerMod.Store(), catalogMod.Store(),
  │                  sellerMod.Store(), paymentMod.Service(), outboxMod.Service())
  ├── adminMod   := admin.NewModule(sqlDB, sellerMod.Store())
  │
  ├── authMW := authMod.Middleware()
  ├── authMod.Service().BootstrapAdmin(ctx, ...)
  ├── outboxMod.Worker().Start(ctx); defer outboxMod.Worker().Stop()
  │
  ├── mux := http.NewServeMux()
  ├── mux.HandleFunc("GET /healthz", healthHandler)
  ├── for _, mod := range modules { mod.RegisterRoutes(mux, authMW) }
  ├── mux.Handle("/", web.StaticHandler("web/dist"))
  │
  └── http.ListenAndServe(addr, chain(mux, requestID, logger))
```

---

## Contrato do Module

```go
// Todo módulo de domínio implementa esta interface.
// O pacote onde ela vive será internal/app/module.go (ou similar).
type Module interface {
    RegisterRoutes(mux *http.ServeMux, authMW *auth.Middleware)
}
```

---

## Passo a Passo

### Passo 0 — Criar a interface `Module`

**Arquivo novo:** `internal/app/module.go`

```go
package app

import (
    "net/http"
    "github.com/passoz/jachegai/internal/auth"
)

type Module interface {
    RegisterRoutes(mux *http.ServeMux, authMW *auth.Middleware)
}
```

**Critérios de aceitação:**
- [ ] Arquivo `internal/app/module.go` existe com a interface `Module`
- [ ] `go build ./...` compila sem erro

---

### Passo 1 — Migrar `auth` para Module

**Arquivo novo:** `internal/auth/module.go`

```go
package auth

import "net/http"

type Module struct {
    store      Store
    service    *Service
    middleware *Middleware
    handler    *Handler
}

func NewModule(db *sql.DB) *Module {
    store := NewStore(db)
    svc := NewService(store)
    mw := NewMiddleware(svc)
    h := NewHandler(svc, mw)
    return &Module{store: store, service: svc, middleware: mw, handler: h}
}

func (m *Module) Store() Store          { return m.store }
func (m *Module) Service() *Service     { return m.service }
func (m *Module) Middleware() *Middleware { return m.middleware }

func (m *Module) RegisterRoutes(mux *http.ServeMux, _ *Middleware) {
    mux.HandleFunc("POST /api/auth/register", m.handler.Register)
    mux.HandleFunc("POST /api/auth/login", m.handler.Login)
    mux.Handle("POST /api/auth/logout", m.middleware.RequireAuth(http.HandlerFunc(m.handler.Logout)))
    mux.Handle("GET /api/auth/me", m.middleware.RequireAuth(http.HandlerFunc(m.handler.Me)))
}
```

**Mudanças:**
- [ ] Criar `internal/auth/module.go`
- [ ] Em `cmd/jachegai/main.go`: instanciar `authMod := auth.NewModule(sqlDB)`, usar `authMod.Service().BootstrapAdmin(...)`, obter `authMW := authMod.Middleware()`
- [ ] Em `internal/httpapi/server.go`: REMOVER as 4 linhas de `mux.Handle*` de auth (agora estão no `RegisterRoutes` do módulo)
- [ ] Em `internal/app/app.go`: REMOVER campos `AuthService`, `AuthMiddleware`, `AuthHandler` e seu wire-up

**Critérios de aceitação:**
- [ ] `go build ./...` compila
- [ ] `go test ./internal/auth/...` passa (todos os testes existentes)
- [ ] Rotas de auth (`POST /api/auth/register`, `POST /api/auth/login`, `POST /api/auth/logout`, `GET /api/auth/me`) são registradas pelo `auth.Module.RegisterRoutes` — verificável via `httptest` no server
- [ ] `main.go` não importa `internal/auth` para handlers (só para o módulo)
- [ ] BootstrapAdmin funciona (verificar no log de inicialização)

---

### Passo 2 — Migrar `sellers` para Module

**Arquivo novo:** `internal/sellers/module.go`

```go
package sellers

import (
    "database/sql"
    "net/http"
    "github.com/passoz/jachegai/internal/auth"
)

type Module struct {
    store   Store
    service *Service
    handler *Handler
}

func NewModule(db *sql.DB) *Module {
    store := NewStore(db)
    svc := NewService(store)
    h := NewHandler(svc)
    return &Module{store: store, service: svc, handler: h}
}

func (m *Module) Store() Store      { return m.store }
func (m *Module) Service() *Service { return m.service }

func (m *Module) RegisterRoutes(mux *http.ServeMux, authMW *auth.Middleware) {
    mux.Handle("POST /api/seller/onboard", authMW.RequireRole(auth.RoleSeller)(http.HandlerFunc(m.handler.Onboard)))
    mux.Handle("GET /api/seller/profile", authMW.RequireRole(auth.RoleSeller)(http.HandlerFunc(m.handler.GetProfile)))
    mux.Handle("PUT /api/seller/profile", authMW.RequireRole(auth.RoleSeller)(http.HandlerFunc(m.handler.UpdateProfile)))
}
```

**Mudanças:**
- [ ] Criar `internal/sellers/module.go`
- [ ] `main.go`: instanciar `sellerMod := sellers.NewModule(sqlDB)`
- [ ] `server.go`: REMOVER as 3 linhas de seller
- [ ] `app.go`: REMOVER `SellerService`, `SellerHandler` e wire-up

**Critérios de aceitação:**
- [ ] `go build ./...` compila
- [ ] `go test ./internal/sellers/...` passa
- [ ] Rotas de seller registradas pelo módulo
- [ ] `main.go` não referencia `sellers.Handler` ou `sellers.Service` diretamente

---

### Passo 3 — Migrar `couriers` para Module

**Arquivo novo:** `internal/couriers/module.go`

```go
package couriers

type Module struct {
    store   Store
    service *Service
    handler *Handler
}

func NewModule(db *sql.DB) *Module {
    store := NewStore(db)
    svc := NewService(store)
    h := NewHandler(svc)
    return &Module{store: store, service: svc, handler: h}
}

func (m *Module) Store() Store      { return m.store }
func (m *Module) Service() *Service { return m.service }

func (m *Module) RegisterRoutes(mux *http.ServeMux, authMW *auth.Middleware) {
    mux.Handle("POST /api/courier/onboard", authMW.RequireRole(auth.RoleCourier)(http.HandlerFunc(m.handler.Onboard)))
    mux.Handle("GET /api/courier/profile", authMW.RequireRole(auth.RoleCourier)(http.HandlerFunc(m.handler.GetProfile)))
    mux.Handle("PUT /api/courier/profile", authMW.RequireRole(auth.RoleCourier)(http.HandlerFunc(m.handler.UpdateProfile)))
    mux.Handle("POST /api/courier/availability", authMW.RequireRole(auth.RoleCourier)(http.HandlerFunc(m.handler.SetAvailability)))
    mux.Handle("GET /api/courier/stats", authMW.RequireRole(auth.RoleCourier)(http.HandlerFunc(m.handler.GetStats)))
}
```

**Mudanças:**
- [ ] Criar `internal/couriers/module.go`
- [ ] `main.go`: instanciar `courierMod := couriers.NewModule(sqlDB)`
- [ ] `server.go`: REMOVER as 5 linhas de courier standalone (as de delivery ficam no orders por enquanto — ver passo 10)
- [ ] `app.go`: REMOVER `CourierService`, `CourierHandler` e wire-up

**Critérios de aceitação:**
- [ ] `go build ./...` compila
- [ ] `go test ./internal/couriers/...` passa
- [ ] Rotas standalone de courier registradas pelo módulo
- [ ] Nota: as rotas de delivery (`/api/courier/deliveries/...`) continuam em `server.go` até o passo 10 (orders)

---

### Passo 4 — Migrar `customers` para Module

**Arquivo novo:** `internal/customers/module.go`

```go
package customers

type Module struct {
    store   Store
    service *Service
    handler *Handler
}

func NewModule(db *sql.DB) *Module {
    store := NewStore(db)
    svc := NewService(store)
    h := NewHandler(svc)
    return &Module{store: store, service: svc, handler: h}
}

func (m *Module) Store() Store      { return m.store }
func (m *Module) Service() *Service { return m.service }

func (m *Module) RegisterRoutes(mux *http.ServeMux, authMW *auth.Middleware) {
    mux.Handle("GET /api/customer/profile", authMW.RequireRole(auth.RoleCustomer)(http.HandlerFunc(m.handler.GetProfile)))
    mux.Handle("PUT /api/customer/profile", authMW.RequireRole(auth.RoleCustomer)(http.HandlerFunc(m.handler.UpdateProfile)))
    mux.Handle("GET /api/customer/addresses", authMW.RequireRole(auth.RoleCustomer)(http.HandlerFunc(m.handler.ListAddresses)))
    mux.Handle("POST /api/customer/addresses", authMW.RequireRole(auth.RoleCustomer)(http.HandlerFunc(m.handler.CreateAddress)))
    mux.Handle("DELETE /api/customer/addresses/{id}", authMW.RequireRole(auth.RoleCustomer)(http.HandlerFunc(m.handler.DeleteAddress)))
}
```

**Mudanças:**
- [ ] Criar `internal/customers/module.go`
- [ ] `main.go`: instanciar `customerMod := customers.NewModule(sqlDB)`
- [ ] `server.go`: REMOVER as 5 linhas de customer standalone (cart/checkout ficam no orders)
- [ ] `app.go`: REMOVER `CustomerService`, `CustomerHandler` e wire-up

**Critérios de aceitação:**
- [ ] `go build ./...` compila
- [ ] Testes de customers (se existirem) passam
- [ ] Rotas de customer standalone registradas pelo módulo

---

### Passo 5 — Migrar `catalog` para Module

**Arquivo novo:** `internal/catalog/module.go`

```go
package catalog

type Module struct {
    store        Store
    service      *Service
    sellerHandler *SellerHandler
    publicHandler *PublicHandler
}

func NewModule(db *sql.DB) *Module {
    store := NewStore(db)
    svc := NewService(store)
    sh := NewSellerHandler(svc)
    ph := NewPublicHandler(svc)
    return &Module{store: store, service: svc, sellerHandler: sh, publicHandler: ph}
}

func (m *Module) Store() Store      { return m.store }
func (m *Module) Service() *Service { return m.service }

func (m *Module) RegisterRoutes(mux *http.ServeMux, authMW *auth.Middleware) {
    // Públicas
    mux.HandleFunc("GET /api/public/sellers", m.publicHandler.ListSellers)
    mux.HandleFunc("GET /api/public/sellers/{slug}/products", m.publicHandler.ListProductsBySlug)
    mux.HandleFunc("GET /api/public/cart", m.publicHandler.GetCart)
    mux.HandleFunc("POST /api/public/cart/items", m.publicHandler.AddCartItem)

    // Seller
    mux.Handle("GET /api/seller/categories", authMW.RequireRole(auth.RoleSeller)(http.HandlerFunc(m.sellerHandler.ListCategories)))
    mux.Handle("POST /api/seller/categories", authMW.RequireRole(auth.RoleSeller)(http.HandlerFunc(m.sellerHandler.CreateCategory)))
    mux.Handle("PUT /api/seller/categories/{id}", authMW.RequireRole(auth.RoleSeller)(http.HandlerFunc(m.sellerHandler.UpdateCategory)))
    mux.Handle("DELETE /api/seller/categories/{id}", authMW.RequireRole(auth.RoleSeller)(http.HandlerFunc(m.sellerHandler.DeleteCategory)))
    mux.Handle("GET /api/seller/products", authMW.RequireRole(auth.RoleSeller)(http.HandlerFunc(m.sellerHandler.ListProducts)))
    mux.Handle("POST /api/seller/products", authMW.RequireRole(auth.RoleSeller)(http.HandlerFunc(m.sellerHandler.CreateProduct)))
    mux.Handle("PUT /api/seller/products/{id}", authMW.RequireRole(auth.RoleSeller)(http.HandlerFunc(m.sellerHandler.UpdateProduct)))
    mux.Handle("GET /api/seller/products/{id}/inventory", authMW.RequireRole(auth.RoleSeller)(http.HandlerFunc(m.sellerHandler.GetInventory)))
    mux.Handle("PUT /api/seller/products/{id}/inventory", authMW.RequireRole(auth.RoleSeller)(http.HandlerFunc(m.sellerHandler.UpdateInventory)))
}
```

**Mudanças:**
- [ ] Criar `internal/catalog/module.go`
- [ ] `main.go`: instanciar `catalogMod := catalog.NewModule(sqlDB)`
- [ ] `server.go`: REMOVER as 13 linhas de catalog
- [ ] `app.go`: REMOVER `CatalogService`, `CatalogSellerHandler`, `CatalogPublicHandler` e wire-up

**Critérios de aceitação:**
- [ ] `go build ./...` compila
- [ ] `go test ./internal/catalog/...` passa
- [ ] Rotas públicas (4) e de seller (9) registradas pelo módulo
- [ ] Módulo com 2 handlers internos (SellerHandler + PublicHandler) funciona corretamente

---

### Passo 6 — Migrar `payments` para Module

**Nota:** `payments` hoje não tem Store separada e não tem rotas HTTP próprias — é um service injetado no orders. Ainda assim, criamos o Module para consistência e para expor `Service()` como getter.

**Arquivo novo:** `internal/payments/module.go`

```go
package payments

type Module struct {
    service *Service
}

func NewModule() *Module {
    return &Module{service: NewService()}
}

func (m *Module) Service() *Service { return m.service }

func (m *Module) RegisterRoutes(mux *http.ServeMux, authMW *auth.Middleware) {
    // Payments não tem rotas HTTP próprias no MVP
}
```

**Mudanças:**
- [ ] Criar `internal/payments/module.go`
- [ ] `main.go`: instanciar `paymentMod := payments.NewModule()`
- [ ] `app.go`: REMOVER `PaymentService` e wire-up

**Critérios de aceitação:**
- [ ] `go build ./...` compila
- [ ] `paymentMod.Service()` expõe o service para o orders usar

---

### Passo 7 — Migrar `outbox` para Module

**Arquivo novo:** `internal/outbox/module.go`

```go
package outbox

type Module struct {
    store   Store
    service *Service
    worker  *Worker
}

func NewModule(db *sql.DB) *Module {
    store := NewStore(db)
    svc := NewService(store)
    w := NewWorker(store)
    return &Module{store: store, service: svc, worker: w}
}

func (m *Module) Store() Store      { return m.store }
func (m *Module) Service() *Service { return m.service }
func (m *Module) Worker() *Worker   { return m.worker }

func (m *Module) RegisterRoutes(mux *http.ServeMux, authMW *auth.Middleware) {
    // Outbox não tem rotas HTTP próprias
}
```

**Mudanças:**
- [ ] Criar `internal/outbox/module.go`
- [ ] `main.go`: instanciar `outboxMod := outbox.NewModule(sqlDB)`, chamar `outboxMod.Worker().Start(ctx)` e `defer outboxMod.Worker().Stop()`
- [ ] `app.go`: REMOVER `OutboxService`, `OutboxWorker` e wire-up

**Critérios de aceitação:**
- [ ] `go build ./...` compila
- [ ] `go test ./internal/outbox/...` passa
- [ ] `outboxMod.Service()` e `outboxMod.Worker()` expõem os objetos corretos
- [ ] Worker inicia e para corretamente (verificar log de inicialização/desligamento)

---

### Passo 8 — Migrar `support` para Module

**Arquivo novo:** `internal/support/module.go`

```go
package support

type Module struct {
    store       Store
    service     *Service
    adminHandler *AdminHandler
}

func NewModule(db *sql.DB) *Module {
    store := NewStore(db)
    svc := NewService(store)
    ah := NewAdminHandler(svc)
    return &Module{store: store, service: svc, adminHandler: ah}
}

func (m *Module) Store() Store      { return m.store }
func (m *Module) Service() *Service { return m.service }

func (m *Module) RegisterRoutes(mux *http.ServeMux, authMW *auth.Middleware) {
    mux.Handle("GET /api/admin/support/tickets", authMW.RequireRole(auth.RoleAdmin)(http.HandlerFunc(m.adminHandler.ListTickets)))
    mux.Handle("GET /api/admin/support/tickets/{id}", authMW.RequireRole(auth.RoleAdmin)(http.HandlerFunc(m.adminHandler.GetTicket)))
}
```

**Mudanças:**
- [ ] Criar `internal/support/module.go`
- [ ] `main.go`: instanciar `supportMod := support.NewModule(sqlDB)`
- [ ] `server.go`: REMOVER as 2 linhas de support
- [ ] `app.go`: REMOVER `SupportService`, `SupportAdminHandler` e wire-up

**Critérios de aceitação:**
- [ ] `go build ./...` compila
- [ ] `go test ./internal/support/...` passa

---

### Passo 9 — Migrar `taxes` para Module

**Arquivo novo:** `internal/taxes/module.go`

```go
package taxes

type Module struct {
    store        Store
    service      *Service
    adminHandler *AdminHandler
}

func NewModule(db *sql.DB) *Module {
    store := NewStore(db)
    svc := NewService(store)
    ah := NewAdminHandler(svc)
    return &Module{store: store, service: svc, adminHandler: ah}
}

func (m *Module) Store() Store      { return m.store }
func (m *Module) Service() *Service { return m.service }

func (m *Module) RegisterRoutes(mux *http.ServeMux, authMW *auth.Middleware) {
    mux.Handle("GET /api/admin/settings", authMW.RequireRole(auth.RoleAdmin)(http.HandlerFunc(m.adminHandler.ListSettings)))
    mux.Handle("PUT /api/admin/settings", authMW.RequireRole(auth.RoleAdmin)(http.HandlerFunc(m.adminHandler.UpdateSetting)))
    mux.Handle("GET /api/admin/tax-settings", authMW.RequireRole(auth.RoleAdmin)(http.HandlerFunc(m.adminHandler.ListSettings)))
    mux.Handle("PUT /api/admin/tax-settings", authMW.RequireRole(auth.RoleAdmin)(http.HandlerFunc(m.adminHandler.UpdateSetting)))
    mux.Handle("GET /api/admin/invoices", authMW.RequireRole(auth.RoleAdmin)(http.HandlerFunc(m.adminHandler.ListInvoices)))
    mux.Handle("GET /api/admin/invoices/{id}", authMW.RequireRole(auth.RoleAdmin)(http.HandlerFunc(m.adminHandler.GetInvoice)))
}
```

**Mudanças:**
- [ ] Criar `internal/taxes/module.go`
- [ ] `main.go`: instanciar `taxesMod := taxes.NewModule(sqlDB)`
- [ ] `server.go`: REMOVER as 6 linhas de taxes
- [ ] `app.go`: REMOVER `TaxesService`, `TaxesAdminHandler` e wire-up

**Critérios de aceitação:**
- [ ] `go build ./...` compila
- [ ] `go test ./internal/taxes/...` passa

---

### Passo 10 — Migrar `orders` para Module

**Arquivo novo:** `internal/orders/module.go`

Este é o módulo mais complexo — agrupa 3 handlers (customer, seller, courier) e depende de 5 outros módulos.

```go
package orders

type Module struct {
    store          Store
    service        *Service
    handler        *Handler          // customer
    sellerHandler  *SellerHandler    // seller
    courierHandler *CourierHandler   // courier
}

func NewModule(
    db *sql.DB,
    customerStore customers.Store,
    catalogStore catalog.Store,
    sellerStore sellers.Store,
    courierStore couriers.Store,
    paymentSvc *payments.Service,
    outboxSvc *outbox.Service,
) *Module {
    store := NewStore(db)
    svc := NewService(store, customerStore, catalogStore, sellerStore, paymentSvc, outboxSvc, db)
    h := NewHandler(svc)
    sh := NewSellerHandler(svc)
    ch := NewCourierHandler(svc, courierStore)
    return &Module{store: store, service: svc, handler: h, sellerHandler: sh, courierHandler: ch}
}

func (m *Module) Store() Store      { return m.store }
func (m *Module) Service() *Service { return m.service }

func (m *Module) RegisterRoutes(mux *http.ServeMux, authMW *auth.Middleware) {
    // Customer cart + checkout + orders
    mux.Handle("GET /api/customer/cart/{seller_id}", authMW.RequireRole(auth.RoleCustomer)(http.HandlerFunc(m.handler.GetCart)))
    mux.Handle("POST /api/customer/cart/{seller_id}/items", authMW.RequireRole(auth.RoleCustomer)(http.HandlerFunc(m.handler.AddCartItem)))
    mux.Handle("PUT /api/customer/cart/{seller_id}/items/{id}", authMW.RequireRole(auth.RoleCustomer)(http.HandlerFunc(m.handler.UpdateCartItem)))
    mux.Handle("DELETE /api/customer/cart/{seller_id}/items/{id}", authMW.RequireRole(auth.RoleCustomer)(http.HandlerFunc(m.handler.RemoveCartItem)))
    mux.Handle("POST /api/customer/checkout", authMW.RequireRole(auth.RoleCustomer)(http.HandlerFunc(m.handler.Checkout)))
    mux.Handle("GET /api/customer/orders", authMW.RequireRole(auth.RoleCustomer)(http.HandlerFunc(m.handler.ListOrders)))
    mux.Handle("GET /api/customer/orders/{id}", authMW.RequireRole(auth.RoleCustomer)(http.HandlerFunc(m.handler.GetOrder)))
    mux.Handle("GET /api/customer/orders/{id}/tracking", authMW.RequireRole(auth.RoleCustomer)(http.HandlerFunc(m.courierHandler.GetTracking)))

    // Seller orders
    mux.Handle("GET /api/seller/orders", authMW.RequireRole(auth.RoleSeller)(http.HandlerFunc(m.sellerHandler.ListOrders)))
    mux.Handle("GET /api/seller/orders/{id}", authMW.RequireRole(auth.RoleSeller)(http.HandlerFunc(m.sellerHandler.GetOrder)))
    mux.Handle("POST /api/seller/orders/{id}/{action}", authMW.RequireRole(auth.RoleSeller)(http.HandlerFunc(m.sellerHandler.TransitionOrder)))

    // Courier deliveries
    mux.Handle("GET /api/courier/deliveries", authMW.RequireRole(auth.RoleCourier)(http.HandlerFunc(m.courierHandler.ListDeliveries)))
    mux.Handle("POST /api/courier/deliveries/{id}/{action}", authMW.RequireRole(auth.RoleCourier)(http.HandlerFunc(m.courierHandler.TransitionDelivery)))
    mux.Handle("POST /api/courier/location", authMW.RequireRole(auth.RoleCourier)(http.HandlerFunc(m.courierHandler.UpdateLocation)))
}
```

**Verificado:** `CourierHandler` usa `courierStore` para `GetCourierByUserID` (resolveCourierID), `InsertLocation` (UpdateLocation) e `GetLatestLocation` (GetTracking). O `orders.NewModule` precisa receber `couriers.Store`.

**Mudanças:**
- [ ] Criar `internal/orders/module.go`
- [ ] `main.go`: instanciar `orderMod := orders.NewModule(sqlDB, customerMod.Store(), catalogMod.Store(), sellerMod.Store(), paymentMod.Service(), outboxMod.Service())`
- [ ] `server.go`: REMOVER todas as linhas de orders (~15)
- [ ] `app.go`: REMOVER `OrderService`, `OrderHandler`, `OrderSellerHandler`, `OrderCourierHandler` e wire-up

**Critérios de aceitação:**
- [ ] `go build ./...` compila
- [ ] `go test ./internal/orders/...` passa (todos os testes existentes)
- [ ] 3 handlers (customer, seller, courier) registrados dentro do mesmo `RegisterRoutes`
- [ ] Dependências cross-module resolvidas via getters (não via acoplamento a tipos concretos de módulo)
- [ ] Rotas de courier que estavam em `server.go` no passo 3 agora estão no orders Module

---

### Passo 11 — Migrar `admin` para Module

**Arquivo novo:** `internal/admin/module.go`

```go
package admin

type Module struct {
    service *Service
    handler *Handler
    // support e taxes já têm seus próprios módulos com rotas
}

func NewModule(db *sql.DB, sellerStore sellers.Store) *Module {
    svc := NewService(db, sellerStore)
    h := NewHandler(svc)
    return &Module{service: svc, handler: h}
}

func (m *Module) Service() *Service { return m.service }

func (m *Module) RegisterRoutes(mux *http.ServeMux, authMW *auth.Middleware) {
    mux.Handle("GET /api/admin/dashboard", authMW.RequireRole(auth.RoleAdmin)(http.HandlerFunc(m.handler.Dashboard)))
    mux.Handle("GET /api/admin/users", authMW.RequireRole(auth.RoleAdmin)(http.HandlerFunc(m.handler.ListUsers)))
    mux.Handle("GET /api/admin/users/{id}", authMW.RequireRole(auth.RoleAdmin)(http.HandlerFunc(m.handler.GetUser)))
    mux.Handle("GET /api/admin/sellers", authMW.RequireRole(auth.RoleAdmin)(http.HandlerFunc(m.handler.ListSellers)))
    mux.Handle("GET /api/admin/sellers/{id}", authMW.RequireRole(auth.RoleAdmin)(http.HandlerFunc(m.handler.GetSeller)))
    mux.Handle("POST /api/admin/sellers/{id}/{action}", authMW.RequireRole(auth.RoleAdmin)(http.HandlerFunc(m.handler.ModerateSeller)))
    mux.Handle("GET /api/admin/couriers", authMW.RequireRole(auth.RoleAdmin)(http.HandlerFunc(m.handler.ListCouriers)))
    mux.Handle("GET /api/admin/couriers/{id}", authMW.RequireRole(auth.RoleAdmin)(http.HandlerFunc(m.handler.GetCourier)))
    mux.Handle("POST /api/admin/couriers/{id}/{action}", authMW.RequireRole(auth.RoleAdmin)(http.HandlerFunc(m.handler.ModerateCourier)))
    mux.Handle("GET /api/admin/orders", authMW.RequireRole(auth.RoleAdmin)(http.HandlerFunc(m.handler.ListOrders)))
    mux.Handle("GET /api/admin/orders/{id}", authMW.RequireRole(auth.RoleAdmin)(http.HandlerFunc(m.handler.GetOrder)))
    mux.Handle("GET /api/admin/observability", authMW.RequireRole(auth.RoleAdmin)(http.HandlerFunc(m.handler.ObservabilitySummary)))
    mux.Handle("GET /api/admin/observability/summary", authMW.RequireRole(auth.RoleAdmin)(http.HandlerFunc(m.handler.ObservabilitySummary)))
    mux.Handle("GET /api/admin/observability/requests", authMW.RequireRole(auth.RoleAdmin)(http.HandlerFunc(m.handler.ObservabilityRequests)))
    mux.Handle("GET /api/admin/observability/orders", authMW.RequireRole(auth.RoleAdmin)(http.HandlerFunc(m.handler.ObservabilityOrders)))
}
```

**Mudanças:**
- [ ] Criar `internal/admin/module.go`
- [ ] `main.go`: instanciar `adminMod := admin.NewModule(sqlDB, sellerMod.Store())`
- [ ] `server.go`: REMOVER todas as linhas de admin (~15)
- [ ] `app.go`: REMOVER `AdminService`, `AdminHandler` e wire-up

**Critérios de aceitação:**
- [ ] `go build ./...` compila
- [ ] `go test ./internal/admin/...` passa
- [ ] 15 rotas de admin registradas pelo módulo
- [ ] Nota: `admin.Service` ainda recebe `*sql.DB` direto — isso é abordado no Candidato #3, não aqui

---

### Passo 12 — Limpar `app.go`

Após todos os 11 módulos migrados, `app.go` deve conter **apenas** `Config` e `LoadConfig()`. Remover:

- [ ] Struct `App` inteira
- [ ] Função `New()` inteira
- [ ] Todos os imports de pacotes de domínio

Se `app.go` ficar só com `Config` + `LoadConfig`, renomear para `config.go` ou manter como está.

**Critérios de aceitação:**
- [ ] `internal/app/app.go` NÃO contém struct `App` nem função `New()`
- [ ] Nenhum import de pacote de domínio em `internal/app/`
- [ ] `go build ./...` compila

---

### Passo 13 — Simplificar `server.go`

Após todos os módulos migrados, `server.go` deve conter:

```go
func (s *Server) routes() {
    s.mux.HandleFunc("GET /healthz", s.handleHealthz)

    for _, mod := range s.modules {
        mod.RegisterRoutes(s.mux, s.authMW)
    }

    s.mux.Handle("/", web.StaticHandler("web/dist"))
}
```

**Mudanças:**
- [ ] `Server` struct ganha campo `modules []app.Module` e `authMW *auth.Middleware`
- [ ] `NewServer` recebe `modules []app.Module, authMW *auth.Middleware`
- [ ] `routes()` reduzido a health check + iteração de módulos + SPA fallback
- [ ] REMOVER todos os `mux.Handle*` individuais de domínio (~100 linhas)

**Critérios de aceitação:**
- [ ] `server.go` tem menos de 40 linhas
- [ ] Nenhum import de pacote de domínio (exceto `app` para `Module` e `auth` para `Middleware`)
- [ ] `go test ./internal/httpapi/...` passa

---

### Passo 14 — `main.go` final

O `main.go` deve ficar:

```go
func main() {
    cfg := app.LoadConfig()
    os.MkdirAll(cfg.DataDir, 0755)

    sqlDB, _ := db.Open(cfg.DBPath)
    defer sqlDB.Close()
    db.Migrate(sqlDB, migrations.SQLiteFS)

    // Módulos folha (sem dependências cross-module)
    authMod    := auth.NewModule(sqlDB)
    sellerMod  := sellers.NewModule(sqlDB)
    courierMod := couriers.NewModule(sqlDB)
    customerMod:= customers.NewModule(sqlDB)
    catalogMod := catalog.NewModule(sqlDB)
    paymentMod := payments.NewModule()
    outboxMod  := outbox.NewModule(sqlDB)
    supportMod := support.NewModule(sqlDB)
    taxesMod   := taxes.NewModule(sqlDB)

    // Módulos com dependências cross-module
    orderMod := orders.NewModule(sqlDB,
        customerMod.Store(), catalogMod.Store(),
        sellerMod.Store(), courierMod.Store(),
        paymentMod.Service(), outboxMod.Service(),
    )
    adminMod := admin.NewModule(sqlDB, sellerMod.Store())

    modules := []app.Module{
        authMod, catalogMod, sellerMod, courierMod, customerMod,
        paymentMod, outboxMod, supportMod, taxesMod, orderMod, adminMod,
    }

    // Bootstrap
    authMW := authMod.Middleware()
    authMod.Service().BootstrapAdmin(ctx, cfg.AdminEmail, cfg.AdminPassword)
    outboxMod.Worker().Start(ctx)
    defer outboxMod.Worker().Stop()

    // Server
    srv := httpapi.NewServer(modules, authMW, cfg)
    srv.Handler() // com middleware chain
    http.ListenAndServe(cfg.Addr, srv.Handler())
}
```

**Critérios de aceitação:**
- [ ] `main.go` NÃO importa handlers, services ou stores individuais (só módulos e `app.Config`)
- [ ] `main.go` tem menos de 60 linhas
- [ ] `go run ./cmd/jachegai` sobe o servidor e responde em `/healthz`
- [ ] `POST /api/auth/register` funciona (fluxo completo)
- [ ] `POST /api/auth/login` funciona (fluxo completo)

---

### Passo 15 — Teste de regressão completa

- [ ] `go test ./... -count=1` passa (todos os pacotes, sem cache)
- [ ] `go build ./...` compila sem warnings
- [ ] `go vet ./...` sem erros
- [ ] `docker compose -f docker-compose.dev.yml up --build` sobe
- [ ] `curl localhost:8080/healthz` retorna 200
- [ ] `curl -X POST localhost:8080/api/auth/register -d '{"email":"test@test.com","password":"123456","role":"customer"}'` retorna 201

---

## Resumo de Arquivos

| Ação | Arquivo |
|------|---------|
| NOVO | `internal/app/module.go` |
| NOVO | `internal/auth/module.go` |
| NOVO | `internal/sellers/module.go` |
| NOVO | `internal/couriers/module.go` |
| NOVO | `internal/customers/module.go` |
| NOVO | `internal/catalog/module.go` |
| NOVO | `internal/payments/module.go` |
| NOVO | `internal/outbox/module.go` |
| NOVO | `internal/support/module.go` |
| NOVO | `internal/taxes/module.go` |
| NOVO | `internal/orders/module.go` |
| NOVO | `internal/admin/module.go` |
| MODIFICADO | `internal/app/app.go` → remover `App` struct e `New()` |
| MODIFICADO | `internal/httpapi/server.go` → reduzir `routes()` |
| MODIFICADO | `cmd/jachegai/main.go` → reescrever com módulos |

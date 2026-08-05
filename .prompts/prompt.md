# PROMPT: Implementar o backend JaChegai em Rails com TDD

> **Objetivo:** Implementar o backend do JaChegai neste repositório Rails, em fatias verticais e com TDD obrigatório, preservando todos os requisitos de backend definidos em `docs/PORTABLE_PRODUCT_SPEC.md` e adaptando para Rails apenas os princípios úteis dos demais documentos em `docs/*.md`.
> **Contexto:** O repositório atual é uma aplicação Rails 8.1 recém-criada. O usuário decidiu explicitamente manter Rails, implementar primeiro o backend, liberar o gate de execução citado nos documentos e adiar frontend/UI. Portanto, esta entrega deve produzir um **backend MVP funcional e verificável**, mas **não pode declarar o MVP completo do produto**, pois as superfícies frontend, acessibilidade visual, PWA e design system ficam para uma entrega posterior.

---

## 1. Hierarquia das Fontes e Conformidade

Siga esta precedência quando os documentos divergirem:

1. `AGENTS.md`: regras obrigatórias do repositório, especialmente o limite absoluto da raiz e o framework atual Rails.
2. Decisões explícitas do usuário nesta conversa: Rails, backend primeiro, frontend adiado e gate liberado.
3. `docs/PORTABLE_PRODUCT_SPEC.md`: **fonte normativa de produto, domínio, segurança, confiabilidade e qualidade**.
4. `docs/IMPLEMENTATION_PLAN.md`: usar somente como referência de ordem das fatias, vertical slices, envelope JSON, SQLite, UUIDv7, testes e smoke flow; **não copiar sua stack Go nem sua estrutura de diretórios**.
5. `docs/REBUILD_PLAN.md`: evidência histórica de uma base Go inexistente neste repositório; não executar seus passos nem criar `cmd/jachegai`, `internal/*` ou módulos Go.
6. `docs/UI_SYSTEM.md` e `docs/github-issues/ui-library/*`: oficiais para a futura entrega frontend, mas fora do escopo atual. Não acessar os caminhos externos citados nesses arquivos.

Antes de escrever código:

- crie `docs/BACKEND_ARCHITECTURE_RAILS.md` com a decisão arquitetural Rails e a worksheet da seção 25 da spec preenchida para o backend;
- crie `docs/BACKEND_REQUIREMENTS_MATRIX.md` contendo **todos os 197 requirement IDs** da spec, um por linha, com: requisito, fatia, componente Rails, teste/evidência, status e desvio;
- use apenas estes status: `planned`, `implemented`, `verified`, `deferred_frontend`, `conditional_not_applicable`, `blocked`;
- nenhum requisito `MUST` pode desaparecer da matriz; requisitos adiados devem ter justificativa e entrega futura identificada;
- não altere os documentos normativos existentes em `docs/*.md` sem autorização.

---

## 2. Escopo e Não-Objetivos

### Em escopo agora

- API REST JSON versionada;
- autenticação local, sessões revogáveis, roles e autorização por objeto;
- sellers, customers, couriers e administradores;
- catálogo, inventário, guest cart, customer cart e checkout;
- pedidos, pagamento simulado, histórico e state machines;
- entrega, atribuição concorrente de courier e tracking;
- favoritos, suporte, settings, fees, invoices e auditoria;
- upload/media no backend;
- outbox, jobs duráveis, observabilidade e health checks;
- backup/restore local demonstrável;
- segurança, testes unitários, request/contract, integração, concorrência, jobs, API E2E e smoke;
- documentação operacional e de contrato.

### Fora desta entrega

- páginas Rails/ERB de produto, React, PWA, frontend ou design system;
- implementação dos itens `UI-01` a `UI-08`;
- acessibilidade visual, responsividade e browser E2E — devem aparecer como `deferred_frontend` na matriz;
- publicação nativa/mobile, Capacitor e microfrontends;
- social login, recuperação de senha e verificação de e-mail;
- pagamento externo real e callback público de provider;
- promoções, cupons, loyalty, refunds, chargebacks, settlement, fiscal avançado e múltiplos sellers por checkout;
- chat customer/courier, roteirização e dispatch dinâmico;
- Kubernetes, broker externo, Redis ou novos serviços de infraestrutura.

### Regra de conclusão

A entrega pode ser chamada de **“backend MVP concluído”** quando seu Definition of Done passar. Ela não pode ser chamada de **“JaChegai MVP completo”** até que as superfícies cliente definidas na spec também existam e os cenários de frontend/acessibilidade sejam verificados.

---

## 3. Requisitos Técnicos e Decisões Fixadas para Rails

- [ ] Ruby `4.0.6` conforme `.ruby-version` e Rails `8.1.3` conforme `Gemfile`.
- [ ] Modular monolith Rails, um repositório, um deployable unit e uma base primária SQLite.
- [ ] Active Record e migrations Rails para persistência; nenhum código Go, `sqlc` ou estrutura `internal/*`.
- [ ] SQLite com foreign keys, WAL e busy timeout validados na inicialização e nos testes.
- [ ] Solid Queue para execução durável de jobs; `outbox_events` na base primária para consistência com transações de negócio.
- [ ] REST JSON sob `/api/v1`; `/healthz` e `/readyz` fora do versionamento.
- [ ] Active Storage em `storage/uploads` (ou caminho configurável sob o volume persistente `storage/`), alinhado ao layout Rails existente; não usar `/data` como suposição Go.
- [ ] Minitest, fixtures Rails e helpers manuais; não adicionar FactoryBot/RSpec.
- [ ] Adicionar/descomentar apenas a gem `bcrypt`, necessária a `has_secure_password`. Outras gems exigem justificativa e aprovação.
- [ ] Todos os nomes de classes, módulos, métodos, variáveis, migrations, logs técnicos e comentários em inglês.
- [ ] Mensagens client-visible em português brasileiro por Rails I18n (`config/locales/pt-BR.yml`), nunca hardcoded em controllers/services.

### 3.1 Identificadores

- IDs das entidades de negócio são UUIDv7 em colunas SQLite `TEXT PRIMARY KEY`.
- Centralize a geração em `app/lib/application_id.rb` usando `SecureRandom.uuid_v7` disponível no Ruby selecionado.
- Gere IDs exclusivamente no servidor; ignore/rejeite `id` enviado pelo cliente para criação de recursos protegidos.
- Teste formato, version bit 7, unicidade e ordenação temporal básica.
- Tokens de sessão, guest cart e idempotência não são entity IDs: gere tokens aleatórios de alta entropia e persista somente o digest quando houver risco de roubo.

### 3.2 Arquitetura Rails

Use, no mínimo:

```text
app/controllers/api/v1/
app/domain/
app/jobs/
app/lib/
app/models/
app/policies/
app/services/
config/initializers/jachegai.rb
db/migrate/
test/controllers/api/v1/ ou test/integration/api/v1/
test/domain/
test/jobs/
test/models/
test/services/
test/support/
```

- `Api::V1::BaseController` deve concentrar JSON, autenticação, CSRF/origin, error mapping e request ID.
- Normalize autenticação em `Current.principal`, contendo ao menos `principal_id`, roles/capabilities, active status, session context e request/correlation ID; services/policies não dependem diretamente de cookies.
- Controllers ficam finos: parseiam input, autorizam, chamam serviço e renderizam contrato.
- Services coordenam transações e regras de aplicação.
- `app/domain/` contém state machines, money e regras independentes de HTTP.
- Policies recebem principal e recurso/scope; toda operação protegida executa policy server-side.
- Provider adapters ficam atrás de interfaces Ruby mínimas e não vazam objetos externos para o domínio.
- Configuração fica centralizada e validada em `config.x.jachegai`, alimentada por ENV/credentials.

---

## 4. Disposição dos Requisitos da Spec

A matriz completa deve enumerar os 197 IDs. Use esta classificação inicial e refine por requisito:

| Área | Tratamento nesta entrega |
|---|---|
| `PRD-001..005` | Evidência de backend/API e smoke; conclusão integral depende do frontend. |
| `IAM-001..010` | Implementar e testar integralmente. |
| `PUB-003..008`, `PUB-010` | Implementar APIs públicas e guest cart. |
| `PUB-001`, `PUB-002`, `PUB-009` | `deferred_frontend`; backend pode oferecer dados, mas não alegar experiência concluída. |
| `CUS-001..013` | Implementar e testar no backend. |
| `CUS-014` | `deferred_frontend`; API deve fornecer estados/erros estáveis que habilitem a futura UI. |
| `SEL-001..013` | Implementar e testar no backend. |
| `COU-001..011` | Implementar e testar no backend. |
| `COU-012` | API deve distinguir queue/active/completed/availability; apresentação fica `deferred_frontend`. |
| `ORD-001..022` | Implementar e testar integralmente. |
| `PAY-001..010` | Implementar por interface provider-neutral + provider simulado; callback externo é `conditional_not_applicable` enquanto não houver provider real. |
| `SUP-001..007` | Implementar e testar integralmente conforme política abaixo. |
| `ADM-001..010` | Implementar e testar no backend. |
| `ADM-011` | Preferir suspensão/reversão no servidor; confirmação visual é `deferred_frontend`. |
| `DAT-001..012` | Implementar e testar integralmente. |
| `INT-001..010` | Implementar no outbox/jobs e adapters; integrações inexistentes podem ser condicionais, nunca omitidas. |
| `UX-005`, `UX-008`, `UX-012` | Aplicar ao vocabulário da API, I18n e segurança das sessões. |
| Outros `UX-*` e acessibilidade visual | `deferred_frontend`, com justificativa explícita. |
| `SEC-001..015` | Implementar/testar os controles de backend; callbacks externos condicionais. |
| `NFR-001..022` | Implementar backend/ops e documentar targets; browser compatibility fica para frontend. |
| `TST-001..005`, `TST-008..011` | Implementar evidência compatível com o backend. |
| `TST-007` | Implementar API E2E do ciclo completo agora; browser E2E será posterior. |
| `TST-006` e parte visual/acessibilidade de `TST-012` | `deferred_frontend`; compatibilidade/versionamento da API e OpenAPI são verificados agora. |

Não use ausência de frontend para ignorar requisitos de segurança, consistência, recovery, API E2E, observabilidade ou operações.

---

## 5. Domínio e Persistência

### 5.1 Entidades mínimas

Implemente modelos e constraints para:

```text
User
RoleAssignment
Session
Customer
Address
Seller
SellerMembership
SellerSetting
Courier
CourierLocation
Category
Product
InventoryItem
GuestCart
GuestCartItem
Cart
CartItem
Order
OrderItem
OrderStatusHistory
Payment
Favorite
SupportTicket
SupportMessage
Setting
Invoice
Upload/ActiveStorage attachments
OutboxEvent
AuditLog
IdempotencyRecord
InventoryMovement
```

### 5.2 Invariantes de dados

- Todas as entidades mutáveis registram `created_at`/`updated_at` em UTC; respostas usam ISO-8601 UTC.
- Valores monetários usam integer minor units (`*_cents`) e currency explícita (`BRL` no MVP).
- Foreign keys e unique indexes protegem relações e idempotência.
- `OrderItem`, address snapshot, order totals, payment amount/currency e fee snapshot não mudam após checkout.
- `OrderStatusHistory`, `SupportMessage` e `AuditLog` são append-only; proteja update/delete na aplicação e, para auditoria/histórico sensível, também no SQLite quando viável.
- `OutboxEvent` tem payload/event identity imutável e processing metadata mutável (`status`, `attempts`, `available_at`, `last_error`).
- Collection endpoints têm ordenação determinística e paginação limitada a `per_page <= 100`.
- Queries aceitam apenas filtros/sorts allow-listed.

### 5.3 State machines canônicas

#### Seller moderation

```text
pending_review -> approved | rejected
approved -> suspended
suspended -> approved
```

Somente admin; cada transição cria `AuditLog` com ator, target, ação, timestamp, request ID e reason opcional.

#### Courier

Approval:

```text
pending_review -> approved | rejected
approved -> suspended
suspended -> approved
```

Operational:

```text
offline <-> available
available -> on_delivery
on_delivery -> available
```

Approval e operational state são campos separados.

#### Order

```text
pending -> accepted | rejected | cancelled
accepted -> preparing | cancelled
preparing -> ready
ready -> assigned
assigned -> picked_up | cancelled
picked_up -> delivered
```

Terminais: `rejected`, `delivered`, `cancelled`.

Toda transição válida atualiza estado + histórico + outbox event em uma transação. Toda transição inválida falha sem efeito parcial.

#### Payment

```text
pending -> paid | failed
paid -> refunded   # estado preparado, comando de refund fora do MVP
```

Order e Payment mantêm estados independentes.

#### Support ticket

```text
open -> in_progress | resolved
in_progress -> resolved
resolved -> open | closed
```

Customers podem criar ticket, listar/ler os próprios tickets e adicionar mensagens aos próprios tickets não fechados. Admin pode responder e transicionar; todas as transições são auditadas.

---

## 6. Autenticação, Sessão e Autorização

- Use `has_secure_password` + bcrypt; senha mínima de 8 caracteres para o MVP.
- Use `RoleAssignment` em vez de um único enum no `User`, permitindo múltiplos papéis futuros.
- Registro público só aceita `customer`, `seller` ou `courier`; nunca `admin`.
- `customer` cria/associa Customer; seller/courier iniciam onboarding pendente.
- Session cookie contém token opaco aleatório; banco armazena digest, user, `expires_at`, `revoked_at`, `last_seen_at` e metadata mínima.
- Session lifetime provisório: 7 dias absolutos; rotacione o token em login e revogue no logout.
- Toda request autenticada revalida expiração, revogação e `user.active`; desativar user revoga/rejeita todas as sessões imediatamente.
- A arquitetura de identidade selecionada é local: não há account linking nem provider externo no MVP. Documente uma interface normalizada para migração futura; external-provider outage é `conditional_not_applicable` até existir adapter.
- Cookies: `HttpOnly`, `SameSite=Lax`, `Secure` em produção, path restrito quando aplicável.
- Como a API usa cookie, mantenha proteção CSRF ativa. Exponha `GET /api/v1/auth/csrf` e exija token + origin permitido em mutações de browser.
- Policies implementam ownership e role/capability para customers, seller memberships, courier assignment e admin.
- Mensagens de login não distinguem e-mail inexistente de senha incorreta.
- Bootstrap admin: task idempotente `bin/rails jachegai:bootstrap_admin`, lendo `ADMIN_EMAIL`/`ADMIN_PASSWORD`; cria somente o primeiro admin quando nenhum existe. Não proíba criação posterior por fluxo administrativo autorizado.
- Rate limiting usa `Rails.cache`/Solid Cache compartilhável, não hash em memória por processo: login/register 5/min por IP e por identifier normalizado, além de limites documentados para cart, checkout, support e location. Emitir métricas/logs redigidos de bloqueios sem revelar existência de conta.

---

## 7. Contrato REST JSON

### 7.1 Envelope

Sucesso:

```json
{"ok":true,"data":{},"meta":{}}
```

Erro:

```json
{
  "ok": false,
  "error": {
    "code": "invalid_input",
    "message": "Requisição inválida",
    "request_id": "...",
    "details": {"email":["invalid"]}
  }
}
```

`details` é opcional, contém field codes estáveis e nunca expõe mensagens de banco, classes ou stack traces.

Taxonomia obrigatória:

```text
invalid_input
unauthenticated
forbidden
not_found
conflict
state_transition_not_allowed
insufficient_inventory
idempotency_conflict
rate_limited
external_dependency_unavailable
internal_failure
```

Mapeamento HTTP:

- `200/201`: sucesso com envelope; não usar `204`, pois o contrato exige envelope consistente;
- `400`: `invalid_input`/JSON inválido/unknown fields;
- `401`: `unauthenticated`;
- `403`: `forbidden`;
- `404`: `not_found`;
- `409`: conflitos, transição inválida, inventário insuficiente ou idempotency conflict;
- `413`: payload/upload maior que o limite;
- `422`: arquivo semanticamente inválido, se necessário;
- `429`: `rate_limited`;
- `503`: dependência obrigatória indisponível;
- `500`: `internal_failure` sanitizado.

Toda resposta inclui `X-Request-ID`. Collections incluem em `meta`: `page`, `per_page`, `total_count`, `total_pages` e sort aplicado.

### 7.2 Regras de request

- `Content-Type: application/json` nas mutações JSON.
- Rejeite JSON malformado, body acima do limite e chaves desconhecidas; strong parameters silenciosos não bastam para SEC-008.
- GET não pode criar cart ou outro estado oculto; `GET /cart` retorna estado vazio quando inexistente. POST cria/muta.
- `Idempotency-Key` obrigatório em checkout, courier accept e mutações financeiras suscetíveis a retry.
- O mesmo key + mesmo payload retorna o resultado original; mesmo key + payload diferente retorna `idempotency_conflict`.
- Preços, fees, seller, product activity e inventory são sempre recalculados no servidor.
- Documente o contrato em `docs/api/openapi.yaml` (OpenAPI 3.1) e mantenha request tests coerentes com ele.

### 7.3 Rotas mínimas

#### Health

```text
GET /healthz
GET /readyz
```

`/healthz` não depende de banco. `/readyz` verifica a base primária e, quando Solid Queue for obrigatório para servir com segurança, a base de queue.

#### Auth

```text
GET  /api/v1/auth/csrf
POST /api/v1/auth/register
POST /api/v1/auth/login
POST /api/v1/auth/logout
GET  /api/v1/auth/me
```

Payloads mínimos:

```json
{"email":"user@example.com","password":"minimum8","actor_type":"customer"}
{"email":"user@example.com","password":"minimum8"}
```

#### Public e guest cart

```text
GET    /api/v1/public/sellers
GET    /api/v1/public/sellers/:seller_id/products
GET    /api/v1/public/cart
POST   /api/v1/public/cart/items
PATCH  /api/v1/public/cart/items/:id
DELETE /api/v1/public/cart/items/:id
```

Guest cart usa cookie/token opaco com retenção de 7 dias. Produto de outro seller exige `replace_confirmed: true`; sem confirmação retorna `conflict`. Quantity é integer entre 1 e um máximo configurado.

#### Customer

```text
GET   /api/v1/customer/profile
PATCH /api/v1/customer/profile
GET   /api/v1/customer/addresses
POST  /api/v1/customer/addresses
PATCH /api/v1/customer/addresses/:id
DELETE /api/v1/customer/addresses/:id
POST  /api/v1/customer/addresses/:id/default
GET   /api/v1/customer/favorites
POST  /api/v1/customer/favorites
DELETE /api/v1/customer/favorites/:seller_id
POST  /api/v1/customer/cart/handoff
GET   /api/v1/customer/carts/:seller_id
POST  /api/v1/customer/carts/:seller_id/items
PATCH /api/v1/customer/carts/:seller_id/items/:id
DELETE /api/v1/customer/carts/:seller_id/items/:id
POST  /api/v1/customer/checkout
GET   /api/v1/customer/orders
GET   /api/v1/customer/orders/:id
POST  /api/v1/customer/orders/:id/cancel
GET   /api/v1/customer/orders/:id/tracking
POST  /api/v1/customer/support/tickets
GET   /api/v1/customer/support/tickets
GET   /api/v1/customer/support/tickets/:id
POST  /api/v1/customer/support/tickets/:id/messages
```

Checkout mínimo:

```json
{"seller_id":"uuid-v7","address_id":"uuid-v7","payment_method":"simulated"}
```

O response de cart/checkout preview expõe authoritative `subtotal_cents`, `delivery_fee_cents`, `discount_cents`, `total_cents` e `currency` antes da confirmação.

#### Seller

```text
POST   /api/v1/seller/onboarding
GET    /api/v1/seller/profile
PATCH  /api/v1/seller/profile
GET    /api/v1/seller/settings
PATCH  /api/v1/seller/settings
GET    /api/v1/seller/categories
POST   /api/v1/seller/categories
PATCH  /api/v1/seller/categories/:id
DELETE /api/v1/seller/categories/:id
GET    /api/v1/seller/products
POST   /api/v1/seller/products
PATCH  /api/v1/seller/products/:id
POST   /api/v1/seller/products/:id/activate
POST   /api/v1/seller/products/:id/deactivate
DELETE /api/v1/seller/products/:id
GET    /api/v1/seller/inventory
GET    /api/v1/seller/inventory/:product_id
PATCH  /api/v1/seller/inventory/:product_id
GET    /api/v1/seller/orders
GET    /api/v1/seller/orders/:id
POST   /api/v1/seller/orders/:id/accept
POST   /api/v1/seller/orders/:id/reject
POST   /api/v1/seller/orders/:id/preparing
POST   /api/v1/seller/orders/:id/ready
```

Category possui `position` seller-scoped; create/update permite ordenação determinística. Produto referenciado historicamente não é apagado destrutivamente; `DELETE` só remove quando constraints permitem, caso contrário retorna conflict e usa deactivate.

#### Courier

```text
POST  /api/v1/courier/onboarding
GET   /api/v1/courier/profile
PATCH /api/v1/courier/profile
POST  /api/v1/courier/availability
GET   /api/v1/courier/deliveries
POST  /api/v1/courier/deliveries/:order_id/accept
POST  /api/v1/courier/deliveries/:order_id/picked-up
POST  /api/v1/courier/deliveries/:order_id/delivered
POST  /api/v1/courier/location
GET   /api/v1/courier/stats
```

`deliveries` distingue `eligible`, `active` e `completed`. Stats incluem completed deliveries e estimated earnings calculados pela soma do `courier_fee_cents` snapshot dos pedidos entregues.

#### Admin

```text
GET  /api/v1/admin/dashboard
GET  /api/v1/admin/users
GET  /api/v1/admin/users/:id
POST /api/v1/admin/users/:id/disable
POST /api/v1/admin/users/:id/enable
GET  /api/v1/admin/sellers
GET  /api/v1/admin/sellers/:id
POST /api/v1/admin/sellers/:id/approve
POST /api/v1/admin/sellers/:id/reject
POST /api/v1/admin/sellers/:id/suspend
POST /api/v1/admin/sellers/:id/reinstate
GET  /api/v1/admin/couriers
GET  /api/v1/admin/couriers/:id
POST /api/v1/admin/couriers/:id/approve
POST /api/v1/admin/couriers/:id/reject
POST /api/v1/admin/couriers/:id/suspend
POST /api/v1/admin/couriers/:id/reinstate
GET  /api/v1/admin/orders
GET  /api/v1/admin/orders/:id
POST /api/v1/admin/orders/:id/cancel
GET  /api/v1/admin/payments
GET  /api/v1/admin/payments/:id
POST /api/v1/admin/payments/:id/mark-paid
GET  /api/v1/admin/settings
PATCH /api/v1/admin/settings/:key
GET  /api/v1/admin/tax-settings
PATCH /api/v1/admin/tax-settings/:key
GET  /api/v1/admin/invoices
GET  /api/v1/admin/invoices/:id
POST /api/v1/admin/invoices/generate
GET  /api/v1/admin/support/tickets
GET  /api/v1/admin/support/tickets/:id
POST /api/v1/admin/support/tickets/:id/messages
POST /api/v1/admin/support/tickets/:id/in-progress
POST /api/v1/admin/support/tickets/:id/resolve
POST /api/v1/admin/support/tickets/:id/reopen
POST /api/v1/admin/support/tickets/:id/close
GET  /api/v1/admin/audit-logs
GET  /api/v1/admin/observability/summary
GET  /api/v1/admin/observability/requests
GET  /api/v1/admin/observability/orders
GET  /api/v1/admin/observability/jobs
```

---

## 8. Casos de Borda, Regras Transacionais e Tratamento de Erros

### Checkout

`CheckoutService` deve, em uma única `ActiveRecord::Base.transaction`:

1. autenticar/resolver customer;
2. consumir `Idempotency-Key` com payload digest;
3. validar seller approved, product ownership/activity, address ownership e quantidades;
4. recalcular subtotal, fee, courier fee, discounts e total;
5. decrementar inventário por conditional update (`quantity >= requested`) e verificar affected rows;
6. criar order com address/fee snapshots;
7. criar immutable order items;
8. criar exatamente um initial payment record por order;
9. criar initial order history;
10. criar outbox event;
11. limpar cart somente após sucesso.

Dois checkouts concorrentes para a última unidade: no máximo um sucesso, inventory nunca negativo, perdedor recebe `insufficient_inventory` e não deixa order/payment/event parcial.

### Restauração de inventário

- Decrement at checkout é a política MVP.
- Reject/cancel restaura exatamente uma vez.
- Use `InventoryMovement` + unique key por order/product/kind ou mecanismo equivalente para tornar restore idempotente.

### Order transitions

- State update, history e outbox event são uma única consistency boundary.
- Seller ownership/courier assignment são conferidos dentro da mesma operação autoritativa.
- Outro seller/customer/courier não pode inferir nem mutar recurso alheio.

### Courier assignment

Use conditional update atômico equivalente a:

```sql
UPDATE orders
SET courier_id = ?, state = 'assigned'
WHERE id = ? AND state = 'ready' AND courier_id IS NULL
```

Apenas courier approved + available aceita. Exatamente um winner; loser recebe `conflict`. Assignment + courier operational state + order history + outbox devem permanecer consistentes.

### Guest-cart handoff

- Mesmo seller: merge quantidades respeitando limites e inventário atual.
- Seller diferente: somente replace quando `replace_confirmed=true`.
- Nunca perca guest cart silenciosamente.
- Guest external token é opaco, armazenado por digest e removido/expirado por cleanup job.

### Cancelamento e rejeição

Política provisória e explícita:

- customer pode cancelar somente order `pending` e com Payment `pending`;
- admin pode cancelar `accepted` ou `assigned` somente enquanto Payment estiver `pending`; paid orders não podem ser cancelados até que refund seja promovido — retornar `conflict`;
- seller pode rejeitar order `pending`; reason é opcional para reject e obrigatório para cancel;
- reject/cancel muda Payment `pending -> failed` com reason code `order_rejected` ou `order_cancelled`;
- restauração de inventário exatamente uma vez, payment transition, order history, audit e outbox são atômicos;
- order `pending` com Payment ainda `pending` expira após 30 minutos por job idempotente: order `pending -> cancelled`, payment `pending -> failed`, inventário restaurado e outbox persistido;
- não exponha qualquer transição que não esteja na state machine canônica.

### Support e invoices

- Ticket pode referenciar apenas order pertencente ao customer criador; ticket + mensagem inicial são atômicos.
- Support messages são append-only e sempre identificam sender/timestamp.
- Invoice identifica seller, period start/end, amount/currency, state (`pending`, `paid`, `cancelled`) e timestamps.
- Fee/settings usados para geração são effective-dated ou snapshotados; mudanças não alteram orders/invoices históricos.

### Tracking e privacidade

- Courier publica location apenas durante delivery `assigned` ou `picked_up`, após consentimento registrado.
- Rate limit mínimo entre updates: 5 segundos.
- Customer lê localização somente de order próprio e enquanto lifecycle permite.
- Payload inclui `recorded_at` e `freshness_seconds`; não promete stream real-time.
- Retenção provisória: 24 horas; cleanup job remove locations expiradas sem apagar histórico comercial.

### Falhas gerais

- DB indisponível: `/readyz` 503; `/healthz` continua 200 se o runtime responde.
- JSON inválido/unknown field: `invalid_input` sem executar mutação.
- Transition inválida: `state_transition_not_allowed` sem efeitos parciais.
- Replayed command: resultado idempotente ou `idempotency_conflict`.
- Unknown outbox event: não marcar como sucesso; registrar e tornar operator-visible.
- Poison job: retries bounded com backoff, `last_error`, next attempt e estado terminal visível.
- Erro interno: `internal_failure`, sem stack trace/secret/PII no client ou log rotineiro.

---

## 9. Payment, Outbox e Providers

- Defina interface `Payments::Gateway` provider-neutral.
- Implemente `Payments::SimulatedGateway`; checkout cria exatamente um Payment `pending` e o fluxo administrativo simula a confirmação com `POST /api/v1/admin/payments/:id/mark-paid`.
- Seller só pode aceitar order quando Payment estiver `paid`; o smoke flow deve confirmar o pagamento antes do aceite.
- `mark-paid` é idempotente: repetir sobre Payment já `paid` retorna o resultado atual; falha com `conflict` se order estiver `rejected`/`cancelled` ou Payment estiver `failed`.
- Payment `pending` expira em 30 minutos conforme a política de cancelamento; `paid` não expira.
- Amount/currency vêm do order snapshot e nunca do request administrativo.
- Não exponha callback externo enquanto não houver provider real; marque PAY-005/SEC-011 como `conditional_not_applicable` e mantenha contract tests da interface para futura implementação.
- Provider failure nunca pode corromper order/inventory/payment; use estado recuperável.
- `OutboxEvent` nasce na transação de negócio.
- Dispatcher periódico Solid Queue procura pending events; não dependa exclusivamente de enqueue-after-commit, pois o processo pode morrer após o commit.
- Handlers são idempotentes, têm bounded retry/backoff, recuperam leased work e deixam poison events visíveis.

---

## 10. Segurança, Privacidade e Operações

- Credenciais/secrets por credentials/ENV; validar mandatory config no boot.
- TLS/secure headers em produção; CSP, `X-Content-Type-Options`, frame/referrer policy e cookie flags.
- CSRF + origin protection para mutações browser/cookie-based.
- Payload size limit e strict unknown-field policy.
- Uploads: tamanho, content type e conteúdo validados; nome/storage key gerado no servidor; sem path traversal nem conteúdo executável inline.
- Logs: JSON em produção, request ID, method/path/status/duration; redigir password, cookies, tokens, address, exact location e payment-sensitive data.
- Audit: admin moderation, user activation, payment transition, settings/fees e ticket state changes.
- Observability deve permitir medir request rate/latency/status/error, dependency health/latency, SQLite contention, queue depth/age, registrations/logins por ator, approved sellers, in-stock products, carts, checkouts por resultado, orders por estado, courier availability/deliveries, payments, ticket age, jobs/retries e failures.
- Não registrar secrets ou localização precisa em métricas/logs.
- Criar `docs/PRIVACY_BACKEND.md` com classificação, finalidade, acesso, retenção, export/anonymization, location policy, backup implications e itens jurídicos ainda bloqueantes.
- Implementar `Privacy::ExportService` e `Privacy::AnonymizeService` preservando order/audit/history; retenção legal definitiva exige aprovação antes de produção.
- Criar `docs/OPERATIONS.md`: boot, deployment, migration, forward-fix/rollback, backup, restore, secret rotation, incident response e shutdown.
- Backup deve cobrir DB primário e uploads necessários; queue/outbox recovery deve ser documentado.
- Criar task de backup e task de restore/teste, definir mecanismo automatizado/agendamento no deployment e documentar retenção/monitoramento. Targets provisórios: RPO 24h, RTO 4h; não declarar produção pronta sem aprovação e restore evidence.
- Validar graceful SIGTERM do Puma + Solid Queue: parar novos requests, encerrar worker e liberar DB dentro do timeout documentado.

---

## 11. TDD Obrigatório — RED → GREEN → REFACTOR

**Toda mudança comportamental deve nascer de um teste falhando. Código produzido sem o ciclo abaixo está incompleto.**

### Ciclo obrigatório por comportamento

1. **RED**
   - escreva o menor teste que descreve um único comportamento/requisito;
   - execute somente esse teste;
   - confirme que ele falha pela ausência/incorreção do comportamento, não por syntax error, fixture quebrada ou setup inválido;
   - registre no andamento qual requirement ID o teste cobre.
2. **GREEN**
   - implemente o mínimo necessário para o teste passar;
   - execute novamente o teste focado;
   - não antecipe abstrações ou casos ainda não testados.
3. **REFACTOR**
   - remova duplicação e melhore nomes/boundaries sem mudar comportamento;
   - execute os testes do domínio/slice afetado.
4. **REGRESSION**
   - execute toda a suíte ao final da fatia;
   - execute lint e security scanners;
   - só então marque requisitos como `verified` na matriz.

### Regras TDD

- Não criar controller action, service branch, state transition, policy rule ou job handler antes do teste correspondente falhar.
- Migrations/configuração gerada podem preceder código de comportamento, mas devem ganhar migration/startup/integration test na mesma fatia.
- Todo bug corrigido exige teste de regressão que falhe antes da correção no menor nível útil; se client-visible, acrescente request/API integration test.
- Testes verificam comportamento/contrato, não métodos privados ou detalhes acidentais.
- Cada endpoint precisa de: success, invalid input, unauthenticated quando aplicável, forbidden/ownership, not found, conflict/state failure e sanitização de internal failure.
- Policies devem ter testes cruzados entre atores e objetos de owners diferentes.
- Use fixtures Rails; não adicionar factory gem.
- A suíte existente paraleliza. Testes de concorrência SQLite devem usar DB compartilhado controlado, conexões distintas e cleanup explícito; não confundir parallel test DBs com concorrência real.
- Para testes concorrentes específicos, desabilite transactional fixture apenas no caso necessário e garanta restauração do estado.
- Nunca tornar teste flaky aceitável por retry cego.

### Camadas obrigatórias

- **Domain unit (TST-001):** state machines, money, totals, inventory, permissions, fee e validation.
- **Persistence integration (TST-002):** migrations, FK/unique constraints, transactions, pagination, WAL, conditional updates.
- **Identity integration (TST-003):** login, expiry, logout/revocation, disabled user, role mapping, bootstrap.
- **Application contract (TST-004):** todos endpoints/envelopes/status/error taxonomy.
- **Provider contract (TST-005):** simulated payment, storage e jobs com failures/retry.
- **API E2E (parte backend de TST-007):** ciclo completo seller/customer/courier/admin por HTTP.
- **Security (TST-008):** object authorization, rate limit, CSRF/origin, session, upload, redaction.
- **Concurrency (TST-009):** oversell e courier single-winner.
- **Recovery (TST-010):** outbox após restart, retry e backup restore.
- **Performance (TST-011):** contention e assignment load smoke com targets documentados.
- **Frontend/component (TST-006) e acessibilidade/browser de TST-012:** `deferred_frontend`, sem fingir cobertura; verificar agora compatibilidade/versionamento do contrato API via OpenAPI e contract tests.

---

## 12. Instruções de Execução Técnico-Práticas — Fatias Verticais

Cada fatia deve conter no task/commit: requirement IDs, outcome, scope/non-scope, regras, API, migration, segurança, observabilidade, teste RED/GREEN, rollback/forward-fix, evidence e estimativa de esforço/risco. A estimativa inclui domínio, contratos, migrations, adapters, testes, segurança, observabilidade, documentação e contingência.

1. **Foundation:** arquitetura/worksheet, matriz, config, UUIDv7, JSON/error contract, request ID, logs, `/healthz`, `/readyz`.
2. **Identity:** User, RoleAssignment, Session, bcrypt, CSRF, register/login/logout/me, admin bootstrap, rate limit.
3. **Seller + moderation + catalog + inventory:** seller membership, profile/settings, admin moderation, categories, products, media metadata, inventory.
4. **Public discovery + guest cart:** approved sellers/products, opaque guest context, trusted prices, retention and handoff policy.
5. **Customer:** profile, addresses/default/snapshot policy, favorites, persistent seller-scoped carts.
6. **Checkout:** idempotency, authoritative totals, inventory concurrency, order/items/history/payment/outbox, cart clear.
7. **Seller orders:** listing/detail/ownership, accept/reject/preparing/ready, inventory restore where applicable.
8. **Courier:** onboarding/moderation, availability, eligible queue, atomic assignment, pickup/delivery, stats.
9. **Tracking:** location consent/rate/freshness/retention and customer-owned tracking.
10. **Support:** ticket+initial message transaction, customer/admin messages, state machine and audit.
11. **Admin:** dashboard, users, moderation, orders/payments, settings/fees, invoices, support, audit, observability.
12. **Uploads + provider/outbox hardening:** Active Storage validation, provider contracts, dispatcher/retry/poison work.
13. **Operations/release evidence:** privacy, backup/restore automatizável, graceful shutdown, load/security/recovery tests, OpenAPI, smoke, atualização do CI quality gate e requirement matrix review.

Não avance para a próxima fatia se a atual estiver vermelha.

---

## 13. Smoke Flow do Backend

Crie `script/smoke_backend.sh`, determinístico para DB limpa. Boot e bootstrap admin são precondições controladas por comando Rails; todo o fluxo de negócio posterior usa apenas HTTP:

1. boot/health/readiness;
2. bootstrap admin;
3. registrar seller e concluir onboarding;
4. admin aprovar seller;
5. seller criar category/product/inventory;
6. public listar seller/product e iniciar guest cart;
7. registrar customer, handoff cart e criar address;
8. checkout com idempotency key;
9. admin confirmar o Payment simulado como `paid`;
10. seller aceitar/preparar/marcar ready;
11. registrar e aprovar courier; courier available;
12. courier aceitar/pickup/enviar location/deliver;
13. customer ler tracking/order;
14. customer criar ticket; admin responder/inspecionar;
15. admin ver dashboard/audit/final state.

Pare no primeiro contrato quebrado. Linha final obrigatória:

```text
JaChegai Rails backend smoke test passed
```

---

## 14. Restrições e Proibições

- ⛔ Não acessar, listar ou executar nada fora da raiz deste repositório.
- ⛔ Não acessar `jachegai-next`, caminhos absolutos dos docs ou referências externas locais.
- ⛔ Não criar Go, `cmd/jachegai`, `internal/*`, `sqlc`, React, `web/*` ou frontend de produto.
- ⛔ Não usar Devise, Pundit, CanCan, Rack::Attack, state-machine gems, ORM adicional ou dependência sem aprovação.
- ⛔ Não aceitar ID, price, fee, total, role admin ou ownership autoritativo do cliente.
- ⛔ Não armazenar senha, session token ou guest token em plaintext.
- ⛔ Não expor stack trace, SQL error, secret, cookie, token, PII ou exact location em response/log.
- ⛔ Não usar callbacks Active Record para orquestração transacional complexa; usar services explícitos.
- ⛔ Não criar hidden mutation em GET.
- ⛔ Não fazer hard delete de histórico comercial/auditoria/support messages.
- ⛔ Não expor cancelamento, payment callback ou state transition sem política explícita e teste.
- ⛔ Não marcar requisito `verified` sem evidence automatizada ou revisão documentada.
- ⛔ Não alegar MVP completo enquanto requisitos frontend estiverem `deferred_frontend`.
- ⛔ Não implementar produção antes do teste RED correspondente, salvo scaffolding/migration conforme exceção TDD documentada.

---

## 15. Comandos de Validação

### Durante o TDD

```bash
bin/rails test test/path/to/focused_test.rb
bin/rails test test/path/to/focused_test.rb:LINE
bin/rails test test/services test/domain
```

### Ao final de cada fatia

```bash
bin/rails db:migrate
bin/rails db:test:prepare
bin/rails test
bin/rails routes | grep /api/v1
bin/rubocop
bin/brakeman --no-pager
```

### Quality gate final

```bash
RAILS_ENV=test bin/rails db:drop db:create db:migrate
bin/rails test
bin/rubocop
bin/brakeman --no-pager
bin/bundler-audit
bin/importmap audit
bin/rails runner 'abort unless Rails.application.class.module_parent.name == "JachegaiRails"'
```

Validação HTTP:

```bash
bin/rails server
curl -fsS http://localhost:3000/healthz
curl -fsS http://localhost:3000/readyz
bash script/smoke_backend.sh
```

Não declarar sucesso se qualquer comando aplicável falhar.

---

## 16. Definition of Done — Backend MVP

- [ ] `docs/BACKEND_ARCHITECTURE_RAILS.md` contém worksheet, diagrams textuais, decisões, alternativas rejeitadas, consistency boundaries e recovery model.
- [ ] `docs/BACKEND_REQUIREMENTS_MATRIX.md` contém os 197 IDs sem lacunas e evidence/status honesto.
- [ ] Todos os requisitos backend em escopo estão `verified`; frontend está explicitamente `deferred_frontend`.
- [ ] OpenAPI 3.1 corresponde às rotas e aos request tests.
- [ ] Todas as rotas de backend necessárias estão sob `/api/v1`, além de `/healthz` e `/readyz`.
- [ ] Auth, session revocation, role/object authorization e admin bootstrap passam.
- [ ] Seller publica produto/inventory; customer faz checkout idempotente; seller prepara; courier aceita uma vez e entrega; customer acompanha; admin opera; support funciona.
- [ ] Checkout concorrente não oversella e courier assignment concorrente tem um vencedor.
- [ ] Históricos, snapshots, audit e outbox respeitam atomicidade e imutabilidade.
- [ ] Rate limits, CSRF/origin, upload validation, strict input e log redaction passam.
- [ ] Jobs recuperam pending work, retry é bounded e poison work é visível.
- [ ] Backup/restore smoke e graceful shutdown foram demonstrados/documentados.
- [ ] `script/smoke_backend.sh` termina com `JaChegai Rails backend smoke test passed`.
- [ ] Load smoke registra e atende os targets provisórios locais: p95 de reads < 500 ms e p95 de checkout < 1 s, com ambiente e limitações documentados.
- [ ] A imagem de produção Rails é construída e executada como um único deployable unit; health/readiness e smoke passam contra ambiente production-like com volume persistente.
- [ ] `bin/rails test`, `bin/rubocop`, `bin/brakeman`, `bin/bundler-audit` e `bin/importmap audit` passam.
- [ ] Nenhum teste foi escrito apenas depois do código: o histórico de execução por fatia registra RED → GREEN → REFACTOR.
- [ ] A entrega é descrita como backend MVP; nenhuma alegação falsa de MVP completo ou frontend concluído.

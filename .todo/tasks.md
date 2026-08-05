# JaChegai Rails Backend — TDD Task List

> Gerado a partir de `.prompts/prompt.md` e de `docs/PORTABLE_PRODUCT_SPEC.md`.
> Escopo: backend Rails MVP. Frontend, PWA, acessibilidade visual e UI system estão adiados.
> Regra: esta entrega pode ser chamada de **backend MVP**, nunca de produto MVP completo.

## Legenda

- `[ ]` não iniciado
- `[~]` em andamento
- `[x]` concluído e verificado
- `[!]` bloqueado — registrar motivo
- `P0` obrigatório para backend MVP
- `P1` obrigatório para production readiness
- `P2` adiado para frontend/pós-MVP

## Protocolo TDD obrigatório para toda tarefa comportamental

Uma tarefa só pode ser marcada `[x]` depois de completar e registrar:

1. **RED:** escrever o menor teste focado, executá-lo e confirmar falha pelo comportamento ausente/incorreto.
2. **GREEN:** implementar somente o necessário e executar o teste focado até passar.
3. **REFACTOR:** melhorar design/nomenclatura sem alterar comportamento e rodar testes da área.
4. **REGRESSION:** rodar a suíte da fatia e os gates aplicáveis.
5. **EVIDENCE:** atualizar `docs/BACKEND_REQUIREMENTS_MATRIX.md` com arquivo de teste/comando/status.

Regras adicionais:

- não implementar controller action, policy, service branch, state transition ou job handler antes do RED;
- migrations/scaffolding podem preceder comportamento, mas exigem teste de persistence/startup na mesma fatia;
- todo bug corrigido recebe primeiro um teste de regressão falhando;
- não avançar de fatia enquanto a atual estiver vermelha;
- não marcar requisito `verified` sem evidência executada;
- manter todas as operações dentro da raiz deste repositório.

## Quality gate de cada fatia

```bash
bin/rails db:migrate
bin/rails db:test:prepare
bin/rails test
bin/rails routes | grep /api/v1
bin/rubocop
bin/brakeman --no-pager
```

---

# Fase 00 — Baseline, arquitetura e rastreabilidade

**Prioridade:** P0  
**Dependências:** nenhuma  
**Risco:** alto — impede omissões dos 197 requisitos.

## T00.1 — Registrar baseline do Rails atual

- [x] Executar e registrar o resultado inicial de:
  ```bash
  bin/rails test
  bin/rubocop
  bin/brakeman --no-pager
  bin/bundler-audit
  bin/importmap audit
  bin/rails runner 'puts Rails.application.class.module_parent.name'
  ```
- [x] Confirmar `JachegaiRails` como namespace da aplicação.
- [x] Confirmar Ruby `4.0.6`, Rails `8.1.3`, SQLite e minitest.
- [x] Registrar falhas preexistentes sem mascará-las.
- [x] Confirmar que não existe remote Git; se um remote for adicionado depois, sincronizar issues abertas em `.todo/issues.md` antes de continuar.

## T00.2 — Criar arquitetura Rails documentada

**Arquivo:** `docs/BACKEND_ARCHITECTURE_RAILS.md`

- [x] Preencher toda a decision worksheet da seção 25 da spec.
- [x] Registrar modular monolith Rails + SQLite + Active Record + Solid Queue.
- [x] Registrar diagramas textuais de componentes e deployable units.
- [x] Registrar data ownership e consistency boundaries:
  - checkout/inventory;
  - order transition/history/outbox;
  - courier assignment;
  - payment transition/idempotency;
  - moderation/audit;
  - ticket/initial message.
- [x] Registrar identity/session/authorization flow.
- [x] Registrar background recovery, backup/restore e failure model.
- [x] Registrar alternativas rejeitadas: plano Go, serviços separados, broker externo, Redis, provider real no MVP.
- [x] Registrar limitações de SQLite e estratégia para concorrência.
- [x] Registrar integração futura de identity/payment/storage por adapters.

## T00.3 — Criar matriz com os 197 requirement IDs

**Arquivo:** `docs/BACKEND_REQUIREMENTS_MATRIX.md`

- [x] Extrair todos os IDs de `docs/PORTABLE_PRODUCT_SPEC.md`.
- [x] Criar exatamente uma linha por ID com colunas:
  `Requirement | Summary | Slice | Rails component | Test/evidence | Status | Deviation`.
- [x] Usar apenas: `planned`, `implemented`, `verified`, `deferred_frontend`, `conditional_not_applicable`, `blocked`.
- [x] Classificar requisitos visuais/frontend honestamente como `deferred_frontend`.
- [x] Classificar callback de payment provider como `conditional_not_applicable` enquanto só houver gateway simulado.
- [x] Não marcar qualquer requisito como `verified` nesta fase.
- [x] Criar validação automatizada que compare IDs da spec com a matriz e falhe por ausente, duplicado ou ID desconhecido.
- [x] **RED:** executar o teste/script antes de a matriz estar completa e observar falha.
- [x] **GREEN:** completar a matriz até 197/197.
- [x] **REFACTOR:** ordenar por prefixo/número e remover duplicações.

## T00.4 — Criar esqueleto OpenAPI

**Arquivo:** `docs/api/openapi.yaml`

- [x] Definir OpenAPI 3.1, servers locais, schemas de envelopes e taxonomia de erros.
- [x] Definir security scheme baseado em session cookie + CSRF header.
- [x] Inserir inicialmente `/healthz`, `/readyz` e namespaces de `/api/v1`.
- [x] Adicionar teste que parseia o YAML e valida versão/schema básico.
- [x] Manter paths/schemas atualizados em cada fatia.

## Gate Fase 00

- [x] Arquitetura revisada contra a spec.
- [x] Matriz contém exatamente 197 IDs.
- [x] OpenAPI é parseável.
- [x] Baseline registrado.

---

# Fase 01 — Foundation, contrato e health

**Prioridade:** P0  
**Dependências:** Fase 00  
**Requisitos principais:** DAT-001..004, DAT-010..011, NFR-001..003, NFR-007, NFR-013..019, SEC-008, SEC-010, TST-002, TST-004.

## T01.1 — Configuração centralizada e I18n

- [x] Criar configuração `config.x.jachegai` validada.
- [x] Definir env vars, defaults seguros e mandatory production config.
- [x] Configurar UTC e serialização ISO-8601.
- [x] Configurar locale padrão `pt-BR` e `config/locales/pt-BR.yml`.
- [x] **RED/GREEN/REFACTOR:** testes de configuração inválida e mensagens traduzidas.
- **Evidência:** `app/lib/jachegai_configuration.rb`, `test/lib/jachegai_configuration_test.rb` (4), `config/application.rb`, `.env.example`.

## T01.2 — UUIDv7 server-side

**Arquivos:** `app/lib/application_id.rb`, `app/models/application_record.rb`.

- [x] **RED:** teste de formato, version bit 7, unicidade e ordenação temporal.
- [x] **RED:** teste de ID client-provided não autoritativo.
- [x] **GREEN:** `ApplicationId.generate` com `SecureRandom.uuid_v7`.
- [x] Concern/base pattern de atribuição e rejeição de IDs externos.
- [x] **REFACTOR:** fonte comum via `ApplicationRecord`.
- **Evidência:** `test/lib/application_id_test.rb` (6), `app/lib/application_id.rb`, `app/models/application_record.rb`.

## T01.3 — SQLite operational baseline

- [x] **RED:** teste de `PRAGMA foreign_keys = ON`.
- [x] **RED:** teste de `journal_mode = WAL` e busy timeout.
- [x] **GREEN:** configurar connection hook/initializer compatível com Rails.
- [x] Testar readiness query simples e falha controlada.
- [x] Documentar efeito de test DBs paralelos e conexões.

## T01.4 — JSON envelope e domain error taxonomy

**Arquivos esperados:** `app/controllers/api/v1/base_controller.rb`, `app/lib/domain_error.rb`, `app/controllers/concerns/` se necessário.

- [x] **RED:** teste de envelope success com `ok`, `data`, `meta`.
- [x] **RED:** testes de cada error code/status mapping.
- [x] **RED:** internal error não expõe exception, SQL ou stack trace.
- [x] **GREEN:** responder com helpers e error mapping centralizados.
- [x] Não usar `204`; toda resposta de sucesso usa envelope.
- [x] Mensagens client-visible via I18n; field details com códigos estáveis.
- [x] **REFACTOR:** controllers não duplicam render/error logic.

## T01.5 — Strict JSON input

- [x] **RED/GREEN:** JSON malformado, Content-Type incorreto e unknown fields retornam erros estáveis.
- [x] **RED/GREEN:** body acima de 256 KiB retorna 413 sem mutação.
- [x] **GREEN:** parser reutilizável em `StrictJson`; middleware rejeita `Content-Length` excedente.
- [x] GET não cria estado oculto.
- **Evidência:** `app/lib/strict_json.rb`, `app/middleware/request_body_limit.rb`, `test/lib/strict_json_test.rb`, `test/controllers/api/v1/auth_controller_test.rb`.

## T01.6 — Request ID e logging estruturado

- [x] Request sem ID recebe ID e request ID válido é propagado.
- [x] Middleware registra method/path/status/duração/request_id.
- [x] Filtros removem credenciais e tokens de parâmetros.
- [x] JSON formatter em produção e `Current.request_id`/principal context.
- **Evidência:** `app/middleware/{request_context,request_logger}.rb`, `app/lib/jachegai_json_formatter.rb`, `config/initializers/jachegai_logging.rb`, `test/middleware/{request_id_test,logging_test}.rb`.

## T01.7 — Liveness e readiness

- [x] `/healthz` retorna 200 independente do banco.
- [x] `/readyz` retorna 200 com DB acessível e 503 em falha.
- [x] Controllers/routes independentes do domínio; `/up` removido.
- [x] OpenAPI atualizado.
- **Evidência:** `app/controllers/health_controller.rb`, `test/controllers/health_controller_test.rb`, `docs/api/openapi.yaml`.

## Gate Fase 01

- [x] Testes focados passaram após RED observado.
- [x] Quality gate da fatia passou.
- [x] Matriz/OpenAPI atualizados com evidências.
- [x] `/healthz` e `/readyz` validados via testes e execução local.
- **Evidência:** 140 runs / 357 assertions / 0 failures; RuboCop 77 limpos; Brakeman 0 warnings.

---

# Fase 02 — Identity, sessions, CSRF e authorization

**Prioridade:** P0  
**Dependências:** Fase 01  
**Requisitos:** IAM-001..010, SEC-001..008, SEC-010, SEC-014..015, TST-003..004, TST-008.

## T02.1 — Dependência bcrypt e schema de identity

- [x] Descomentar/adicionar apenas `gem "bcrypt", "~> 3.1.7"` e atualizar lockfile.
- [x] Criar migrations UUIDv7 para `users`, `role_assignments`, `sessions` conforme o registration flow (customers/sellers/couriers são fases posteriores).
- [x] Foreign keys, unique indexes e timestamps UTC.
- [x] Session armazena somente token digest, `expires_at`, `revoked_at`, `last_seen_at` e metadata mínima.
- [x] **RED:** persistence tests de FK, unique email normalizado, roles e token digest.
- [x] **GREEN:** migrations/models mínimos.
- **Evidência:** migrations `20260801172027_create_users`, `20260801172028_create_role_assignments`, `20260801172029_create_sessions` (id string UUIDv7, FK ON); `app/models/{user,role_assignment,session}.rb`; `test/models/{user_test,session_test,role_assignment_test}.rb` (11).

## T02.2 — User e roles

- [x] **RED:** password hash funciona e plaintext não é persistido.
- [x] **RED:** senha menor que 8 falha.
- [x] **RED:** email normalizado/duplicado falha sem leak.
- [x] **RED:** registro público de `admin` falha.
- [x] **RED:** role assignment suporta customer/seller/courier e múltiplos papéis futuros.
- [x] **GREEN:** models e validations.
- [x] **REFACTOR:** autorização delegada a policies (roles são leitura via `has_role?`; sem setter público de roles).

## T02.3 — Session service e Current.principal

- [x] **RED:** login válido cria sessão e retorna token Bearer opaco.
- [x] **RED:** banco contém digest, nunca token plaintext.
- [x] **RED:** sessão expira em 7 dias absolutos.
- [x] **RED:** logout revoga sessão.
- [x] **RED:** sessão expirada/revogada/disabled user é rejeitada.
- [x] **RED:** novo login revoga a sessão anterior.
- [x] **GREEN:** `SessionService`, token digest e política de token Bearer.
- [x] **GREEN:** normalizar `Current.principal` com ID, roles, active, session e request ID.
- [x] **REFACTOR:** services/policies não leem credencial diretamente.
- **Evidência:** `app/services/session_service.rb`, `app/lib/principal.rb`, `app/models/current.rb`; `test/services/session_service_test.rb` (9), `test/lib/principal_test.rb` (3), `test/models/session_test.rb`.

## T02.4 — Policies e object-level authorization base

- [x] Criar `BasePolicy`, `AuthorizationError` e helper `authorize!` sem gem externa.
- [x] **RED:** unauthenticated difere de forbidden.
- [x] **RED:** role errada é bloqueada.
- [x] **RED:** ownership diferente é bloqueado sem data disclosure.
- [x] **GREEN:** policy base + scopes.
- [x] Criar shared test cases para customer/seller/courier/admin.
- **Evidência:** `app/policies/base_policy.rb`, `test/policies/base_policy_test.rb`, `test/support/api_test_controller.rb` + `TestApiPolicy`, `test/controllers/api/v1/policy_authorization_test.rb`; BaseController com `authenticate!`/`authorize!`/`bearer_token` (401 vs 403).

## T02.5 — Auth API

Rotas:

```text
POST /api/v1/auth/register
POST /api/v1/auth/login
POST /api/v1/auth/logout
GET  /api/v1/auth/me
```

Para cada endpoint:

- [x] **RED:** success contract.
- [x] **RED:** malformed/unknown input.
- [x] **RED:** unauthenticated/forbidden quando aplicável.
- [x] **RED:** internal failure sanitizado.
- [x] **GREEN:** controller fino + service.
- [x] Registro customer cria Customer; seller/courier inicia relação de onboarding pendente (roles derivadas, sem Customer ainda — fases posteriores).
- [x] Login inválido usa mensagem indiferenciada.
- [x] Atualizar OpenAPI.
- **Evidência:** `app/controllers/api/v1/auth_controller.rb` (register 201, login 200, me, logout; transação), `test/controllers/api/v1/auth_controller_test.rb` (9), curl real (UUIDv7 `019fbe90-…`, roles); StrictJson → string keys (payload["email"]).

## T02.6 — CSRF e origin protection

- [x] **RED:** mutação com Origin não permitido falha.
- [x] **RED:** Origin permitido e cliente sem Origin permitem request API.
- [x] **GREEN:** validação exata de origem (scheme/host/porta) no middleware; sem cookie de sessão.
- [x] Credencial usa Bearer token; produção força HTTPS via `FORCE_SSL`.
- **Evidência:** `app/middleware/origin_policy.rb` + inserção no `config/application.rb`; `ALLOWED_ORIGINS` em `.env.example`; `config/environments/production.rb`; `test/middleware/origin_policy_test.rb` (3).

## T02.7 — Rate limiting de identity

- [x] **RED:** sexta tentativa de login no minuto é 429.
- [x] **RED:** limiter funciona por IP e identifier normalizado.
- [x] **RED:** não revela existência da conta.
- [x] **GREEN:** limiter fixed-window via `RateLimiter` com `RailsCacheStore` em produção e `MemoryStore` isolado em testes.
- [x] Limite aplicado por IP e identifier normalizado, com headers `X-RateLimit-*`/`Retry-After` e evento redigido.
- **Evidência:** `app/lib/rate_limiter.rb`, `app/controllers/api/v1/base_controller.rb`, `app/controllers/api/v1/auth_controller.rb#login`, `config/locales/pt-BR.yml`, `test/lib/rate_limiter_test.rb` (5), `test/controllers/api/v1/rate_limit_test.rb` (3).

## T02.8 — Bootstrap admin

- [x] **RED:** task sem env obrigatória falha claramente.
- [x] **RED:** primeira execução cria um admin.
- [x] **RED:** repetição é idempotente.
- [x] **RED:** não sobrescreve admin existente.
- [x] **GREEN:** task `jachegai:bootstrap_admin`.
- [x] Documentar uso sem expor senha.
- **Evidência:** `lib/tasks/bootstrap.rake` (EMAIL/PASSWORD/FULL_NAME; cria usuário ou adiciona admin sem sobrescrever usuário existente; aborta sem env), `test/tasks/bootstrap_admin_test.rb` (4), verificação CLI real.

## Gate Fase 02

- [x] Todos os casos de identity/authorization verdes.
- [x] Security request tests verdes.
- [x] OpenAPI e matriz atualizados.
- [x] Quality gate passou.
- **Evidência Gate atualizada:** 141 runs / 359 assertions / 0 failures; RuboCop 77 arquivos limpos; Brakeman 0 warnings; OpenAPI documenta auth Bearer, envelopes, 413/429 e health; matriz atualizada distinguindo `verified` de `implemented`.

---

# Fase 03 — Seller, moderation, catalog e inventory

**Prioridade:** P0  
**Dependências:** Fase 02  
**Requisitos entregues nesta fase:** SEL-001, SEL-003..008, IAM-004, DAT-004/005/007/010, SEC-007, ADM-003/009.  
**Preparação parcial, sem declarar conclusão:** DAT-009 (reserva concorrente na Fase 06), SEL-002 (visibilidade pública em T04.2), SEL-009..012 (Fase 07) e SEL-013 (Fase 12).

## T03.1 — Schema do seller domain

- [x] Migrations para `sellers`, `seller_memberships`, `seller_settings`, `categories`, `products`, `inventory_items` e media attachment metadata. — 73001–73008 aplicadas; uploads com owner polymorphic + storage_key único.
- [x] Seller moderation states e constraints. — `moderation_state` default `pending_review`, validação no model e CHECK `seller_moderation_state_valid` no banco.
- [x] Category `position` seller-scoped com ordenação determinística. — índice unique `(seller_id, position)` e scope ordered `(position, id)`; reorder usa faixa temporária sem colisões.
- [x] Product price em `price_cents` + `currency`. — colunas not null default 0/BRL; validações >= 0 e [A-Z]{3}.
- [x] Inventory quantity com check `>= 0` e unique product index. — CHECK inventory_quantity_non_negative + index único em product_id.
- [x] **RED:** migration/invariant tests. — 8 arquivos model test (seller, membership, settings, category, product, inventory, upload, audit).
- [x] **GREEN:** migrations/models. — 28 runs/66 assertions verdes em test/models/*.

## T03.2 — Seller onboarding/profile/settings

Rotas:

```text
POST  /api/v1/seller/onboarding
GET   /api/v1/seller/profile
PATCH /api/v1/seller/profile
GET   /api/v1/seller/settings
PATCH /api/v1/seller/settings
```

- [x] **RED:** seller role completa onboarding uma vez. — test/services/seller_onboarding_service_test.rb + onboarding_controller_test.rb (201, pending_review).
- [x] **RED:** outro papel/owner é bloqueado. — 403 forbidden para non-seller; 404 para perfil sem seller (sem disclosure).
- [x] **RED:** profile/settings validam unknown fields e dados. — StrictJson unknown_fields (422) + validações de email/currency.
- [x] **GREEN:** services/policies/controllers. — SellerOnboardingService, SellerPolicy, ProfileController, SettingsController.
- [x] Testar estado inicial `pending_review`. — onboarding_controller_test.rb e seller_test.rb.

## T03.3 — Seller moderation state machine

- [x] **RED:** todas as transições válidas passam somente para admin. — controller e `ModerationService` validam autoridade; chamada direta por não-admin retorna forbidden e audita failure.
- [x] **RED:** todas as transições inválidas falham sem mudança. — SellerModeration::InvalidTransition; 409 invalid_transition; estado preservado.
- [x] **RED:** cada transição cria AuditLog completo. — audit success/failure com actor/action/reason/correlation_id; falha do audit reverte a mudança de estado.
- [x] **GREEN:** `SellerModeration` + `ModerationService`. — transição + audit de sucesso em uma transação atômica.
- [x] **REFACTOR:** state machine independente de HTTP/Active Record quando possível. — app/lib/seller_moderation.rb é pure Ruby, testado isoladamente.

## T03.4 — Categories

- [x] **RED:** create/list/update/order/remove do próprio seller. — categories_controller_test.rb (CRUD + PUT order).
- [x] **RED:** outro seller não lê/muta recurso privado. — 404 via scope `current_seller.categories.find`.
- [x] **RED:** delete com referências proibidas retorna conflict. — 409 category_in_use (test services + controller).
- [x] **GREEN:** API, policy e service. — CategoryPolicy, CategoryService, CategoriesController.
- [x] Garantir sorting por position + tie-breaker ID. — scope ordered `order(:position, :id)` + posição única por seller no banco.

## T03.5 — Products e activity

- [x] **RED:** CRUD, activate/deactivate e ownership. — products_controller_test.rb.
- [x] **RED:** price negativo, currency inválida e seller inconsistente falham. — 422 com fields context; category de outro seller rejeitada.
- [x] **RED:** produto histórico não sofre hard delete. — 409 product_in_use quando há inventory/uploads.
- [x] **GREEN:** models/services/API. — ProductService, ProductPolicy, ProductsController.
- [x] Preparar apenas metadata relacional de mídia sem declarar upload seguro. — Upload model/table criados; Active Storage, validação de conteúdo e serving seguro ficam em T12.1 (SEL-013 permanece planned).

## T03.6 — Inventory

- [x] **RED:** read/update só para seller owner. — inventory_controller_test.rb (404 para produto alheio).
- [x] **RED:** negative inventory falha no model e DB. — validação model + CHECK constraint; 422 no controller.
- [x] **RED:** product precisa pertencer ao seller. — inventory_item valida product_belongs_to_seller.
- [x] **GREEN:** inventory API/service com uma linha por produto e update transacional. — índice único, retry defensivo de `RecordNotUnique` e `with_lock`; teste real de contenção/overselling permanece Fase 06.

## T03.7 — Admin seller moderation routes

- [x] Implementar list/detail + approve/reject/suspend/reinstate. — Admin::SellersController + Admin::SellerPolicy (require_admin!).
- [x] **RED:** role guard, object existence, transition conflict e audit. — 403/404/409 e AuditRecord assertions.
- [x] **GREEN:** controllers finos usando ModerationService. — 9 testes admin verdes.
- [x] Atualizar OpenAPI. — todos os 18 paths seller/admin, schemas create/PATCH distintos, paginação bounded e respostas 400/403/404/409/413/422 testados.

## Gate Fase 03

- [x] Seller pending pode ser aprovado. — admin approve → approved + moderated_at + audit (admin/sellers_controller_test.rb).
- [x] Seller approved gerencia catalog/inventory próprio. — seller controllers + services verdes; pending/suspended/rejected podem consultar dados próprios, mas mutations retornam 403.
- [x] Outro seller não acessa/muta recursos. — 404 em categories/products/inventory para seller alheio; cardinalidade de um seller por usuário garantida no banco.
- [x] Payloads inválidos nunca sofrem coerção silenciosa. — onboarding/category/inventory/admin moderation cobertos para missing/type/content-type/JSON/unknown/size com códigos estáveis.
- [x] Coleções Fase 03 são determinísticas e paginadas. — default 25, máximo 100, meta count/page/per_page/total/total_pages.
- [x] Quality gate e matriz passaram após remediação. — 262 runs/754 assertions/0 failures; RuboCop 136 files/no offenses; Brakeman 0 errors/0 warnings; OpenAPI YAML válido; matriz mantém requisitos futuros como planned/implemented sem sobredeclaração.

---

# Fase 04 — Public discovery e guest cart

**Prioridade:** P0  
**Dependências:** Fase 03  
**Requisitos:** PUB-003..007, PUB-010, ORD-001..005, SEC-015. `PUB-008` depende do customer cart e do handoff explícito da Fase 05 (T05.5).

## T04.1 — Guest cart schema e opaque identity

- [x] Migrations `guest_carts`/`guest_cart_items` com expiry, quantity bounded constraint e timestamps; invariante de seller único no modelo e nas mutações transacionais.
- [x] Guest token aleatório; persistir apenas digest.
- [x] **RED:** token não é guessable/plaintext e expira em 7 dias.
- [x] **RED:** guest cart aceita apenas um seller.
- [x] **GREEN:** models/context resolver.

## T04.2 — Public seller/product discovery

- [x] **RED:** somente seller approved/publicável aparece.
- [x] **RED:** somente product active com inventory positivo aparece.
- [x] **RED:** price/availability vêm do banco, não de query/client.
- [x] **RED:** pagination/order determinísticos.
- [x] **GREEN:** public query services/controllers.

## T04.3 — Guest cart operations

Rotas GET/POST/PATCH/DELETE definidas no prompt.

- [x] **RED:** GET inexistente retorna cart vazio sem criar registro.
- [x] **RED:** add/update/remove valida quantity bounded integer.
- [x] **RED:** product inativo/outro seller/sem inventory falha.
- [x] **RED:** seller diferente sem `replace_confirmed` retorna conflict e preserva cart.
- [x] **RED:** seller diferente confirmado substitui atomicamente.
- [x] **GREEN:** cart service/controllers.
- [x] Aplicar rate limit de cart mutation.

## T04.4 — Guest cart cleanup

- [x] **RED:** job remove apenas carts expirados.
- [x] **RED:** retry é idempotente.
- [x] **GREEN:** Solid Queue recurring cleanup.

## Gate Fase 04

- [x] Visitor descobre seller/product e mantém guest cart por navegação normal; handoff para customer cart permanece Fase 05/T05.5.
- [x] Nenhuma hidden mutation em GET.
- [x] OpenAPI, matriz e quality gate atualizados.

---

# Fase 05 — Customer, addresses, favorites e persistent carts

**Prioridade:** P0  
**Dependências:** Fase 04  
**Requisitos:** CUS-001..005, IAM-003, PUB-008, ORD-001..005, DAT-007/010/011.  
**Diferidos:** CUS-006..010 e DAT-008/012 dependem de checkout, orders, snapshots e política de retenção nas Fases 06–07.

## T05.1 — Customer profile

- [x] **RED:** customer cria/lê/atualiza próprio profile.
- [x] **RED:** outro user não acessa profile.
- [x] **GREEN:** service/policy/API.

## T05.2 — Addresses

- [x] Migrations/constraints para address estruturado e default único por customer.
- [x] **RED:** create/list/update/select-default/delete próprio.
- [x] **RED:** outro customer recebe forbidden/not found sem disclosure.
- [x] **RED:** default remains deterministic ao excluir.
- [x] **DIFERIDO F06:** address usado em order não destrói histórico; validar snapshots quando `orders` existir.
- [x] **GREEN:** address service/API.

## T05.3 — Favorites

- [x] **RED:** add/list/remove seller favorite do customer.
- [x] **RED:** duplicate é idempotente ou conflict estável conforme contrato.
- [x] **RED:** seller inexistente/não elegível tratado.
- [x] **GREEN:** model/service/API.

## T05.4 — Customer carts

- [x] Migrations para `carts`/`cart_items`; unique active cart por customer/seller.
- [x] **RED:** add/update/remove/list com ownership.
- [x] **RED:** seller/product/activity/quantity são autoritativos.
- [x] **RED:** response mostra subtotal/fee/total preview do servidor.
- [x] **GREEN:** customer cart service/API.

## T05.5 — Guest-to-customer handoff

- [x] **RED:** mesmo seller faz merge bounded sem duplicação incorreta.
- [x] **RED:** seller diferente exige confirmação e não perde cart silenciosamente.
- [x] **RED:** retry do handoff é idempotente.
- [x] **GREEN:** handoff service/endpoint.

## Gate Fase 05

- [x] Customer possui profile/address/favorite/cart isolados.
- [x] Guest handoff testado.
- [x] OpenAPI, matriz e quality gate atualizados.

---

# Fase 06 — Atomic checkout, payment, inventory e outbox

**Prioridade:** P0  
**Dependências:** Fase 05  
**Requisitos:** ORD-006..015, ORD-022, PAY-001..010, DAT-006..009, INT-001/005..010, TST-009.

## T06.1 — Order/payment/outbox schema

- [x] Migrations para orders, order_items, order_status_histories, payments, idempotency_records, inventory_movements e outbox_events.
- [x] Order address/fee/courier fee/total snapshots.
- [x] Unique payment per order.
- [x] Unique idempotency key por principal/operation.
- [x] Unique inventory movement por order/product/kind.
- [x] Append-only protections para history.
- [x] **RED:** persistence/constraint tests.
- [x] **GREEN:** migrations/models.

## T06.2 — Money/totals domain

- [x] **RED:** subtotal, delivery fee, discount zero default, courier fee e total.
- [x] **RED:** overflow/negative/currency mismatch falham.
- [x] **GREEN:** immutable Money/OrderTotals domain objects.

## T06.3 — Payment gateway contract

- [x] **RED:** contract tests provider-neutral.
- [x] **RED:** simulated gateway cria pending payment com authoritative amount/currency.
- [x] **RED:** provider failure deixa estado recuperável.
- [x] **GREEN:** `Payments::Gateway` + `SimulatedGateway`.
- [x] PAY-005/SEC-011 permanecem conditional while no external callback exists.

## T06.4 — Idempotency service

- [x] **RED:** mesma key + mesmo payload retorna resultado original.
- [x] **RED:** mesma key + payload diferente retorna `idempotency_conflict`.
- [x] **RED:** requests concorrentes com mesma key criam um order.
- [x] **GREEN:** digest/claim/complete/failure semantics.

## T06.5 — CheckoutService

- [x] **RED:** exige authenticated customer e address próprio.
- [x] **RED:** valida seller approved, product owner/activity, quantity e inventory.
- [x] **RED:** ignora/rejeita client price/fee/total.
- [x] **RED:** cria atomicamente order/items/history/payment/outbox/inventory movement.
- [x] **RED:** cart limpa somente após commit bem-sucedido.
- [x] **RED:** falha deixa cart recuperável e sem registros parciais.
- [x] **GREEN:** menor implementação transacional.
- [x] **REFACTOR:** checkout não depende de controller/provider concrete object.

## T06.6 — Conditional inventory decrement

- [x] **RED:** duas conexões compram última unidade; exatamente uma vence.
- [x] **RED:** perdedor recebe `insufficient_inventory`.
- [x] **RED:** inventory nunca negativo e loser não deixa order/payment/event.
- [x] **GREEN:** conditional SQL update dentro da transação.
- [x] Documentar setup especial de teste concorrente SQLite.

## T06.7 — Checkout API

- [x] **RED:** success 201 + snapshots/envelope.
- [x] **RED:** missing Idempotency-Key.
- [x] **RED:** invalid input/ownership/inventory/conflicts/internal failure.
- [x] **GREEN:** endpoint fino.
- [x] Atualizar OpenAPI.

## Gate Fase 06

- [x] Cenários B e C da spec passam.
- [x] Payment e order permanecem estados separados.
- [x] Atomicidade e concorrência comprovadas.
- [x] Quality gate/matriz/OpenAPI atualizados.

---

# Fase 07 — Seller order workflow, payment confirmation e cancellation

**Prioridade:** P0  
**Dependências:** Fase 06  
**Requisitos:** SEL-009..012, ORD-016..018, ORD-020..022, PAY-006/008.

## T07.1 — Order state machine

- [x] **RED:** cada transição canônica válida.
- [x] **RED:** matriz completa de transições inválidas.
- [x] **RED:** terminais não transitam.
- [x] **GREEN:** `OrderStateMachine` em `app/domain/`.

## T07.2 — OrderTransitionService

- [x] **RED:** transition + history + outbox são atômicos.
- [x] **RED:** history registra from/to/actor/time/reason/request ID.
- [x] **RED:** seller ownership conferido na operação autoritativa.
- [x] **RED:** accept exige Payment paid.
- [x] **GREEN:** service explícito.

## T07.3 — Simulated payment confirmation

- [x] **RED:** admin marca pending payment paid.
- [x] **RED:** repetir mark-paid é idempotente.
- [x] **RED:** failed/cancelled/rejected payment/order retorna conflict.
- [x] **RED:** amount/currency não vêm do request.
- [x] **RED:** payment transition cria audit/outbox.
- [x] **GREEN:** payment service; rota admin pode ser registrada agora.

## T07.4 — Seller order API

- [x] **RED:** seller lista/detalha apenas próprios orders com history.
- [x] **RED:** accept/reject/preparing/ready success.
- [x] **RED:** outro seller não inspeciona/transita.
- [x] **RED:** invalid transition retorna taxonomy estável.
- [x] **GREEN:** endpoints definidos no prompt.

## T07.5 — Reject/cancel e inventory restore

- [x] **RED:** seller reject pending restaura inventory exatamente uma vez.
- [x] **RED:** customer cancela somente pending + payment pending e reason obrigatório.
- [x] **RED:** admin cancel policy para accepted/assigned pending payment.
- [x] **RED:** paid order não cancela sem refund capability.
- [x] **RED:** payment pending vira failed com reason code.
- [x] **RED:** retry não duplica InventoryMovement.
- [x] **GREEN:** cancellation/rejection services.

## T07.6 — Pending payment expiration

- [x] **RED:** pending order/payment com 30+ minutos expira.
- [x] **RED:** paid/non-expired não expira.
- [x] **RED:** expiration restaura inventory e grava history/outbox uma vez.
- [x] **GREEN:** idempotent Solid Queue job + recurring config.

## Gate Fase 07

- [x] Cenário D passa.
- [x] Seller workflow completo e auditable.
- [x] Cancellation/expiration idempotentes.
- [x] Quality gate/matriz/OpenAPI atualizados.

---

# Fase 08 — Courier onboarding, queue e atomic assignment

**Prioridade:** P0  
**Dependências:** Fase 07  
**Requisitos:** COU-001..009, COU-011..012, ORD-019..020, ADM-004.

## T08.1 — Courier schema/profile

- [x] Completar migration/model de courier com approval e operational fields separados, consent, vehicle/contact data.
- [x] **RED:** onboarding/profile own access.
- [x] **RED:** estados independentes e constraints.
- [x] **GREEN:** courier service/API.

## T08.2 — Courier moderation

- [x] **RED:** admin approve/reject/suspend/reinstate conforme state machine.
- [x] **RED:** audit obrigatório.
- [x] **GREEN:** moderation service/routes.

## T08.3 — Availability

- [x] **RED:** somente approved courier fica available.
- [x] **RED:** courier com active delivery não fica unavailable.
- [x] **RED:** suspended/rejected permanece offline.
- [x] **GREEN:** availability service/API.

## T08.4 — Eligible/active/completed queue

- [x] **RED:** approved+available vê ready unassigned orders.
- [x] **RED:** active mostra somente assignment próprio.
- [x] **RED:** completed mostra histórico próprio paginado.
- [x] **GREEN:** query service/endpoint com filtros allow-listed.

## T08.5 — Atomic courier assignment

- [x] **RED:** duas conexões/couriers aceitam o mesmo ready order; exatamente um vence.
- [x] **RED:** loser recebe conflict sem history/event duplicado.
- [x] **RED:** winner vira on_delivery e order assigned atomicamente.
- [x] **RED:** Idempotency-Key retry retorna mesmo result.
- [x] **GREEN:** conditional update + transactional assignment service.

## T08.6 — Pickup/delivery transitions

- [x] **RED:** assigned courier marca picked_up/delivered.
- [x] **RED:** outro courier não muta assignment.
- [x] **RED:** delivery conclui courier operational state corretamente.
- [x] **GREEN:** transition service/API.

## T08.7 — Courier stats

- [x] **RED:** completed deliveries count.
- [x] **RED:** earnings = courier_fee_cents snapshots delivered only.
- [x] **GREEN:** stats query/API.

## Gate Fase 08

- [x] Cenário E passa sob concorrência real de conexões.
- [x] Queue/active/completed separados no contrato.
- [x] Quality gate/matriz/OpenAPI atualizados.

---

# Fase 09 — Courier location e customer tracking

**Prioridade:** P0  
**Dependências:** Fase 08  
**Requisitos:** COU-010, CUS-011, SEC-007/010/015, TST-008.

## T09.1 — Location schema/privacy

- [x] Migration com coordinates, accuracy opcional, recorded_at, courier e retention indexes.
- [x] **RED:** location somente com consent registrado.
- [x] **RED:** somente durante assigned/picked_up.
- [x] **RED:** exact location não aparece em logs.
- [x] **GREEN:** location service/model.

## T09.2 — Location ingest rate limit

- [x] **RED:** updates com intervalo menor que 5s são rate-limited.
- [x] **RED:** valid update persiste server timestamp/validated precision.
- [x] **GREEN:** shared-cache limiter + endpoint.

## T09.3 — Customer tracking

- [x] **RED:** owner vê state, ordered history, latest permitted location, recorded_at e freshness_seconds.
- [x] **RED:** outro customer/admin policy não autorizado conforme contrato.
- [x] **RED:** location indisponível retorna tracking sem location, não erro enganoso.
- [x] **GREEN:** tracking query/API.

## T09.4 — Location cleanup

- [x] **RED:** locations >24h são removidas; recentes permanecem.
- [x] **RED:** job retry idempotente.
- [x] **GREEN:** recurring cleanup job.

## Gate Fase 09

- [x] Cenário F passa.
- [x] Privacy/log redaction verificada.
- [x] Quality gate/matriz/OpenAPI atualizados.

---

# Fase 10 — Support tickets e messages

**Prioridade:** P0  
**Dependências:** Fase 05 e Fase 07  
**Requisitos:** SUP-001..007, DAT-006/007, IAM-003/006, ADM-006.

## T10.1 — Support schema/state machine

- [x] Migrations tickets/messages com optional order FK, sender, timestamps e state.
- [x] Append-only message protection.
- [x] **RED:** state transitions válidas/inválidas.
- [x] **GREEN:** TicketState domain.

## T10.2 — Ticket creation transaction

- [x] **RED:** ticket + initial message persistem atomicamente.
- [x] **RED:** optional order precisa pertencer ao customer.
- [x] **RED:** falha na mensagem não deixa ticket parcial.
- [x] **GREEN:** TicketService.

## T10.3 — Customer support API

- [x] **RED:** create/list/detail próprios.
- [x] **RED:** outro customer não acessa.
- [x] **RED:** customer adiciona message em ticket não fechado próprio.
- [x] **GREEN:** customer endpoints.

## T10.4 — Admin support API

- [x] **RED:** admin list/detail/messages.
- [x] **RED:** admin reply + in-progress/resolve/reopen/close.
- [x] **RED:** transition auditada.
- [x] **GREEN:** admin endpoints.

## Gate Fase 10

- [x] Cenário G passa.
- [x] Messages append-only e ownership testados.
- [x] Quality gate/matriz/OpenAPI atualizados.

---

# Fase 11 — Admin operations, settings, invoices, audit e observability

**Prioridade:** P0/P1  
**Dependências:** Fases 02–10  
**Requisitos:** ADM-001..011, PAY-008, DAT-006/008, NFR-017..022, SEC-012.

## T11.1 — AuditLog hardening

- [x] Garantir campos actor/action/resource/result/reason/metadata/time/request_id.
- [x] **RED:** sensitive commands sem audit falham/rollback quando aplicável.
- [x] **RED:** update/delete de audit é proibido.
- [x] **GREEN:** AuditService + protections.


## T11.2 — User administration

- [x] **RED:** admin list/detail users + actor relationships.
- [x] **RED:** disable revoga/rejeita sessões imediatamente.
- [x] **RED:** enable restaura autenticação futura sem reativar sessão antiga.
- [x] **RED:** non-admin forbidden.
- [x] **GREEN:** admin user API.


## T11.3 — Admin orders/payments

- [x] **RED:** list/detail orders com history/payment.
- [x] **RED:** admin cancellation policy.
- [x] **RED:** payment list/detail/mark-paid.
- [x] **GREEN:** endpoints e policies.


## T11.4 — Settings e effective-dated fees

- [x] Migrations/model para settings history/effective dates.
- [x] **RED:** admin read/update with reason/audit.
- [x] **RED:** mudança não altera order snapshot.
- [x] **GREEN:** settings service/API.


## T11.5 — Invoices

- [x] Migration com seller, period, amount/currency, state, timestamps.
- [x] **RED:** generation by period uses historical fee/order data.
- [x] **RED:** rerun é idempotente.
- [x] **RED:** states pending/paid/cancelled e immutable historical values.
- [x] **GREEN:** invoice service/list/detail/generate API.


## T11.6 — Operational dashboard

- [x] **RED:** indicadores de users, sellers, couriers, orders, payments, tickets e failures.
- [x] **RED:** queries paginadas/determinísticas.
- [x] **GREEN:** dashboard query/API.


## T11.7 — Observability endpoints

- [x] Instrumentar request rate/latency/status/error.
- [x] Instrumentar DB contention/dependency health, queue depth/age/retry.
- [x] Instrumentar product signals pedidos pela seção 20.
- [x] **RED:** admin-only endpoints summary/requests/orders/jobs.
- [x] **RED:** nenhum secret/PII/location exata.
- [x] **GREEN:** in-process/DB-backed summaries.
- [x] Observability não participa da correção transacional central.


## Gate Fase 11

- [x] Cenário H passa para todos os atores.
- [x] Admin opera todos os domínios sem privilege leak.
- [x] Audit e settings history verificados.
- [x] Quality gate/matriz/OpenAPI atualizados.


---

# Fase 12 — Uploads, outbox e provider hardening

**Prioridade:** P0/P1  
**Dependências:** Fases 03, 06 e 11  
**Requisitos:** SEL-013, SEC-009, INT-001..010, NFR-006/008/009.

## T12.1 — Active Storage backend

- [x] Instalar migrations Active Storage conforme Rails.
- [x] Configurar produção em caminho persistente sob `storage/uploads` ou ENV equivalente.
- [x] **RED:** size limit, allow-listed content types e content validation.
- [x] **RED:** server-generated storage key/name e path traversal bloqueado.
- [x] **RED:** conteúdo executável não é servido inline de modo inseguro.
- [x] **GREEN:** upload service/attachment policy.

## T12.2 — Outbox dispatcher durável

- [x] **RED:** business commit deixa pending outbox mesmo se enqueue imediato não ocorrer.
- [x] **RED:** dispatcher recupera pending após restart.
- [x] **RED:** handler é idempotente.
- [x] **RED:** unknown event não vira success.
- [x] **GREEN:** polling dispatcher Solid Queue.

## T12.3 — Retry, leasing e poison work

- [x] **RED:** attempts/last_error/available_at atualizados.
- [x] **RED:** leased work abandonado é recuperável.
- [x] **RED:** bounded retry/backoff leva a terminal poison state visível.
- [x] **GREEN:** processing lifecycle.

## T12.4 — Provider contracts

- [x] Consolidar contracts de payment, storage, identity e notifications intents.
- [x] **RED:** provider objects/errors não vazam para domain/API.
- [x] **RED:** explicit timeouts e bounded retries para qualquer network adapter futuro/presente.
- [x] **GREEN:** adapter boundaries/documentation.

## Gate Fase 12

- [x] Upload security tests passam.
- [x] Outbox recovery/poison tests passam.
- [x] Quality gate/matriz/OpenAPI atualizados.

---

# Fase 13 — Privacy, recovery, performance, smoke e release gate

**Prioridade:** P0/P1  
**Dependências:** Fases 00–12  
**Requisitos:** DAT-012, SEC-001..015, NFR-001..022, TST-007..012.

## T13.1 — Privacy backend

**Arquivo:** `docs/PRIVACY_BACKEND.md`

- [x] Documentar finalidade/classificação/acesso/retention de identity, contact, address, order, support, payment e location.
- [x] Documentar LGPD assumptions, backup implications e decisões jurídicas bloqueantes.
- [x] **RED:** export service retorna dados do principal sem dados alheios.
- [x] **RED:** anonymize preserva order/payment/audit/history legalmente necessários.
- [x] **GREEN:** `Privacy::ExportService` e `Privacy::AnonymizeService`.

## T13.2 — Operations documentation

**Arquivo:** `docs/OPERATIONS.md`

- [x] Documentar boot/config/migration/deploy/forward-fix/rollback.
- [x] Documentar secret rotation e incident response.
- [x] Documentar graceful SIGTERM de Puma + Solid Queue.
- [x] Documentar SQLite/upload backup, schedule, retention e monitoring.
- [x] Registrar targets provisórios RPO 24h/RTO 4h.

## T13.3 — Backup/restore

- [x] **RED:** backup task falha claramente sem configuração/destino válido.
- [x] **RED:** backup consistente inclui primary DB e uploads necessários.
- [x] **RED:** restore em ambiente isolado recupera schema/data representativos.
- [x] **GREEN:** tasks de backup/restore/check.
- [x] Testar restore após material schema/storage change.
- [x] Registrar duração e integridade.

## T13.4 — Graceful shutdown/recovery

- [x] Criar teste/script que envia SIGTERM sob request/job em andamento.
- [x] Verificar stop de novos requests, drain bounded, worker stop e DB release.
- [x] Verificar pending outbox retomado após restart.

## T13.5 — API E2E

- [x] **RED:** criar teste HTTP completo dos cenários A–H antes de fechar gaps.
- [x] **GREEN:** corrigir somente gaps observados.
- [x] Cobrir public → seller → customer → payment → seller → courier → tracking → support → admin.
- [x] Cobrir cross-role denial e disabled user.

## T13.6 — Smoke backend

**Arquivo:** `script/smoke_backend.sh`

- [x] Implementar precondições controladas: DB limpa, boot e bootstrap admin.
- [x] Executar todo fluxo de negócio posterior apenas via HTTP.
- [x] Validar cada status/envelope/ID antes de avançar.
- [x] Reexecutar idempotency-sensitive steps e confirmar ausência de duplicação.
- [x] Parar no primeiro erro.
- [x] Linha final exata: `JaChegai Rails backend smoke test passed`.

## T13.7 — Security threat scenarios

- [x] Customer acessa address/order/ticket de outro customer → bloqueado.
- [x] Seller muta catalog/order de outro seller → bloqueado.
- [x] Courier transita delivery alheio → bloqueado.
- [x] Public registration tenta admin → bloqueado.
- [x] Replayed checkout → sem duplicação.
- [x] Concurrent courier accept → um winner.
- [x] Manipulated client price → ignorado/rejeitado.
- [x] Crafted upload/path traversal/executable → bloqueado.
- [x] Revoked/disabled session → bloqueada.
- [x] CSRF/origin attack → bloqueado.
- [x] Logs não capturam credentials/PII/location.
- [x] External callback scenario marcado conditional, não falsamente testado.

## T13.8 — Load/performance smoke

- [x] Criar carga repetível para reads, checkout contention e courier assignment.
- [x] Registrar ambiente/hardware/dataset/concurrency.
- [x] Verificar provisoriamente p95 reads <500 ms e p95 checkout <1 s local.
- [x] Verificar inventory e assignment invariants durante carga.
- [x] Se target falhar, registrar blocker; não maquiar medição.

## T13.9 — Finalizar OpenAPI e compatibility policy

- [x] Todos os routes do Rails aparecem no OpenAPI.
- [x] Todos os OpenAPI paths têm request/contract test.
- [x] Documentar versioning `/api/v1` e breaking-change policy.
- [x] Validar schemas/envelopes/status codes contra execução.

## T13.10 — Production-like image

- [x] Build da imagem Rails existente passa.
- [x] Um único deployable unit; sem frontend product adicional ou serviços novos.
- [x] Volume persistente cobre SQLite/Active Storage necessários.
- [x] Rodar migrations, health/readiness e smoke em production-like.
- [x] Verificar secret/config failure explícita.

## T13.11 — CI quality gate

- [x] Atualizar `.github/workflows/ci.yml` para bloquear em:
  - tests unit/request/integration/jobs;
  - concurrency/recovery/API E2E;
  - RuboCop;
  - Brakeman;
  - Bundler Audit;
  - Importmap audit enquanto importmap fizer parte do repo;
  - OpenAPI/matrix validation.
- [x] Não permitir bypass documentado do gate.

## T13.12 — Fechar requirements matrix

- [x] Reexecutar validador dos 197 IDs.
- [x] Marcar `verified` apenas com evidence real.
- [x] Manter frontend/visual em `deferred_frontend`.
- [x] Manter callbacks externos em `conditional_not_applicable` enquanto não implementados.
- [x] Nenhum mandatory backend requirement pode ficar `planned`/`implemented` sem evidence.
- [x] Registrar blockers e deviations aprovados.

---

# Quality Gate Final — Backend MVP

Execute em DB de teste recriada:

```bash
RAILS_ENV=test bin/rails db:drop db:create db:migrate
bin/rails test
bin/rubocop
bin/brakeman --no-pager
bin/bundler-audit
bin/importmap audit
bin/rails runner 'abort unless Rails.application.class.module_parent.name == "JachegaiRails"'
```

Depois:

```bash
bin/rails server
curl -fsS http://localhost:3000/healthz
curl -fsS http://localhost:3000/readyz
bash script/smoke_backend.sh
```

## Definition of Done final

- [x] Arquitetura Rails e worksheet completas.
- [x] Matriz contém 197/197 IDs e evidência honesta.
- [x] Backend requirements em escopo estão `verified`.
- [x] Frontend requirements permanecem `deferred_frontend`.
- [x] OpenAPI corresponde aos routes/request tests.
- [x] Auth/session/revocation/roles/object authorization passam.
- [x] Seller, catalog e inventory funcionam.
- [x] Guest/customer carts e handoff funcionam.
- [x] Checkout é atômico, idempotente e não oversella.
- [x] Payment simulado e expiration/cancellation são consistentes.
- [x] Seller order workflow passa.
- [x] Courier assignment tem exatamente um winner sob concorrência.
- [x] Tracking respeita ownership/privacy/retention.
- [x] Support/admin/settings/invoices/audit/observability funcionam.
- [x] Upload e outbox security/recovery passam.
- [x] Backup/restore e graceful shutdown demonstrados.
- [x] API E2E e smoke passam.
- [x] Performance targets provisórios medidos e atendidos ou bloqueio registrado.
- [x] Production-like image/volume/health/smoke passam.
- [x] CI quality gate bloqueia falhas.
- [x] Todo comportamento implementado tem registro RED → GREEN → REFACTOR → REGRESSION.
- [x] Não há alegação de MVP completo do produto sem frontend.

---


# Fase 14 — Frontend MVP (Design Brutalista)

**Fonte:** `.prompts/frontend-mvp.md`
**Dependências:** Backend API concluída (89 endpoints, JWT Bearer, envelope `{ok, data, meta}`).
**Stack:** React 19 + Vite + TypeScript + TailwindCSS 4 + React Router 7.
**Restrições:**
- ⛔ Não alterar controllers, models ou rotas Rails existentes.
- ⛔ Não usar Material UI, Bootstrap, Chakra ou qualquer kit UI pré-estilizado.
- ⛔ Não armazenar tokens em cookies — usar `localStorage` com limpeza em logout/expiração.
- ⛔ Lógica de negócio fica no backend — frontend é camada de visualização + formulários.

**Design System — Brutalismo:**
- Paleta: branco (`#FFFFFF`), vermelho claro (`#FF6B6B`), preto (`#000000`), cinza claro (`#F5F5F5`) para fundos.
- Bordas: `border-4 border-black` em cards, inputs, botões e modais.
- Cantos: `rounded-3xl` (24px) — arredondamento grande em tudo.
- Sombras: `shadow-[8px_8px_0px_0px_rgba(0,0,0,1)]` — hard shadow preta.
- Tipografia: títulos em `font-black italic` (ex: `text-4xl font-black italic`).
- Botões: fundo preto + texto branco (primário), fundo vermelho claro + texto preto (ação), fundo branco + borda preta (secundário). Hover inverte ou desloca sombra.
- Inputs: `border-4 border-black rounded-3xl px-6 py-3 text-lg focus:shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]`.

---

## T14.1 — Scaffold Vite + Tailwind + proxy

- [x] `npm create vite@latest frontend -- --template react-ts` na raiz do projeto.
- [x] `cd frontend && npm install react-router-dom axios`.
- [x] `npm install -D tailwindcss @tailwindcss/vite` (Tailwind 4 plugin Vite).
- [x] Configurar `vite.config.ts`:
  - Plugin `@tailwindcss/vite`.
  - `server.proxy`: `"/api/v1"` → `http://localhost:3000`, `/healthz` → idem, `/readyz` → idem.
  - `server.port`: 5173.
- [x] Criar `frontend/src/index.css` com `@import "tailwindcss"` + `@theme` contendo:
  - `--color-brutal-red: #FF6B6B`, `--color-brutal-black: #000000`, `--color-brutal-white: #FFFFFF`, `--color-brutal-gray: #F5F5F5`.
  - `--radius-brutal: 1.5rem`, `--shadow-brutal: 8px 8px 0px 0px rgba(0,0,0,1)`.
- [x] Limpar arquivos gerados pelo scaffold (App.css, assets/react.svg, conteúdo padrão do App.tsx).
- [x] Verificar: `npm run build` compila sem erros.
- [x] Verificar: `curl http://localhost:5173/api/v1/auth/me` retorna `401` (proxy funciona para o Rails).
- [x] Verificar: `curl http://localhost:5173/healthz` retorna `200`.
- [x] Adicionar `frontend/node_modules/` e `frontend/dist/` ao `.gitignore`.

---

## T14.2 — Design system: componentes base brutalistas

Todos os componentes em `frontend/src/components/ui/`.

- [x] `Button.tsx` — variantes: `primary` (bg-black text-white), `danger` (bg-brutal-red text-black), `outline` (bg-white border-black). Props: `variant`, `size`, `loading`, `disabled`, `children`, `onClick`, `type`. Todos com `border-4 border-black rounded-3xl shadow-brutal`. Estado hover: desloca sombra para `4px 4px`. Estado disabled: `opacity-50 cursor-not-allowed`.
- [x] `Input.tsx` — Props: `label`, `name`, `type`, `error`, `placeholder`, `value`, `onChange`, `required`. Label em `font-bold text-sm uppercase tracking-wider`. Input com `border-4 border-black rounded-3xl`. Erro: `border-brutal-red` + mensagem vermelha abaixo.
- [x] `Select.tsx` — Mesmo padrão visual do Input. Props: `label`, `options`, `value`, `onChange`, `error`.
- [x] `Card.tsx` — Container com `border-4 border-black rounded-3xl shadow-brutal bg-white p-6`. Props: `children`, `className`.
- [x] `Modal.tsx` — Overlay `bg-black/50`, conteúdo centralizado com Card brutalista. Props: `open`, `onClose`, `title`, `children`. Título em `font-black italic text-2xl`. Botão X no canto superior.
- [x] `Badge.tsx` — Para status labels. Variantes por status: `pending` (amarelo), `approved/paid` (verde), `rejected/cancelled` (vermelho), `active` (azul). Todos com `border-2 border-black rounded-full px-3 py-1 text-xs font-bold uppercase`.
- [x] `Table.tsx` — Tabela com `border-4 border-black rounded-3xl overflow-hidden`. Headers em `bg-black text-white font-bold uppercase`. Linhas alternadas `bg-white / bg-brutal-gray`. Props: `columns`, `data`, `onRowClick`.
- [x] `EmptyState.tsx` — Ícone grande + título italic bold + descrição + botão de ação opcional. Para listas vazias.
- [x] `LoadingSpinner.tsx` — Spinner brutalista (quadrado rotacionando com `border-4 border-black`).
- [x] `ErrorState.tsx` — Card vermelho com ícone + mensagem + botão "Tentar novamente".
- [x] `PageTitle.tsx` — `<h1 className="text-4xl font-black italic text-black">`. Subtítulo opcional em `text-lg text-gray-600`.
- [x] `ConfirmDialog.tsx` — Modal com mensagem + botões "Confirmar" (danger) e "Cancelar" (outline). Para ações destrutivas (UX-004).
- [x] Verificar: `npm run build` compila sem erros (TS strict).
- [x] Validação visual: screenshot da página raiz com o tema brutalista (`.todo/screenshots/t14-2-home.png`) + DOM check.

---

## T14.3 — Layout, Header, Footer, navegação e rotas

- [x] `Footer.tsx` — em `frontend/src/components/layout/`:
  - Fundo preto, texto branco.
  - 4 colunas: **JaChegai** (logo + tagline), **Para você** (links: Descubra sellers, Seja courier, Seja parceiro), **Suporte** (FAQ, Termos, Privacidade, Contato), **Siga-nos** (ícones placeholder).
  - Copyright `© 2026 JaChegai. Todos os direitos reservados.` centralizado embaixo.
  - Border-top: `border-t-4 border-brutal-red`.
  - Presente em **todas** as páginas sem exceção.
- [x] `Header.tsx` — componente condicional por role:
  - **Visitante**: logo + links "Entrar" / "Cadastrar".
  - **Customer**: logo + "Meu carrinho" + "Meus pedidos" + "Perfil" + "Sair".
  - **Seller**: logo + "Produtos" + "Pedidos" + "Estoque" + "Perfil" + "Sair".
  - **Courier**: logo + "Entregas" + "Disponibilidade" + "Estatísticas" + "Perfil" + "Sair".
  - **Admin**: logo + "Dashboard" + "Usuários" + "Sellers" + "Couriers" + "Pedidos" + "Pagamentos" + "Tickets" + "Faturas" + "Config" + "Sair".
  - Fundo branco, `border-b-4 border-black`, logo em `font-black italic text-2xl`.
  - Mobile: menu hamburger que abre sidebar com mesmos links.
- [x] `PublicLayout.tsx` — Header visitante + `<Outlet />` + Footer.
- [x] `CustomerLayout.tsx` — Header customer + `<Outlet />` + Footer. Redireciona para `/login` se não autenticado.
- [x] `SellerLayout.tsx` — Header seller + `<Outlet />` + Footer. Redireciona para `/login` se não autenticado ou sem role seller.
- [x] `CourierLayout.tsx` — Header courier + `<Outlet />` + Footer. Idem.
- [x] `AdminLayout.tsx` — Header admin + sidebar fixa (links de navegação) + `<Outlet />` + Footer. Sidebar com `bg-black text-white` e links com hover `bg-brutal-red`.
- [x] `ProtectedRoute.tsx` — wrapper que checa AuthContext: se não autenticado → `/login`; se autenticado mas sem a role necessária → página 403 brutalista.
- [x] Configurar React Router em `App.tsx` com:
  ```
  /                           → PublicLayout > HomePage
  /sellers                    → PublicLayout > SellersPage
  /sellers/:id                → PublicLayout > SellerDetailPage
  /products/:id               → PublicLayout > ProductDetailPage
  /login                      → PublicLayout > LoginPage
  /register                   → PublicLayout > RegisterPage
  /customer/*                 → CustomerLayout (protected: customer)
    /customer/cart             → CartPage
    /customer/checkout         → CheckoutPage
    /customer/orders           → OrdersPage
    /customer/orders/:id       → OrderDetailPage
    /customer/tracking/:id     → TrackingPage
    /customer/addresses        → AddressesPage
    /customer/favorites        → FavoritesPage
    /customer/tickets          → TicketsPage
    /customer/tickets/:id      → TicketDetailPage
    /customer/profile          → ProfilePage
  /seller/*                   → SellerLayout (protected: seller)
    /seller/onboarding         → OnboardingPage
    /seller/products           → ProductsPage
    /seller/products/:id       → ProductEditPage
    /seller/categories         → CategoriesPage
    /seller/inventory          → InventoryPage
    /seller/orders             → OrdersPage
    /seller/orders/:id         → OrderDetailPage
    /seller/settings           → SettingsPage
    /seller/profile            → ProfilePage
  /courier/*                  → CourierLayout (protected: courier)
    /courier/onboarding        → OnboardingPage
    /courier/deliveries        → DeliveriesPage (eligible + active)
    /courier/history           → HistoryPage
    /courier/availability      → AvailabilityPage
    /courier/stats             → StatsPage
    /courier/profile           → ProfilePage
  /admin/*                    → AdminLayout (protected: admin)
    /admin/dashboard           → DashboardPage
    /admin/users               → UsersPage
    /admin/users/:id           → UserDetailPage
    /admin/sellers             → SellersPage
    /admin/sellers/:id         → SellerDetailPage
    /admin/couriers            → CouriersPage
    /admin/couriers/:id        → CourierDetailPage
    /admin/orders              → OrdersPage
    /admin/orders/:id          → OrderDetailPage
    /admin/payments            → PaymentsPage
    /admin/payments/:id        → PaymentDetailPage
    /admin/tickets             → TicketsPage
    /admin/tickets/:id         → TicketDetailPage
    /admin/invoices            → InvoicesPage
    /admin/invoices/:id        → InvoiceDetailPage
    /admin/settings            → SettingsPage
    /admin/observability       → ObservabilityPage
  *                            → NotFoundPage (404 brutalista)
  ```

---

## T14.4 — Serviço de API e AuthContext

- [x] `frontend/src/services/api.ts`:
  - Instância Axios com `baseURL: ""` (proxy resolve).
  - Request interceptor: se `localStorage.getItem("token")` existe, adiciona `Authorization: Bearer <token>`.
  - Response interceptor: se status `401`, limpa `localStorage` (`token`, `user`), redireciona para `/login` com query `?expired=true`.
  - Helper `unwrap(response)`: extrai `response.data.data` do envelope `{ok, data, meta}`.
  - Helper `unwrapError(error)`: extrai `error.response.data` para código/mensagem de erro.
- [x] `frontend/src/services/auth.ts` — funções tipadas:
  - `register(name, email, password)` → `POST /api/v1/auth/register` → retorna `{token, user}`.
  - `login(email, password)` → `POST /api/v1/auth/login` → retorna `{token, user}`.
  - `logout()` → `POST /api/v1/auth/logout` → limpa localStorage.
  - `getMe()` → `GET /api/v1/auth/me` → retorna user com roles.
- [x] `frontend/src/contexts/AuthContext.tsx`:
  - State: `user` (com `id`, `email`, `name`, `roles[]`), `token`, `loading`, `isAuthenticated`.
  - `login(email, password)`: chama auth.login, salva token + user no localStorage, seta state.
  - `register(name, email, password)`: chama auth.register, salva, seta state.
  - `logout()`: chama auth.logout, limpa localStorage, seta state null.
  - `hasRole(role: string): boolean` — verifica se o user tem a role (customer, seller, courier, admin).
  - No mount: se token existe no localStorage, chama `getMe()` para validar; se 401, limpa.
- [x] Tipos TypeScript em `frontend/src/types/`:
  - `api.ts`: `ApiResponse<T>`, `ApiError`, `PaginationMeta`.
  - `auth.ts`: `User`, `LoginRequest`, `RegisterRequest`, `AuthState`.
  - `models.ts`: `Seller`, `Product`, `Category`, `Cart`, `CartItem`, `Order`, `OrderItem`, `Address`, `Favorite`, `Ticket`, `TicketMessage`, `Courier`, `Invoice`, `Payment`, `MarketplaceSetting`.

---

## T14.5 — Autenticação: Login, Registro, Logout

- [x] `LoginPage.tsx`:
  - Centralizada vertical/horizontal.
  - Card brutalista com título `"Entrar"` em `font-black italic text-3xl`.
  - Campos: email (type email), senha (type password). Ambos com Input brutalista.
  - Botão "Entrar" (primary). Botão "Criar conta" (outline, navega para `/register`).
  - Se `?expired=true` na URL: toast/banner vermelho "Sua sessão expirou. Faça login novamente."
  - Erro 401: mensagem "Email ou senha incorretos" sob o formulário (UX-003: preserva email digitado).
  - Após login: redireciona para dashboard do primeiro role do user (`customer` → `/customer/orders`, `seller` → `/seller/orders`, `courier` → `/courier/deliveries`, `admin` → `/admin/dashboard`).
- [x] `RegisterPage.tsx`:
  - Card brutalista com título `"Criar conta"`.
  - Campos: nome completo, email, senha, confirmar senha.
  - Validação client-side: email format, senha mínimo 6 chars, senhas iguais.
  - Erro 422: destaca campos com `border-brutal-red` e mostra mensagem do backend por campo.
  - Após registro: login automático e redirecionamento para `/customer/orders`.
  - Link "Já tem conta? Entrar" → `/login`.
- [x] Botão de logout no Header: chama `AuthContext.logout()` → redireciona para `/`.

---

## T14.6 — Área pública: Home, Sellers, Produtos e Guest Cart

**Endpoints consumidos:** `GET /api/v1/public/sellers`, `GET /api/v1/public/sellers/{id}`, `GET /api/v1/public/sellers/{seller_id}/products`, `GET /api/v1/public/products/{id}`, `POST|PATCH|DELETE /api/v1/public/cart/items`, `GET|DELETE /api/v1/public/cart`.

- [x] `HomePage.tsx`:
  - Hero section: título grande em `font-black italic` ("Seu delivery. Já chegou."), subtítulo, botão CTA "Explorar sellers" → `/sellers`.
  - Seção "Como funciona" — 3 cards brutalistas: Escolha → Peça → Receba.
  - Seção "Sellers em destaque" — grid de cards de sellers (consumir `GET /api/v1/public/sellers?limit=6`).
  - Seção "Seja parceiro" / "Seja entregador" — CTAs para páginas estáticas futuras.
- [x] `SellersPage.tsx`:
  - Título `"Sellers"` em PageTitle brutalista.
  - Grid de SellerCards (nome, descrição, badge de status). Cada card clicável → `/sellers/:id`.
  - Paginação se houver `meta.page`/`meta.total_pages`. EmptyState se nenhum seller.
- [x] `SellerDetailPage.tsx`:
  - Header do seller: nome em `font-black italic`, descrição, badge moderation_state.
  - Lista de produtos desse seller (`GET /api/v1/public/sellers/{seller_id}/products`).
  - Cada produto: Card com nome, preço (formatado BRL: `R$ XX,XX`), badge disponibilidade.
  - Botão "Adicionar ao carrinho" em cada produto → chama `POST /api/v1/public/cart/items` com `{product_id, quantity: 1}`.
  - Se resposta 201: toast de sucesso. Se seller diferente do cart atual: exibir ConfirmDialog "Seu carrinho será substituído. Continuar?" (guest-cart replace policy).
- [x] `ProductDetailPage.tsx`:
  - Detalhes do produto: nome, descrição, preço formatado, estoque (quantidade disponível ou "Esgotado").
  - Botão "Adicionar ao carrinho" se em estoque.
  - Seletor de quantidade (`1..10` ou max estoque) com Input numérico.
- [x] `GuestCartWidget.tsx` (componente no Header público):
  - Ícone de carrinho com badge de quantidade de itens.
  - Click abre painel lateral (slide-over) com lista de itens do guest cart (`GET /api/v1/public/cart`).
  - Cada item: nome, qty, preço unitário, botão remover (`DELETE /api/v1/public/cart/items/{id}`).
  - Botão "Editar quantidade" → `PATCH /api/v1/public/cart/items/{id}` com `{quantity}`.
  - Botão "Fazer login para finalizar" → `/login` (após login, handoff do guest cart acontece via `POST /api/v1/customer/cart/handoff`).
  - EmptyState se carrinho vazio.
- [x] Formatação monetária: criar helper `formatMoney(cents: number, currency: string): string` → `R$ 12,50` para BRL.

---

## T14.7 — Customer: Perfil, Endereços e Favoritos

**Endpoints:** `GET|PATCH /api/v1/customer/profile`, `GET|POST /api/v1/customer/addresses`, `GET|PATCH|DELETE /api/v1/customer/addresses/{id}`, `POST /api/v1/customer/addresses/{id}/default`, `GET|POST /api/v1/customer/favorites`, `DELETE /api/v1/customer/favorites/{id}`.

- [x] `customer/ProfilePage.tsx`:
  - Card com dados do perfil: nome completo, email (readonly), data de criação.
  - Formulário de edição inline (nome completo). Botão "Salvar" (`PATCH /api/v1/customer/profile`).
- [x] `customer/AddressesPage.tsx`:
  - Lista de endereços em cards brutalistas. Badge "Padrão" no endereço default.
  - Cada card: rua, número, complemento, bairro, cidade, estado, CEP. Botões: "Editar" (abre Modal), "Excluir" (ConfirmDialog), "Tornar padrão" (`POST .../default`).
  - Botão "Novo endereço" → abre Modal com formulário (campos: street, number, complement, neighborhood, city, state, zip_code). `POST /api/v1/customer/addresses`.
  - Validação 422: destaca campos errados.
- [x] `customer/FavoritesPage.tsx`:
  - Grid de sellers favoritados (`GET /api/v1/customer/favorites`).
  - Cada card: nome do seller, botão "Remover" (`DELETE /api/v1/customer/favorites/{id}`).
  - Botão "Explorar sellers" → `/sellers` se lista vazia (EmptyState).

---

## T14.8 — Customer: Carrinho, Checkout e Handoff

**Endpoints:** `GET|DELETE /api/v1/customer/cart`, `POST /api/v1/customer/cart/items`, `PATCH|DELETE /api/v1/customer/cart/items/{id}`, `POST /api/v1/customer/cart/handoff`, `POST /api/v1/customer/checkout`.

- [x] `customer/CartPage.tsx`:
  - Handoff automático: ao montar, se guest cart existia (cookie/localStorage), chamar `POST /api/v1/customer/cart/handoff` silenciosamente. Exibir toast se houver merge.
  - Lista de itens do carrinho (`GET /api/v1/customer/cart`).
  - Cada item: nome produto, quantidade (editável via input numérico → `PATCH .../items/{id}`), preço unitário, subtotal. Botão "Remover" → `DELETE`.
  - Resumo: subtotal, taxa de entrega, total. Todos em `formatMoney()`.
  - Botão "Limpar carrinho" (ConfirmDialog → `DELETE /api/v1/customer/cart`).
  - Botão "Finalizar compra" → navega para `/customer/checkout`.
  - EmptyState se carrinho vazio: "Seu carrinho está vazio" + botão "Explorar sellers".
- [x] `customer/CheckoutPage.tsx`:
  - Resumo do carrinho (readonly): itens, quantidades, preços, total.
  - Seletor de endereço de entrega: dropdown com endereços do customer (`GET /api/v1/customer/addresses`). Endereço padrão pré-selecionado. Link "Adicionar endereço" → abre Modal.
  - Botão "Confirmar pedido" → `POST /api/v1/customer/checkout` com `{address_id}`.
  - Resposta 201: exibir Card de sucesso com order ID, navegar para `/customer/orders/{id}`.
  - Resposta 422 `insufficient_inventory`: mensagem "Estoque insuficiente para um ou mais itens". Manter carrinho recuperável.
  - Resposta 422 `idempotency_conflict`: mensagem "Este pedido já foi processado".
  - Resposta 422/500 `external_dependency_unavailable`: mensagem "Erro no processamento do pagamento. Tente novamente."

---

## T14.9 — Customer: Pedidos, Tracking e Tickets

**Endpoints:** `GET /api/v1/customer/orders/{id}/cancel` (POST), `GET /api/v1/customer/orders/{id}/tracking`, `GET|POST /api/v1/customer/tickets`, `GET /api/v1/customer/tickets/{id}`, `POST /api/v1/customer/tickets/{id}/messages`.

- [x] `customer/OrdersPage.tsx`:
  - Lista paginada de pedidos do customer. Buscar de onde? A API não tem `GET /api/v1/customer/orders` explícito — verificar se existe. Se não: página estática "Ver tracking de pedido por ID".
  - Cada card: order ID (truncado), status (Badge), data, total, seller. Click → `/customer/orders/:id`.
- [x] `customer/OrderDetailPage.tsx`:
  - Card com: status atual (Badge grande), data de criação, seller.
  - Lista de itens: nome, quantidade, preço unitário, subtotal.
  - Totais: subtotal, delivery_fee, discount, courier_fee, total.
  - Histórico de status: timeline vertical com estado + data + ator. Estado em `font-bold`, data em `text-sm text-gray-500`.
  - Se status é `pending`: botão "Cancelar pedido" (ConfirmDialog → `POST .../cancel`).
- [x] `customer/TrackingPage.tsx`:
  - Consome `GET /api/v1/customer/orders/{id}/tracking`.
  - Card com: estado atual do pedido, histórico de transições.
  - Se courier atribuído e localização disponível: exibir coordenadas (lat, lng) e timestamp de última atualização. Sem mapa (deferred) — exibir dados textuais: "Courier próximo — última posição: X, Y às HH:MM".
  - Mensagem de freshness: "Atualizado há X minutos" (UX: não implicar real-time se periódico).
- [x] `customer/TicketsPage.tsx`:
  - Lista de tickets do customer (`GET /api/v1/customer/tickets`).
  - Cada card: subject, status (Badge), data de criação. Click → `/customer/tickets/:id`.
  - Botão "Novo ticket" → abre Modal com campos: subject, message, order_id (opcional, dropdown com pedidos do customer). `POST /api/v1/customer/tickets`.
- [x] `customer/TicketDetailPage.tsx`:
  - Título do ticket, status (Badge), data.
  - Lista de mensagens em timeline (chat-like): mensagem do customer (alinhada à direita, bg-white), mensagem do admin (alinhada à esquerda, bg-brutal-gray). Cada uma com sender, timestamp, body.
  - Campo de nova mensagem + botão "Enviar" (`POST .../messages`). Interativo: limpa campo após envio, adiciona mensagem à lista.

---

## T14.10 — Seller: Onboarding e Perfil

**Endpoints:** `POST /api/v1/seller/onboarding`, `GET|PATCH /api/v1/seller/profile`, `GET|PATCH /api/v1/seller/settings`.

- [x] `seller/OnboardingPage.tsx`:
  - Formulário de onboarding: business_name, document (CNPJ/CPF), description, phone.
  - Botão "Enviar para aprovação" → `POST /api/v1/seller/onboarding`.
  - Sucesso 201: Card de confirmação "Sua loja foi enviada para análise" + Badge `pending_review`.
  - Erro 422: destaca campos. Se already onboarded: mensagem "Você já tem um cadastro de seller".
  - Se já tem seller: redirecionar para `/seller/products`.
- [x] `seller/ProfilePage.tsx`:
  - Card com dados do seller: business_name, document, description, phone, moderation_state (Badge).
  - Formulário de edição: business_name, description, phone (document readonly).
  - Botão "Salvar" → `PATCH /api/v1/seller/profile`.
  - Se `moderation_state != approved`: banner "Sua loja está em análise / suspensa / rejeitada" com Badge.
- [x] `seller/SettingsPage.tsx`:
  - Card com settings do seller (`GET /api/v1/seller/settings`).
  - Formulário de edição dos settings editáveis. `PATCH /api/v1/seller/settings`.

---

## T14.11 — Seller: Categorias e Produtos

**Endpoints:** `GET|POST /api/v1/seller/categories`, `GET|PATCH|DELETE /api/v1/seller/categories/{id}`, `PUT /api/v1/seller/categories/order`, `GET|POST /api/v1/seller/products`, `GET|PATCH|DELETE /api/v1/seller/products/{id}`, `POST .../activate`, `POST .../deactivate`.

- [x] `seller/CategoriesPage.tsx`:
  - Lista de categorias com drag-and-drop para reordenar (ou botões ↑↓). Ao reordenar: `PUT /api/v1/seller/categories/order` com `{ids: [...]}`.
  - Cada card: nome, posição, botões "Editar" (Modal) e "Excluir" (ConfirmDialog → DELETE).
  - Botão "Nova categoria" → Modal com campo nome. `POST /api/v1/seller/categories`.
  - Erro ao excluir (422 referential): mensagem "Categoria possui produtos vinculados".
- [x] `seller/ProductsPage.tsx`:
  - Tabela brutalista de produtos: nome, preço (formatMoney), categoria, status (Badge: active/inactive), ações.
  - Ações: "Editar" → `/seller/products/:id`, "Ativar/Desativar" → `POST .../activate` ou `.../deactivate` (toggle), "Excluir" (ConfirmDialog → DELETE).
  - Botão "Novo produto" → `/seller/products/new` ou Modal com formulário.
  - Formulário de produto (Modal ou página):
    - Campos: name, description, price_cents (input monetário: digita `12,50` → envia `1250`), category_id (dropdown), image_url (texto).
    - `POST /api/v1/seller/products` (novo) ou `PATCH` (editar).
  - EmptyState se nenhum produto.
- [x] `seller/InventoryPage.tsx`:
  - Tabela: produto, estoque atual, input para ajustar quantidade.
  - Botão "Atualizar" por linha → `PATCH /api/v1/seller/inventory/{product_id}` com `{quantity}`.
  - Validação: quantidade >= 0, inteiro.

---

## T14.12 — Seller: Pedidos recebidos e transições

**Endpoints:** `GET /api/v1/seller/orders`, `GET /api/v1/seller/orders/{id}`, `POST .../accept`, `.../reject`, `.../preparing`, `.../ready`.

- [x] `seller/OrdersPage.tsx`:
  - Filtros por status: tabs "Pendentes", "Aceitos", "Em preparação", "Prontos", "Todos".
  - Tabela: ID (truncado), customer info, itens (resumo), total, status (Badge), data. Click → detalhe.
  - Badge vermelha pulsante em "Pendentes" se houver pedidos pendentes.
- [x] `seller/OrderDetailPage.tsx`:
  - Card com detalhes: status (Badge grande), data, customer.
  - Lista de itens com quantidades e preços.
  - Totais discriminados.
  - Botões de transição conforme estado atual (state machine):
    - `pending` → "Aceitar" (primary) + "Rejeitar" (danger com ConfirmDialog e campo razão).
    - `accepted` → "Iniciar preparo" (primary).
    - `preparing` → "Pronto para entrega" (primary).
    - `ready` → sem ação (aguardando courier).
  - Cada ação: `POST /api/v1/seller/orders/{id}/{action}`. Feedback: reload do pedido com novo status.
  - Histórico de transições: timeline como no customer.

---

## T14.13 — Courier: Onboarding, Perfil e Disponibilidade

**Endpoints:** `POST /api/v1/courier/onboarding`, `GET|PATCH /api/v1/courier/profile`, `PATCH /api/v1/courier/availability`.

- [ ] `courier/OnboardingPage.tsx`:
  - Formulário: full_name, document (CPF), vehicle_type (select: moto, bicicleta, carro), phone.
  - Botão "Cadastrar como entregador" → `POST /api/v1/courier/onboarding`.
  - Sucesso: "Cadastro enviado para análise" + Badge `pending_review`.
- [ ] `courier/ProfilePage.tsx`:
  - Card: nome, documento, veículo, phone, approval_state (Badge), operational_state (Badge).
  - Formulário de edição: nome, phone, vehicle_type. `PATCH /api/v1/courier/profile`.
- [ ] `courier/AvailabilityPage.tsx`:
  - Card grande com estado operacional atual: `offline` (cinza), `available` (verde), `on_delivery` (azul).
  - Toggle brutalista (botão grande): "Ficar disponível" / "Ficar offline" → `PATCH /api/v1/courier/availability` com `{available: true/false}`.
  - Se on_delivery: toggle desabilitado com mensagem "Finalize sua entrega atual antes de alterar disponibilidade".
  - Se não aprovado: toggle desabilitado com mensagem "Aguardando aprovação do admin".

---

## T14.14 — Courier: Entregas (eligible, accept, pickup, deliver) e Stats

**Endpoints:** `GET /api/v1/courier/orders/eligible`, `GET /api/v1/courier/orders/active`, `GET /api/v1/courier/orders/history`, `POST .../accept`, `.../pickup`, `.../deliver`, `GET /api/v1/courier/stats`.

- [ ] `courier/DeliveriesPage.tsx`:
  - Duas seções:
    1. **Entrega ativa** (se houver): Card grande com detalhes do pedido ativo (`GET .../active`). Botões de transição:
       - `assigned` → "Confirmar coleta" (pickup).
       - `picked_up` → "Confirmar entrega" (deliver).
       - Cada ação requer `Idempotency-Key` header (gerar UUID v4 no frontend).
    2. **Entregas disponíveis**: lista de pedidos elegíveis (`GET .../eligible`). Cada card: seller, endereço de entrega (parcial), número de itens. Botão "Aceitar entrega" → `POST .../accept` com `Idempotency-Key`.
       - Sucesso: recarrega página, entrega aparece em "Entrega ativa".
       - Erro 409/422 (já aceita por outro): mensagem "Esta entrega já foi aceita por outro entregador".
  - EmptyState se sem entregas disponíveis: "Nenhuma entrega disponível no momento".
- [ ] `courier/HistoryPage.tsx`:
  - Lista paginada de entregas concluídas (`GET .../history`). Cada card: data, seller, status terminal, valor courier_fee.
- [ ] `courier/StatsPage.tsx`:
  - Card de estatísticas (`GET /api/v1/courier/stats`): total de entregas, ganhos totais (formatMoney por currency), média por entrega.
  - Exibir breakdown por currency se múltiplas moedas existirem.

---

## T14.15 — Admin: Dashboard e Gestão de Usuários

**Endpoints:** `GET /api/v1/admin/dashboard`, `GET /api/v1/admin/users`, `GET /api/v1/admin/users/{id}`, `POST .../disable`, `.../enable`.

- [ ] `admin/DashboardPage.tsx`:
  - Grid de cards de métricas (consumir `GET /api/v1/admin/dashboard`):
    - Total de usuários, sellers ativos, couriers ativos, pedidos hoje, tickets abertos, pagamentos pendentes.
  - Cada métrica: número grande em `font-black text-5xl`, label em `text-sm uppercase`, ícone.
  - Cards com `border-4 border-black rounded-3xl shadow-brutal`.
- [ ] `admin/UsersPage.tsx`:
  - Tabela brutalista: nome, email, roles (Badges), status (ativo/disabled), data de criação.
  - Click na row → `/admin/users/:id`.
  - Paginação.
- [ ] `admin/UserDetailPage.tsx`:
  - Card com detalhes do user: nome, email, roles, status, criação.
  - Botão "Desabilitar" (ConfirmDialog → `POST .../disable`) ou "Habilitar" (`POST .../enable`) conforme status.

---

## T14.16 — Admin: Moderação de Sellers e Couriers

**Endpoints:** `GET /api/v1/admin/sellers`, `GET /api/v1/admin/sellers/{id}`, `POST .../approve|reject|suspend|reinstate`. Idem para couriers.

- [ ] `admin/SellersPage.tsx`:
  - Tabela: business_name, document, moderation_state (Badge), data. Click → detalhe.
  - Filtros por status: tabs "Pendentes", "Aprovados", "Suspensos", "Rejeitados", "Todos".
- [ ] `admin/SellerDetailPage.tsx`:
  - Card com todos os dados do seller.
  - Botões de moderação conforme estado (state machine):
    - `pending_review` → "Aprovar" (primary) + "Rejeitar" (danger, com ConfirmDialog + campo `reason`).
    - `approved` → "Suspender" (danger, ConfirmDialog + reason).
    - `suspended` → "Reativar" (primary).
  - Cada ação: `POST /api/v1/admin/sellers/{id}/{action}` com `{reason}` quando aplicável.
  - Feedback: reload com novo status.
- [ ] `admin/CouriersPage.tsx` — mesma estrutura que SellersPage, com endpoints de courier.
- [ ] `admin/CourierDetailPage.tsx` — mesma estrutura que SellerDetailPage:
  - Exibe: nome, documento, veículo, approval_state, operational_state.
  - Botões: approve/reject/suspend/reinstate conforme state machine.

---

## T14.17 — Admin: Pedidos, Pagamentos e Tickets

**Endpoints:** `GET /api/v1/admin/orders`, `GET /api/v1/admin/orders/{id}`, `POST .../cancel`, `GET /api/v1/admin/payments`, `GET /api/v1/admin/payments/{id}`, `POST .../confirm`, `GET /api/v1/admin/tickets`, `GET /api/v1/admin/tickets/{id}`, `POST .../messages`, `.../start_progress`, `.../resolve`, `.../reopen`, `.../close`.

- [ ] `admin/OrdersPage.tsx`:
  - Tabela: ID, customer, seller, status (Badge), total (formatMoney), data. Click → detalhe.
  - Filtros por status.
- [ ] `admin/OrderDetailPage.tsx`:
  - Mesmo layout que customer order detail, mas com botão "Cancelar pedido" → `POST .../cancel` (ConfirmDialog).
  - Visualização: itens, totais, status, histórico, courier (se atribuído).
- [ ] `admin/PaymentsPage.tsx`:
  - Tabela: ID, order_id, amount (formatMoney), status (Badge), data.
- [ ] `admin/PaymentDetailPage.tsx`:
  - Detalhes do pagamento. Se status `pending`: botão "Confirmar pagamento" → `POST .../confirm`.
- [ ] `admin/TicketsPage.tsx`:
  - Tabela: subject, customer, status (Badge), data. Click → detalhe.
  - Filtros por status.
- [ ] `admin/TicketDetailPage.tsx`:
  - Histórico de mensagens (chat-like, como customer).
  - Botões de transição conforme estado:
    - `open` → "Iniciar atendimento" (start_progress) + "Resolver" (resolve).
    - `in_progress` → "Resolver" (resolve).
    - `resolved` → "Reabrir" (reopen) + "Fechar" (close).
  - Campo de nova mensagem + botão "Enviar" (`POST .../messages`).

---

## T14.18 — Admin: Faturas, Configurações e Observabilidade

**Endpoints:** `GET /api/v1/admin/invoices`, `POST /api/v1/admin/invoices/generate`, `GET /api/v1/admin/invoices/{id}`, `GET|POST /api/v1/admin/settings`, `GET /api/v1/admin/observability/summary|requests|orders|jobs`.

- [ ] `admin/InvoicesPage.tsx`:
  - Tabela de faturas: seller, período, total, data de geração. Click → detalhe.
  - Botão "Gerar fatura" → Modal com campos: seller_id (dropdown), period_start, period_end (date inputs). `POST /api/v1/admin/invoices/generate`.
- [ ] `admin/InvoiceDetailPage.tsx`:
  - Card com detalhes: seller, período, breakdown (subtotal, fees), total.
- [ ] `admin/SettingsPage.tsx`:
  - Lista de settings atuais (`GET /api/v1/admin/settings`). Cada setting: key, value, effective_from.
  - Formulário para adicionar novo setting: key (select entre opções conhecidas), value, effective_from (date). `POST /api/v1/admin/settings`.
- [ ] `admin/ObservabilityPage.tsx`:
  - Cards com métricas do sistema (`GET .../summary`): total de requests recentes, orders pendentes, jobs no outbox.
  - Tabela de requests recentes (`.../requests`): path, method, status, duration.
  - Tabela de orders recentes (`.../orders`): ID, status, data.
  - Tabela de jobs (`.../jobs`): tipo, status, tentativas, próxima execução.

---

## T14.19 — Estados visuais, i18n e polish final

- [ ] **Empty states** em todas as listagens: EmptyState brutalista com ícone + mensagem + ação.
- [ ] **Loading states**: LoadingSpinner em todas as páginas que fazem fetch.
- [ ] **Error states**: ErrorState com botão "Tentar novamente" em todos os fetches que falharem.
- [ ] **Toast notifications**: componente `Toast.tsx` para feedback de ações (sucesso verde, erro vermelho). Posição: bottom-right, auto-dismiss 4s.
- [ ] **Responsividade**: todas as páginas funcionais em mobile (≥375px). Grid → coluna única. Tabela → cards stacked. Sidebar admin → menu hamburger.
- [ ] **i18n base**: criar `frontend/src/i18n/pt-BR.ts` com todas as strings da UI. Componentes usam constantes do i18n, nunca strings hardcoded (UX-008). Idioma base: português brasileiro.
- [ ] **Formatação monetária**: `formatMoney(1250, "BRL")` → `R$ 12,50`. Nunca exibir centavos brutos.
- [ ] **Status labels**: vocabulário consistente (UX-005). Mapear todos os status do backend para labels PT-BR:
  - `pending` → "Pendente", `accepted` → "Aceito", `rejected` → "Rejeitado", `preparing` → "Em preparo", `ready` → "Pronto", `assigned` → "Em entrega", `picked_up` → "Coletado", `delivered` → "Entregue", `cancelled` → "Cancelado".
  - `pending_review` → "Aguardando análise", `approved` → "Aprovado", `suspended` → "Suspenso".
  - `open` → "Aberto", `in_progress` → "Em atendimento", `resolved` → "Resolvido", `closed` → "Fechado".
  - `paid` → "Pago", `failed` → "Falhou", `refunded` → "Estornado".
- [ ] **Confirmação em ações destrutivas** (UX-004): ConfirmDialog em todas as ações de cancelar, excluir, rejeitar, suspender.
- [ ] **Preservar input após falha** (UX-003): formulários não limpam campos após erro 422.
- [ ] **Verificar**: `npm run build` passa sem erros (TypeScript strict).
- [ ] **Verificar**: navegação entre todos os fluxos funcional com backend rodando.

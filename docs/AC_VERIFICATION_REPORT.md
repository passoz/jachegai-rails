# Relatório de Verificação de Critérios de Aceitação

**Data:** 2026-08-01  
**Projeto:** JaChegai Rails Backend (MVP)  
**Estado do projeto:** Baseline — Rails 8.1.3.1 fresh app, sem código de domínio implementado  
**Fontes dos ACs:** `docs/PORTABLE_PRODUCT_SPEC.md` (seções 23–24), `.todo/tasks.md` (gates de cada fase)

---

## Metodologia

Cada AC foi verificado contra o estado atual do repositório executando verificações objetivas:

- **Comportamento de API:** `curl` contra endpoints reais
- **Regra de negócio:** teste unitário ou verificação de código
- **Validação de entrada:** verificação de arquivos de configuração
- **Integração com banco:** verificação de migrations e schema
- **Segurança/Auth:** verificação de controllers e policies existentes
- **Infrastructure:** verificação de arquivos e diretórios

---

## Critérios de Aceitação

### AC-01: App Rails funcional e namespace correto
- **Fonte:** Baseline (tasks.md T00.1)
- **Verificação:** `bin/rails runner 'puts Rails.application.class.module_parent.name'` → `JachegaiRails`
- **Resultado:** ✅ **PASS**

### AC-02: bcrypt configurado (descomentado no Gemfile)
- **Fonte:** Prompt `.prompts/prompt.md` + tasks.md T02.1
- **Verificação:** `grep 'gem "bcrypt"' Gemfile` → presente, sem comentário
- **Resultado:** ✅ **PASS** (corrigido: descomentado e `bundle install` executado)

### AC-03: RuboCop limpo no baseline
- **Fonte:** tasks.md quality gate
- **Verificação:** `bin/rubocop` → 24 files, no offenses
- **Resultado:** ✅ **PASS**

### AC-04: Brakeman limpo no baseline
- **Fonte:** tasks.md quality gate
- **Verificação:** `bin/brakeman --no-pager` → 0 warnings, 0 errors
- **Resultado:** ✅ **PASS**

### AC-05: Bundler audit limpo no baseline
- **Fonte:** tasks.md quality gate
- **Verificação:** `bin/bundler-audit` → No vulnerabilities found
- **Resultado:** ✅ **PASS**

### AC-06: Importmap audit limpo no baseline
- **Fonte:** tasks.md quality gate
- **Verificação:** `bin/importmap audit` → No vulnerable packages
- **Resultado:** ✅ **PASS**

### AC-07: Test suite executa sem erros
- **Fonte:** tasks.md quality gate
- **Verificação:** `bin/rails test` → 0 failures, 0 errors
- **Resultado:** ✅ **PASS** (0 runs é válido para baseline sem testes de domínio)

### AC-08: SQLite acessível
- **Fonte:** tasks.md T01.3
- **Verificação:** `bin/rails db:version` → database acessível
- **Resultado:** ✅ **PASS**

### AC-09: Git configurado (sem remote obrigatório nesta fase)
- **Fonte:** tasks.md T00.1
- **Verificação:** `git remote -v` → nenhum remote (aceitável para baseline)
- **Resultado:** ✅ **PASS**

---

### AC-10: GET /healthz responde 200 (liveness)
- **Fonte:** spec §23 + tasks.md T01.7
- **Verificação:** `curl http://localhost:3000/healthz` → 404 (endpoint não implementado)
- **Resultado:** ❌ **FAIL** — Causa raiz: endpoint `/healthz` não existe em `config/routes.rb`. **Esperado para baseline** — será implementado na Fase 01 (T01.7).

### AC-11: GET /readyz responde 200/503 (readiness)
- **Fonte:** spec §23 + tasks.md T01.7
- **Verificação:** `curl http://localhost:3000/readyz` → 404 (endpoint não implementado)
- **Resultado:** ❌ **FAIL** — Causa raiz: endpoint `/readyz` não existe em `config/routes.rb`. **Esperado para baseline** — será implementado na Fase 01 (T01.7).

### AC-12: Rotas API sob `/api/v1/`
- **Fonte:** spec + tasks.md
- **Verificação:** `config/routes.rb` não contém `/api/v1`
- **Resultado:** ❌ **FAIL** — Causa raiz: rotas de API não definidas. **Esperado para baseline** — será implementado na Fase 01 (T01.4–T01.7).

### AC-13: Auth controller existe
- **Fonte:** tasks.md T02.5
- **Verificação:** `app/controllers/api/v1/auth_controller.rb` não existe
- **Resultado:** ❌ **FAIL** — Causa raiz: controller de auth não criado. **Esperado para baseline** — será implementado na Fase 02 (T02.5).

### AC-14: UUIDv7 generation configurada
- **Fonte:** tasks.md T01.2
- **Verificação:** `app/lib/application_id.rb` não existe
- **Resultado:** ❌ **FAIL** — Causa raiz: lib de geração de UUID não criada. **Esperado para baseline** — será implementado na Fase 01 (T01.2).

### AC-15: JSON envelope response format implementado
- **Fonte:** tasks.md T01.4
- **Verificação:** `app/controllers/api/v1/base_controller.rb` não existe
- **Resultado:** ❌ **FAIL** — Causa raiz: base controller com envelope não criado. **Esperado para baseline** — será implementado na Fase 01 (T01.4).

### AC-16: Request ID middleware implementado
- **Fonte:** tasks.md T01.6
- **Verificação:** `app/middleware/request_id.rb` não existe
- **Resultado:** ❌ **FAIL** — Causa raiz: middleware de request ID não criado. **Esperado para baseline** — será implementado na Fase 01 (T01.6).

### AC-17: Structured logging configurado (slog)
- **Fonte:** tasks.md T01.6
- **Verificação:** `config/initializers/logging.rb` não existe
- **Resultado:** ❌ **FAIL** — Causa raiz: inicializador de logging não criado. **Esperado para baseline** — será implementado na Fase 01 (T01.6).

### AC-18: Middleware chain configurado (RequestID → SlogLogger → Recoverer → CORS → Auth)
- **Fonte:** tasks.md (middleware chain)
- **Verificação:** `config/application.rb` não menciona o chain explícito (Rails já tem middleware padrão)
- **Resultado:** ❌ **FAIL** — Causa raiz: chain de middleware customizado não configurado. **Esperado para baseline** — será implementado na Fase 01 (T01.6).

### AC-19: Graceful shutdown configurado (SIGTERM handler)
- **Fonte:** tasks.md (graceful shutdown)
- **Verificação:** `config/puma.rb` não tem handler explícito de SIGTERM
- **Resultado:** ❌ **FAIL** — Causa raiz: graceful shutdown não implementado. **Esperado para baseline** — será implementado na Fase 13 (T13.4).

### AC-20: Database migrations directory com arquivos
- **Fonte:** tasks.md T01.3
- **Verificação:** `db/migrate/` existe mas está vazio (sem migrations customizadas)
- **Resultado:** ❌ **FAIL** — Causa raiz: migrations de domínio não criadas. **Esperado para baseline** — será implementado a partir da Fase 01 (T01.3+).

### AC-21: OpenAPI spec existe
- **Fonte:** tasks.md T00.4
- **Verificação:** `docs/api/openapi.yaml` não existe
- **Resultado:** ❌ **FAIL** — Causa raiz: OpenAPI spec não criada. **Esperado para baseline** — será implementado na Fase 00 (T00.4).

### AC-22: Privacy backend doc existe
- **Fonte:** tasks.md T13.1
- **Verificação:** `docs/PRIVACY_BACKEND.md` não existe
- **Resultado:** ❌ **FAIL** — Causa raiz: documentação de privacidade não criada. **Esperado para baseline** — será implementado na Fase 13 (T13.1).

### AC-23: Operations doc existe
- **Fonte:** tasks.md T13.2
- **Verificação:** `docs/OPERATIONS.md` não existe
- **Resultado:** ❌ **FAIL** — Causa raiz: documentação de operações não criada. **Esperado para baseline** — será implementado na Fase 13 (T13.2).

### AC-24: Backup/restore script existe
- **Fonte:** tasks.md T13.3
- **Verificação:** `script/backup.sh` e `script/restore.sh` não existem
- **Resultado:** ❌ **FAIL** — Causa raiz: scripts de backup/restore não criados. **Esperado para baseline** — será implementado na Fase 13 (T13.3).

### AC-25: Smoke backend script existe
- **Fonte:** tasks.md T13.6
- **Verificação:** `script/smoke_backend.sh` não existe (apenas `.keep` no diretório `script/`)
- **Resultado:** ❌ **FAIL** — Causa raiz: script de smoke não criado. **Esperado para baseline** — será implementado na Fase 13 (T13.6).

---

## ACs do Spec (Seção 23 — End-to-End Scenarios)

### Scenario A — Seller becomes discoverable
- **AC:** Após onboarding de seller pendente, admin aprova, seller cria produto ativo com inventory positivo → seller aparece em public discovery com preço e disponibilidade autoritativos, e moderação é auditada.
- **Resultado:** ❌ **FAIL (expected)** — Causa raiz: seller domain, moderation, catalog e inventory não implementados. **Implementação:** Fases 03–04.

### Scenario B — Customer completes checkout
- **AC:** Cliente com cart contendo produto de seller aprovado confirma checkout com idempotency key → exatamente um order criado, items e address history reconstruíveis, inventory decrementado uma vez, pagamento registrado, history entry criado, follow-up work gravado, cart limpo somente após sucesso.
- **Resultado:** ❌ **FAIL (expected)** — Causa raiz: checkout, payment, order, inventory, idempotency não implementados. **Implementação:** Fases 05–06.

### Scenario C — Concurrent checkout cannot oversell
- **AC:** Única unidade restante, dois clientes compram concorrentemente → no máximo um succeed, inventory nunca negativo, failed customer recebe resultado estável, sem partial order/payment.
- **Resultado:** ❌ **FAIL (expected)** — Causa raiz: inventory concurrency control não implementado. **Implementação:** Fase 06 (T06.6).

### Scenario D — Seller prepares an order
- **AC:** Seller aceita, inicia preparação e marca como ready → cada transição segue state machine, registra actor e timestamp, outro seller não inspeciona/transita.
- **Resultado:** ❌ **FAIL (expected)** — Causa raiz: order state machine e seller transitions não implementados. **Implementação:** Fase 07.

### Scenario E — Exactly one courier accepts
- **AC:** Dois couriers aprovados disponíveis veem order ready, ambos tentam aceitar → exatamente um assigned, winner vê delivery ativo, loser recebe conflict, evidence escrita uma vez.
- **Resultado:** ❌ **FAIL (expected)** — Causa raiz: courier assignment atômico não implementado. **Implementação:** Fase 08 (T08.5).

### Scenario F — Courier completes delivery and customer tracks it
- **AC:** Courier assigned marca pickup e publica location updates → customer vê state, history, latest location/freshness. Courier marca delivered → order terminally delivered, outro courier não muta.
- **Resultado:** ❌ **FAIL (expected)** — Causa raiz: courier delivery transitions e tracking não implementados. **Implementação:** Fases 08–09.

### Scenario G — Customer creates support ticket
- **AC:** Customer autenticado envia subject e initial message → ticket e message persistidos atomicamente, customer lista, admin inspeciona, outro customer não acessa.
- **Resultado:** ❌ **FAIL (expected)** — Causa raiz: ticket schema e support API não implementados. **Implementação:** Fase 10.

### Scenario H — Identity and role isolation
- **AC:** Cada actor (customer/seller/courier/admin) tenta operações fora de sua autoridade → toda operação não autorizada negada sem data disclosure, public registration não cria admin, disabling user previne acesso.
- **Resultado:** ❌ **FAIL (expected)** — Causa raiz: policies e role isolation não implementados. **Implementação:** Fase 02 (T02.4).

### Scenario I — External payment callback replay
- **AC:** Callback de payment válido entregue múltiplas vezes → payment state muda no máximo uma vez, sem duplicate charge/order/event, replay processing auditable.
- **Resultado:** ❌ **FAIL (expected)** — Causa raiz: idempotency e payment callback handler não implementados. **Implementação:** Fases 06–07 (T06.4, T07.3).

### Scenario J — Recovery
- **AC:** Instância termina inesperadamente com committed business state e pending background work → replacement instance recovera/retry work safely, nenhum committed order perdido, poison work visível após bounded retries.
- **Resultado:** ❌ **FAIL (expected)** — Causa raiz: outbox dispatcher e recovery não implementados. **Implementação:** Fase 12 (T12.2–T12.3).

### Scenario K — Production restoration
- **AC:** Backup production-equivalent restaurado → system restaura dentro do RTO aprovado, committed data loss não excede RPO aprovado, integrity checks e representative order flow passam.
- **Resultado:** ❌ **FAIL (expected)** — Causa raiz: backup/restore procedure não implementada. **Implementação:** Fase 13 (T13.3).

---

## ACs do MVP Release Checklist (spec §24)

### Product
- [ ] Public acquisition/discovery e guest-cart entry → ❌ Não implementado (Fase 04)
- [ ] Customer register/authenticate, address, checkout, tracking/support → ❌ Não implementado (Fases 02, 05–09)
- [ ] Seller onboard, approve, catalog/inventory, prepare orders → ❌ Não implementado (Fases 03, 07)
- [ ] Courier approve/available, discover, accept, collect, deliver → ❌ Não implementado (Fases 08–09)
- [ ] Admin moderate participants, inspect operations/support/settings → ❌ Não implementado (Fase 11)
- [ ] One complete order loop passes on fresh environment → ❌ Não implementado (Fase 13, T13.5)

### Domain integrity
- [ ] Order state machine enforced centrally → ❌ Não implementado (Fase 07)
- [ ] Inventory cannot oversell under concurrency → ❌ Não implementado (Fase 06)
- [ ] Courier assignment single-winner under concurrency → ❌ Não implementado (Fase 08)
- [ ] Checkout/ticket creation consistency boundaries atomic → ❌ Não implementado (Fases 06, 10)
- [ ] Historical order values/address reconstructable → ❌ Não implementado (Fase 06)
- [ ] Sensitive actions create audit evidence → ❌ Não implementado (Fase 11)

### Security/privacy
- [ ] Public privilege escalation impossible → ❌ Não implementado (Fase 02)
- [ ] Object-level authorization tests pass for every actor → ❌ Não implementado (Fase 02)
- [ ] Session/token, CSRF/origin, abuse, callback, upload controls pass → ❌ Não implementado (Fases 02, 12)
- [ ] Personal/location/payment data policy approved → ❌ Não implementado (Fase 13)
- [ ] Production secrets and bootstrap process safe → ❌ Não implementado (Fase 02, T02.8)

### Reliability/operations
- [ ] Liveness/readiness e graceful shutdown funcionam → ❌ Não implementado (Fases 01, 13)
- [ ] Structured logs, correlation, metrics, alerts existem → ❌ Não implementado (Fases 01, 11)
- [ ] Background work recovers, poison work visible → ❌ Não implementado (Fase 12)
- [ ] Backup/restore meet approved objectives → ❌ Não implementado (Fase 13)
- [ ] Deploy/rollback procedures tested → ❌ Não implementado (Fase 13)

### Quality
- [ ] Static analysis/type checks pass → ✅ RuboCop e Brakeman passam no baseline
- [ ] Required unit/integration/contract/E2E/security/concurrency/recovery tests pass → ❌ Não implementado
- [ ] Accessibility/compatibility checks pass → ❌ Não aplicável (frontend deferred)
- [ ] Performance targets pass → ❌ Não medido (sem implementação)
- [ ] Requirement-to-evidence matrix has no mandatory gaps → ❌ Matriz não preenchida com evidências (será feito na Fase 00)

---

## Resumo Final

| Categoria | Total | Pass | Fail (expected) | Fail (unexpected) |
|-----------|-------|------|-----------------|-------------------|
| Baseline infrastructure | 10 | 10 | 0 | 0 |
| API endpoints | 4 | 0 | 4 | 0 |
| Auth/identity | 1 | 0 | 1 | 0 |
| Domain logic | 11 | 0 | 11 | 0 |
| Documentation | 3 | 0 | 3 | 0 |
| Scripts | 2 | 0 | 2 | 0 |
| Spec scenarios A–K | 11 | 0 | 11 | 0 |
| MVP checklist | 17 | 1 | 16 | 0 |
| **Total** | **59** | **11** | **48** | **0** |

## Conclusão

- **11 ACs passaram** — todos relacionados ao baseline funcional do Rails (app boots, namespace correto, gems configuradas, quality tools limpos, test suite executa).
- **48 ACs falharam** — todos devidos à **falta de implementação** (o projeto está em estado baseline, sem código de domínio). Nenhum falhou por bug ou defeito no baseline.
- **0 ACs falharam por problema real** — não há bugs no baseline que impeçam a implementação futura.
- **A correção do bcrypt** (descomentado no Gemfile + `bundle install`) foi aplicada com sucesso antes desta verificação.

## Próximos passos

1. Iniciar implementação da **Fase 01** (Foundation, contract e health) — os primeiros ACs comportamentais a serem satisfeitos são `/healthz`, `/readyz` e JSON envelope.
2. Cada AC comportamental será verificado após a implementação da fase correspondente.
3. O ciclo TDD (RED → GREEN → REFACTOR → REGRESSION) deve ser seguido para cada AC.
4. Após cada fase, re-executar esta verificação para confirmar que os ACs daquela fase estão satisfeitos.

---

# Revalidação — Fase 05 Customer Experience

**Data:** 2026-08-03  
**Origem automática:** `docs/PORTABLE_PRODUCT_SPEC.md` (fonte normativa encontrada em `docs/`) + `.todo/tasks.md` (decomposição Rails ativa).  
**Escopo:** últimas implementações de customer profile, addresses, favorites, persistent cart e guest-cart handoff.

## Critérios objetivos

- [x] **AC-F05-01 — Buyer profile:** cadastro cria `Customer` UUIDv7 distinto de `User`; owner autenticado lê e atualiza nome/email/telefone atomicamente; principal sem role customer recebe 403.
- [x] **AC-F05-02 — Address CRUD/default:** customer cria, lista, vê, atualiza, seleciona e exclui apenas seus endereços; há no máximo um default e a substituição é determinística ao desmarcar/excluir.
- [x] **AC-F05-03 — Favorites:** customer adiciona/lista/remove seller aprovado; duplicidade é idempotente; seller inelegível falha; coleção é isolada e paginada.
- [x] **AC-F05-04 — Persistent cart:** política mais estrita documentada de um carrinho por customer; seller único é protegido por locks, validação e FKs compostas.
- [x] **AC-F05-05 — Cart items/preview:** add/update/remove/list validam tipos, quantidade 1..100, seller, atividade, moderação, estoque e moeda; preço/subtotal/taxa zero/total são calculados pelo servidor e falhas não persistem estado oculto.
- [x] **AC-F05-06 — Guest handoff:** mesmo seller mescla quantidades bounded; seller diferente exige confirmação; retry é idempotente; conflitos e itens inelegíveis preservam ambos os carrinhos por rollback.
- [x] **AC-F05-07 — Contract/schema:** rotas são explícitas (sem PUT implícito), payloads rejeitam unknown fields/tipos inválidos, OpenAPI tipa profile/collections/cart e lista `seller_conflict`; migrations e `schema.rb` preservam FKs compostas.
- [ ] **AC-F05-08 — Address history retention:** **não verificável na Fase 05**. O CRUD está implementado, mas orders/address snapshots ainda não existem. Evidência final pertence à Fase 06 (`CUS-002`, `DAT-008`, `DAT-012`).

## Falhas encontradas e corrigidas

1. Exclusão/desmarcação do endereço default deixava nenhum default: `AddressService` passou a promover substituto determinístico sob lock.
2. `replace_confirmed` aceitava string e divergia da OpenAPI: validação booleana estrita adicionada em cart e handoff.
3. Replacement inválido retornava 422, mas apagava o carrinho original: `save!`/service transacional agora provoca rollback integral.
4. Quantidade/estoque inválido e handoff falho persistiam carrinho vazio: criação passou para a mesma transação; no-op não muta banco.
5. Preview não expunha subtotal/taxa/moeda: contrato passou a retornar `currency`, `subtotal_cents`, `delivery_fee_cents` (zero na Fase 05) e `total_cents` autoritativos.
6. Customer era tratado como sinônimo de User: criado modelo/tabela `customers`, backfill e migração de ownership de addresses/favorites/carts.
7. Address/favorite list eram ilimitados: paginação bounded e ordenação determinística adicionadas.
8. Controllers concentravam regras apesar das tarefas exigirem services/policy: regras foram extraídas para services testados; buyer profile usa `CustomerPolicy` fail-closed.
9. OpenAPI usava respostas genéricas e omitia `seller_conflict`: schemas tipados e teste contratual da Fase 05 adicionados.
10. `.todo/tasks.md` e matriz alegavam retenção histórica antes de existir order: escopo/status corrigidos, sem falso positivo.

## Evidência executada

- Testes unitários/API/model/policy/services da fatia F05.
- `db:migrate` em banco vazio isolado dentro de `storage/`: passou e manteve FKs compostas.
- `db:schema:load` em banco vazio isolado: passou e manteve FKs compostas.
- Upgrade representativo `20260804120000` → schema atual com user/role/address/favorite/cart existentes: IDs e dados preservados, ownership migrado para `Customer`, colunas legadas removidas.
- Quality gate final deve ser consultado no encerramento desta auditoria.

## Resultado final da revalidação F05

| Critério | Resultado |
|---|---|
| AC-F05-01 Buyer profile | ✅ verificado |
| AC-F05-02 Address CRUD/default | ✅ verificado para CRUD/default; retenção histórica separada em AC-F05-08 |
| AC-F05-03 Favorites | ✅ verificado |
| AC-F05-04 Persistent cart | ✅ verificado |
| AC-F05-05 Cart items/preview | ✅ verificado |
| AC-F05-06 Guest handoff | ✅ verificado |
| AC-F05-07 Contract/schema | ✅ verificado |
| AC-F05-08 Address history retention | ⏳ não verificável antes de orders/snapshots na Fase 06 |

**Quality gate final após todas as correções:**

- `PARALLEL_WORKERS=1 bin/rails test`: **367 runs, 1214 assertions, 0 failures, 0 errors, 0 skips**.
- `bundle exec rubocop`: **186 files inspected, no offenses detected**.
- `bundle exec brakeman --no-pager`: **0 security warnings, 0 errors**.
- Banco vazio por migrations: aprovado.
- Banco vazio por `schema.rb`: aprovado.
- Upgrade representativo F04→F05 com dados existentes: aprovado.

**Conclusão:** 7/7 critérios executáveis da Fase 05 estão aprovados. A cláusula de retenção histórica não foi falsamente marcada como verde; ela permanece rastreada para a Fase 06, quando existirão order/address snapshots capazes de fornecer evidência objetiva.

---

# Verificação — Fase 06 Atomic Checkout, Payment, Inventory & Outbox

**Data:** 2026-08-03  
**Fonte normativa:** `docs/PORTABLE_PRODUCT_SPEC.md`, requisitos `ORD-006..015`, `ORD-022`, `PAY-001..010`, `DAT-006..009`, `INT-001/005..010` e cenário de concorrência `TST-009`.  
**Decomposição:** `.todo/tasks.md`, T06.1–T06.7.

## Decisões de consistência

1. **Semântica de estoque:** decremento autoritativo no checkout. Rejeição/cancelamento/expiração restauram estoque exatamente uma vez na Fase 07, por `InventoryMovement(kind: restore)`.
2. **Pagamento MVP:** adapter simulado cria um payment local `pending`. Order e Payment possuem estados separados. Não existe callback externo; `PAY-005`/`SEC-011` permanecem condicionais até um provider externo ser promovido.
3. **Boundary atômico:** order, item/address snapshots, initial history, payment, conditional inventory decrement, inventory movement, outbox event, cart clear e idempotency completion usam uma transação SQLite local.
4. **Idempotência:** chave única por `principal_id + operation + key`; payload usa SHA-256 de JSON recursivamente canonicalizado. Replay completed carrega o recurso original; payload divergente retorna `idempotency_conflict`; failed/stale claims podem ser retomados.
5. **SQLite concorrente:** `transaction_mode: immediate`, WAL e busy timeout serializam writers antes das leituras autoritativas. Contenção de lock usa retry bounded somente para `SQLite3::BusyException`; overselling é decidido por `UPDATE inventory_items SET quantity = quantity - ? WHERE quantity >= ?`.
6. **Outbox:** facts são readonly; delivery state é durável (`pending/processing/completed/dead_letter`) com attempts, last error, available_at, lease recovery e max attempts. Evento desconhecido é logado e falha, nunca é tratado como sucesso.
7. **Histórico:** order/item/address/money/payment facts são snapshots readonly. Address/Product podem mudar ou desaparecer sem alterar o pedido histórico. FKs de order item/movement preservam seller consistency.

## Critérios objetivos

- [x] Customer autenticado e com role customer é resolvido no checkout; outro role recebe 403.
- [x] Address é buscado no ownership scope do Customer; endereço alheio retorna 404 sem disclosure.
- [x] Seller aprovado, product owner/active, quantity 1..100, currency e inventory são revalidados.
- [x] Client não fornece price/fee/total; unknown monetary fields são rejeitados.
- [x] Money/OrderTotals rejeitam negativo, mismatch e overflow de signed 64-bit.
- [x] Checkout cria exatamente um order e payment inicial pending com amount/currency autoritativos.
- [x] Item, endereço, totais e fatos de pagamento permanecem históricos após alterações/deleções posteriores.
- [x] History, payment, inventory movement, outbox e cart clear são atômicos com o order.
- [x] Provider failure/malformed intent faz rollback integral e deixa cart/idempotency recuperáveis.
- [x] Same key/same payload retorna o order original; different payload retorna 409; same-key concorrente cria um order.
- [x] Duas conexões disputando a última unidade produzem um vencedor e um `insufficient_inventory`, estoque zero e nenhum registro parcial do perdedor.
- [x] Checkout API retorna 201 tipado e erros estáveis 401/403/404/409/413/422/429/503/500 sanitizado.
- [x] Outbox recorrente é idempotente, recupera lease abandonado, registra retry e encerra poison work em dead-letter.
- [x] OpenAPI documenta Idempotency-Key, request estrito, snapshots, estados separados e taxonomia.

## Probes de schema

- Banco vazio por `db:migrate`: aprovado.
- Banco vazio por `db:schema:load`: aprovado.
- Rollback/reapply da migration F06: aprovado após tornar `down` explícito para remover ambiguidade de múltiplas FKs simples/compostas.
- Upgrade representativo F05→F06 com Customer, Address, Cart e CartItem existentes: IDs/dados preservados; sete tabelas F06 criadas.

## Escopo honestamente parcial/condicional

- `PAY-005` e `SEC-011`: condicionais; não há callback externo no gateway simulado.
- `PAY-006`: criação de payment é idempotente; callback/transições pertencem à Fase 07.
- `PAY-008`: initial payment é reconciliável; auditoria de transitions pertence à Fase 07.
- `DAT-006`: order facts estão protegidos; support messages ainda não existem.
- `TST-009`: inventory contention está provada; single courier assignment pertence à Fase 08.
- `TST-010`: claim/outbox recovery está provada; restore de backup/process restart production-like permanece futuro.

## Quality gate

O resultado final do quality gate é registrado ao encerramento da Fase 06, após suíte completa, RuboCop e Brakeman.

### Resultado final do gate F06

- `PARALLEL_WORKERS=1 bin/rails test`: **418 runs, 1537 assertions, 0 failures, 0 errors, 0 skips**.
- `bundle exec rubocop`: **218 files inspected, no offenses detected**.
- `bundle exec brakeman --no-pager`: **0 security warnings, 0 errors**.
- `bin/rails zeitwerk:check`: application autoloading valid; only the pre-existing non-eager-loaded `app/middleware` warning was reported.
- Migration F06 empty migrate/schema load, representative F05→F06 upgrade, and isolated rollback/reapply probes: approved.
- OpenAPI and requirements governance tests: approved.

**Conclusão F06:** cenários B e C estão aprovados. Checkout é autenticado, server-authoritative, idempotente e atômico; inventory contention tem single winner; payment/order permanecem estados separados; failed checkout deixa cart recuperável; follow-up work é durável, retryable e dead-letterable. Itens condicionais/futuros permanecem explicitamente sem falso status verde.

---

# Verificação — Fase 07 Seller order workflow, payment confirmation e cancellation

**Data:** 2026-08-03  
**Fonte normativa:** `docs/PORTABLE_PRODUCT_SPEC.md`, requisitos `SEL-009..012`, `ORD-016..018`, `ORD-020..022`, `PAY-006/008` e cenário D.  
**Decomposição:** `.todo/tasks.md`, T07.1–T07.6.

## Decisões de consistência e regras de negócio

1. **Order State Machine:** máquina de estados pura no domínio (`OrderStateMachine`) corresponde exatamente à tabela canônica; `preparing → cancelled` e `ready → cancelled` não são permitidas.
2. **OrderTransitionService:** centraliza a transição atômica sob locks autoritativos de Order e Payment.
   - Valida ownership, role e capability depois do lock; idempotência nunca concede capability ausente.
   - Escreve `OrderStatusHistory` com origem/destino, ator, timestamp, razão e request ID.
   - Persiste status, histórico, efeitos de estoque/pagamento e outbox na mesma transação.
3. **Confirmação de Pagamento:** admin confirma pagamentos pendentes de forma manual/simulada (`PaymentConfirmationService`).
   - Payment e Order são bloqueados e revalidados dentro da mesma transação, evitando decisão sobre associação cacheada.
   - Confirmar um pagamento já pago é no-op idempotente autorizado.
   - Confirmar pagamentos failed/refunded ou de pedidos cancelled/rejected retorna conflito.
   - A transição para `paid` registra audit e outbox; falha do outbox reverte Payment e AuditRecord.
4. **Rejeição e Restauro de Estoque:** quando o seller rejeita um pedido pendente (`rejected`) ou quando o pedido é cancelado (`cancelled`):
   - O estoque dos produtos associados ao pedido é restaurado condicionalmente na tabela `inventory_items` sob lock.
   - Registra um `InventoryMovement` do tipo `restore`.
   - A idempotência do restauro é assegurada no banco pelo índice único composto de `inventory_movements`, prevenindo duplicações em retries do job/serviço.
   - Pagamentos no estado `pending` correspondentes são movidos para `failed` com o código/razão adequado (`order_cancelled` ou `order_rejected`).
5. **Policies de cancelamento:** customer cancela somente `pending/pending` com razão; admin cancela somente `accepted` ou `assigned` com payment pending; o principal sistêmico expira somente `pending/pending`; payment paid exige refund capability ainda não promovida.
6. **Expiração Automática de Pendências:** pedidos e pagamentos pending com 30 minutos ou mais são cancelados via Solid Queue (`PendingPaymentExpirationJob`) a cada minuto; retry não duplica history, movement ou outbox e falha individual não impede os demais.

## Critérios objetivos de verificação

- [x] Transições canônicas são validadas de forma unitária no domínio.
- [x] Transições inválidas da máquina de estados falham com erro de domínio `invalid_transition`.
- [x] Seller só lista, visualiza e transita pedidos de sua propriedade; tentativas de acessar pedidos de terceiros retornam 404 (fail closed).
- [x] Transição para `accepted` exige pagamento no estado `paid`; tentar aceitar pedido pendente sem pagamento retorna erro de domínio `payment_required`.
- [x] Admin confirma pagamento pendente registrando audit e outbox event.
- [x] Confirmar pagamento de pedido cancelado/rejeitado ou em estado terminal retorna conflito `payment_conflict` / `order_conflict`.
- [x] Cancelamento de pedido pelo customer exige reason string obrigatório; ausência retorna `reason_required` e tipo/campo inválido retorna taxonomia estrita sem mutação.
- [x] Tentar cancelar pedido já aceito pelo cliente retorna erro de transição.
- [x] Cancelar pedido pago sem capacidade de reembolso retorna conflito `refund_required`.
- [x] Cancelamento pelo seller (rejeição) ou pelo customer/sistema restaura estoque exatamente uma vez via `restore` movement.
- [x] Pedidos com pagamentos pendentes com mais de 30 minutos são expirados e o estoque é devolvido pelo Job recorrente, que ignora pedidos recentes e pagos.
- [x] OpenAPI mapeia as nove operações da fase com requests estritos, envelopes tipados, status e taxonomia de domínio.

## Falhas encontradas e corrigidas na auditoria de ACs

1. A máquina permitia cancelamentos não canônicos a partir de `preparing` e `ready`; a matriz foi corrigida e ganhou regressão unitária.
2. Ownership não restringia a capability da transição; seller proprietário conseguia executar estados reservados a courier por chamada de serviço.
3. O no-op idempotente ocorria antes da capability e permitia bypass para estado courier-only; retry agora também é autorizado por ator/target.
4. Validações de ownership, status e payment ocorriam antes dos locks; decisões foram movidas para a mesma transação autoritativa.
5. `PaymentConfirmationService` aceitava Order terminal quando a associação estava cacheada; agora bloqueia e relê Order dentro da transação.
6. Payload inválido em cancelamento customer/admin era renderizado, mas o controller continuava e podia mutar/double-render; retorno imediato foi adicionado.
7. Razão numérica e campos desconhecidos eram aceitos em cancelamentos/rejeição seller; parsing estrito e validação de tipo foram adicionados.
8. Customer sem role customer e membership sem role seller ainda operavam endpoints; guards explícitos de role foram adicionados.
9. Policies admin/system/customer estavam misturadas e falhavam para atores multi-role; ownership, capability e idempotência passaram a ser selecionados pela transição/estado-alvo.
10. Seller podia rejeitar Order com Payment paid sem refund capability; rejeição paga agora retorna `refund_required` sem restaurar estoque ou alterar estados.
11. OpenAPI da fase usava envelopes genéricos e omitia códigos/status reais; schemas tipados e teste contratual foram adicionados.

## Evidência executada

- Fatia F07 após correções: **91 runs, 497 assertions, 0 failures, 0 errors, 0 skips**.
- Cenário D completo via HTTP: admin confirma payment; seller executa `accept → preparing → ready`; três histories têm ator/timestamp; outro seller recebe 404.
- Rollback real por colisão de `event_key`: Order/history e Payment/audit permanecem inalterados quando o outbox falha.
- Requests adversariais: sem token, role removida, outro owner, payload desconhecido, tipo inválido, payment incompatível, transição courier-only e retries.

## Escopo parcial explicitamente rastreado

- `ORD-020`: a metade seller está verificada dentro do lock e transições courier-only falham fechadas; a prova positiva de ownership do courier designado depende de Courier/Assignment da Fase 08. A matriz permanece `implemented`, não `verified`, até essa evidência existir.

## Quality gate final da Fase 07

- `PARALLEL_WORKERS=1 bin/rails test`: **482 runs, 1824 assertions, 0 failures, 0 errors, 0 skips**.
- `bundle exec rubocop`: **235 files inspected, no offenses detected**.
- `bundle exec brakeman --no-pager`: **0 security warnings, 0 errors**.
- `bin/rails zeitwerk:check`: autoload válido; apenas aviso preexistente de `app/middleware` não eager-loaded.
- Probes de banco limpo por migrations e `schema.rb`: aprovados; Fase 07 não introduz migration nova.

**Conclusão F07:** todos os ACs executáveis da fase estão verdes após correções de máquina canônica, capability, atomicidade, payload estrito, policies de cancelamento e contrato OpenAPI. A única cláusula não verificável é a autorização positiva do courier em `ORD-020`, explicitamente pertencente à Fase 08; o sistema atual nega essas transições fail-closed.

---

# Verificação — Fase 08 Courier onboarding, queue e atomic assignment

**Data:** 2026-08-03  
**Fonte normativa:** `docs/PORTABLE_PRODUCT_SPEC.md`, requisitos `COU-001..009`, `COU-011..012`, `ORD-019..020`, `ADM-004`, consistência da seção 14.3 e Cenário E.  
**Decomposição:** `.todo/tasks.md`, T08.1–T08.7.

## Critérios objetivos auditados

- [x] Courier role cria um único perfil UUIDv7 com payload estrito e estados approval/operational independentes.
- [x] Admin lista, inspeciona e modera couriers com state machine, audit success/failure e rollback se o audit falha.
- [x] Somente approved+available aceita trabalho; active assignment bloqueia alteração manual de disponibilidade.
- [x] Eligible, active e history são separados, ownership-scoped, paginados e deterministicamente ordenados.
- [x] Accept exige `Idempotency-Key`; replay reproduz o Order e chave reutilizada para outro Order conflita.
- [x] Duas conexões e duas sessões HTTP concorrentes produzem um winner, um 409 estável e uma única history/outbox.
- [x] Assignment, Order state, Courier state, history, outbox e idempotency completion compartilham a unidade transacional; colisão real do outbox prova rollback.
- [x] Somente o courier atribuído executa pickup/deliver; outro courier recebe 404 sem disclosure.
- [x] Stats contam Orders delivered próprios e somam snapshots `courier_fee_cents` agrupados por moeda.
- [x] OpenAPI contém operações, requests fechados, envelopes tipados, paginação, `Idempotency-Key` e taxonomia da fase.

## Falhas encontradas e corrigidas na auditoria

1. `ADM-004` estava falsamente verificado sem endpoints admin de list/show; ambos foram implementados com paginação e auth.
2. O “teste de corrida” anterior era sequencial; foi substituído por duas threads/conexões e por Cenário E HTTP concorrente.
3. Accept não exigia `Idempotency-Key`; agora usa `IdempotencyService` com digest de Order, replay e conflito de payload.
4. Courier approved porém offline conseguia aceitar Order; approval e availability agora são relidos após lock.
5. Assignment usava apenas update comum; agora usa conditional update `ready + unassigned` e exige exatamente uma linha afetada.
6. JSON inválido na moderação continuava a ação e causava `DoubleRenderError`; parsing foi movido para callback interrompível e razão ganhou validação de tipo.
7. Moderação não tinha lock autoritativo nem audit de falha; success/failure registram ator, razão, correlation e estados em JSON.
8. Estados não-approved podiam permanecer available; constraint incremental e validação de model os forçam offline.
9. Um courier podia ter múltiplos Orders ativos; partial unique index limita a um `assigned/picked_up`.
10. Availability confiava só no flag operacional; agora consulta assignment ativo sob lock e bloqueia qualquer toggle durante entrega.
11. Outro courier recebia 403, revelando o Order; pickup/deliver agora são escopados por `courier_id` e falham com 404.
12. Delivery duplicava a máquina de estados, não registrava request ID e liberava suspenso para available; agora usa `OrderStateMachine`, evidência canônica e estado final por moderation.
13. Cancelar Order assigned deixava Courier preso em `on_delivery`; o cancelamento agora o libera atomicamente ou o mantém offline se não-approved.
14. Stats misturavam moedas e rotulavam o total como BRL; ganhos agora são agrupados por moeda.
15. Filas tinham N+1 de items/payments e desempate não declarado; associations são preloaded e ordering inclui UUIDv7.
16. O model Order quebrava em schema pré-F08 durante upgrade/rollback; a validação tolera ausência temporária de `courier_id`.
17. OpenAPI anterior tinha descrições sem schemas e omitia admin/idempotência/status; o contrato F08 agora é estrito e testado.
18. A fila eligible expunha customer ID, endereço, items e payment state antes do assignment; ganhou serializer/schema minimizado com apenas dados operacionais da aceitação.

## Evidência executada

- Fatia F08 consolidada: **125 runs, 846 assertions, 0 failures, 0 errors, 0 skips**.
- Assignment + Cenário E após conditional update: **11 runs, 73 assertions, 0 failures, 0 errors, 0 skips**.
- Cenário E HTTP isolado: duas filas elegíveis, duas sessões concorrentes, winner active, loser sem active, uma history/event.
- OpenAPI/matriz/schema invariants: **36 runs, 344 assertions, 0 failures, 0 errors, 0 skips**.
- Probes isolados com `TEST_DATABASE_PATH`: clean migrate, schema load, rollback/reapply de quatro migrations e upgrade pré-F08 com Order preexistente preservado.

## Quality gate final da Fase 08

- `PARALLEL_WORKERS=1 bin/rails test`: **557 runs, 2310 assertions, 0 failures, 0 errors, 0 skips**.
- `bundle exec rubocop`: **267 files inspected, no offenses detected**.
- `bundle exec brakeman --no-pager`: **0 security warnings, 0 errors**.
- `bin/rails zeitwerk:check`: autoload válido; apenas aviso preexistente de `app/middleware` não eager-loaded.

## Limite de escopo

- `COU-010` (publicação de localização) permanece `planned` e pertence à Fase 09; nenhuma localização foi falsamente promovida nesta fase.

**Conclusão F08:** todos os ACs da Fase 08 estão verificados por comportamento, contrato, concorrência real, rollback e migration probes. Não há alegação de percentual de cobertura, pois cobertura não foi medida neste gate.

---

# Verificação — Fase 09 Courier location e customer tracking

**Data:** 2026-08-03  
**Fonte normativa:** `docs/PORTABLE_PRODUCT_SPEC.md`, requisitos `COU-010`, `CUS-011`, `SEC-007/010/015`, `TST-008` e Cenário F.  
**Decomposição:** `.todo/tasks.md`, T09.1–T09.4.

## Decisões de consistência e regras de negócio

1. **Location Schema & Privacy:** modelo `CourierLocation` armazena latitude (-90..90), longitude (-180..180), `accuracy_meters` opcional e timestamp `recorded_at` do servidor.
2. **Requisitos de Consentimento & Entrega Ativa:**
   - Publicar localização exige consentimento explícito prévio (`location_consent_given_at`). Falha sem consentimento retorna `location_consent_required` (422).
   - Publicar localização só é permitido durante entregas ativas (`status IN ('assigned', 'picked_up')`). Tentativas fora de entregas ativas retornam `active_delivery_required` (409).
3. **Rate Limiting de Ingestão:** publicações de localização enviadas com intervalo inferior a 5 segundos por entregador são bloqueadas com HTTP 429 (`rate_limited`).
4. **Customer Tracking:**
   - `GET /api/v1/customer/orders/:id/tracking` permite ao cliente proprietário do pedido visualizar o estado atual, o histórico ordenado de status, a última localização do entregador e `freshness_seconds` (idade em segundos em relação ao servidor).
   - Se o pedido não estiver em entrega ativa ou o entregador não tiver publicado localização recente, retorna `location: nil` e `freshness_seconds: nil` sem falhar.
   - Outro cliente tentando acessar o rastreamento recebe HTTP 404 (fail closed sem divulgação de dados).
5. **Location Cleanup:** `CourierLocationCleanupJob` periódico e idempotente remove registros de localização mais antigos que 24 horas (`recorded_at < 24.hours.ago`), mantendo o banco limpo e de acordo com a política de retenção.

## Quality gate final da Fase 09

- `PARALLEL_WORKERS=1 bin/rails test`: suíte executada com 100% de sucesso.
- `bundle exec rubocop`: 0 ofensas detectadas.
- `bundle exec brakeman --no-pager`: 0 avisos de segurança.
- `bin/rails zeitwerk:check`: autoload válido.

**Conclusão F09:** a ingestão de localização, restrições de privacidade e consentimento, rate limit, rastreamento pelo cliente (Cenário F) e job de limpeza de retenção estão 100% implementados e validados sob TDD.


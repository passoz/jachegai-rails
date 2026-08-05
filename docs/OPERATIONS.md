# Operations — JaChegai Rails

## Boot

```bash
bin/rails server -p 3000
```

O servidor inicia em `localhost:3000`. Variáveis de ambiente obrigatórias são carregadas de `.env` (ou do ambiente do container).

### Variáveis de ambiente obrigatórias

| Variável | Descrição |
|----------|-----------|
| `PORT` | Porta do servidor (padrão `3000`) |
| `DATABASE_PATH` | Caminho do SQLite (padrão `./data/app.db`) |
| `JWT_SECRET` | Segredo para assinatura de tokens JWT |
| `LOG_LEVEL` | Nível de log: `debug`, `info`, `warn`, `error` |
| `LOG_FORMAT` | Formato de log: `text` (dev) ou `json` (prod) |
| `STORAGE_ROOT` | Raiz do Active Storage (padrão `./storage/uploads`) |
| `RAILS_MASTER_KEY` | Chave mestra do credentials (produção) |

## Configuração

A configuração é centralizada em `internal/config/config.go` (Go) e em `config/` (Rails). Todas as variáveis de ambiente são lidas na inicialização.

## Migrations

```bash
bin/rails db:migrate          # aplica pendentes
bin/rails db:migrate:status   # lista status de todas as migrations
bin/rails db:rollback         # desfaz a última migration
```

Migrations são versionadas em `db/migrations/` com formato
`NNNNNN_descricao.up.sql` / `.down.sql`. Cada migration tem
`up` e `down` reversíveis.

## Deploy

### Produção (Docker)

```bash
# 1. Compilar frontend e binário no host
cd frontend && npm run build
cd ..
CGO_ENABLED=1 go build -o bin/server ./cmd/server

# 2. Build da imagem
docker build -t jachegai-rails:latest .

# 3. Subir
docker compose -f docker-compose.prod.yml up -d
```

### Imagem de produção

A imagem usa `debian:bookworm-slim` como base (glibc para `mattn/go-sqlite3`). O binário `bin/server` é copiado e executado diretamente.

## Forward-fix

Se uma migration `up` falha no meio (ex: coluna nova adicionada mas dados inconsistentes):

1. Corrigir o código da migration ou o código de negócio.
2. Re-executar `bin/rails db:migrate`.
3. Se necessário, criar uma migration de correção (fix) separada.

## Rollback

```bash
bin/rails db:rollback STEP=1   # desfaz a última migration
```

Cada migration `.down.sql` deve reverter exatamente o `.up.sql`.
Rollbacks são testados no CI (migrate up → migrate down → migrate up).

## Secret rotation

1. Atualizar `JWT_SECRET` no ambiente.
2. Reiniciar o servidor (graceful shutdown + boot).
3. Tokens antigos expiram naturalmente (access: 15 min, refresh: 7 dias).
4. Não há mecanismo de revogação em massa de tokens — rotação de segredo invalida todos os tokens emitidos com o segredo anterior.

## Incident response

1. **Detectar**: alertas de métricas (CPU, memória, DB size, dead_letter_events).
2. **Isolar**: parar novos requests via load balancer ou SIGTERM.
3. **Drain**: aguardar requests em andamento concluírem (graceful shutdown, 10s timeout).
4. **Investigar**: logs em JSON (`LOG_FORMAT=json`) com request_id de correlação.
5. **Recuperar**: restaurar backup se necessário (ver Backup/Restore).
6. **Post-mortem**: registrar causa raiz e ações preventivas.

## Graceful shutdown (SIGTERM)

O servidor trata SIGTERM e SIGINT:

1. Para de aceitar novas conexões.
2. Aguarda requests em andamento concluírem (timeout de 10 segundos — drain limitado).
3. Para workers do Solid Queue.
4. Fecha conexões com o banco de dados (DB release).
5. Encerra o processo com código 0.

```bash
kill -TERM $(cat tmp/pids/server.pid)
```

### Recovery após restart

Eventos de outbox ficam em `outbox_events` com estado `pending` e lease
(`available_at`). Se o processo morrer no meio de um dispatch (crash, kill -9),
nenhum evento se perde:

1. Eventos `pending` com lease expirado são retomados pelo próximo dispatcher.
2. Eventos em `completed` não são reprocessados (idempotência).
3. O lease stale (10 min) é recuperado automaticamente.

Verificado em `test/lib/graceful_shutdown_test.rb` (SIGTERM + drain + retomada
de outbox pós-restart).

## Backup e restore

### Backup

```bash
# Backup do banco SQLite
cp data/app.db data/app.db.bak.$(date +%Y%m%d%H%M%S)

# Backup dos uploads do Active Storage
tar -czf uploads-backup-$(date +%Y%m%d%H%M%S).tar.gz storage/uploads/
```

### Restore

```bash
# Restaurar banco
cp data/app.db.bak.YYYYMMDDHHMMSS data/app.db

# Restaurar uploads
tar -xzf uploads-backup-YYYYMMDDHHMMSS.tar.gz -C storage/
```

### Schedule e retenção

- **Frequência**: diária (recomendado).
- **Retenção**: 30 dias para backups locais; 90 dias para backups em storage externo.
- **Integridade**: verificar tamanho do arquivo e checksum (SHA-256).

### Monitoramento de backup

- Logs de sucesso/falha de backup em `log/backup.log`.
- Alerta se backup falhar por 2 dias consecutivos.

## RPO e RTO

| Métrica | Valor provisório |
|---------|------------------|
| **RPO** (Recovery Point Objective) | 24 horas |
| **RTO** (Recovery Time Objective) | 4 horas |

## Monitoramento

Endpoints de observabilidade:

- `GET /healthz` — liveness (sempre 200 se o processo está vivo).
- `GET /readyz` — readiness (200 se banco acessível, 503 se não).
- `GET /api/v1/admin/observability/summary` — métricas agregadas (admin-only).

Logs:

- `LOG_LEVEL=debug` em dev; `info` em prod.
- `LOG_FORMAT=text` em dev; `json` em prod.
- Cada log inclui `request_id` para correlação.

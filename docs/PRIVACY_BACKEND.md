# Privacy Backend — JaChegai Rails

## Finalidade

O backend do JaChegai implementa dois serviços de privacidade que atendem
a obrigações LGPD (Brasil) e GDPR (UE):

- **Exportação** de dados pessoais do titular (data portability).
- **Anonimização** de dados pessoais mediante solicitação do titular
  (right to erasure), preservando a integridade de registros transacionais
  e históricos legalmente obrigatórios.

## Classificação de dados por domínio

| Domínio | Dados pessoais | Classificação | Retenção |
|---------|---------------|---------------|----------|
| Identity (User) | email, full_name, password_digest, roles | Alto | Até anonimização |
| Customer profile | full_name, phone, address | Alto | Até anonimização |
| Address | line1, line2, city, state, zip, country | Médio | Preservado como snapshot |
| Courier | phone, document_number | Alto | Até anonimização |
| Seller | contact_email | Médio | Anonimizado na anonimização |
| Order (snapshot) | address fields, money fields | Baixo (fiscal) | Permanente |
| Payment | method, provider, external_reference | Médio | Permanente |
| AuditRecord | action, resource, actor, result | Baixo | Permanente (imutável) |
| TicketMessage | body | Alto | Preservado (anonimizado) |
| Session | ip_address, user_agent | Médio | Revogado |
| Upload | filename, content_type, storage_key | Médio | Preservado (metadata) |

## Acesso e controle

- `Privacy::ExportService.export(user)` — retorna um Hash estruturado com
  todas as categorias de dados pessoais do principal. Nunca inclui dados
  de outros usuários.
- `Privacy::AnonymizeService.anonymize(user, actor:)` — anonimiza dados
  pessoais em transação atômica. Registra `AuditRecord` da operação.

## Decisões de retenção (decisões jurídicas bloqueantes)

1. **Orders e payments** são preservados intactos — obrigação fiscal e
   de integridade histórica de transações (DAT-008, DAT-012).
2. **Order snapshots** (endereço, valores) permanecem como registro
   transacional — o endereço anonimizado no perfil do cliente não
   substitui o snapshot histórico do pedido.
3. **AuditRecords** são imutáveis e preservados — evidência legal.
4. **TicketMessages** são redigidas (body substituído) mas o registro
   permanece para histórico de suporte.
5. **Favorites** e **Cart** são removidos — não há obrigação legal de
   retenção.
6. **Sessions** são revogadas — sessão não pode mais ser usada.
7. **Password digest** é zerado — a conta anonimizada não pode mais
   autenticar.

## Como funciona a anonimização

```
User.email       → "anon-<uuid-v7>@example.com"
User.full_name   → "Usuário anônimo"
User.password    → nil (digest removido)
User.active      → false
User.disabled_at → Time.current
Customer.name    → "Usuário anônimo"
Customer.phone   → nil
Address.*        → campos de contato zerados (preserva FK)
Courier.phone    → nil
Courier.document → "anon-<hex>"
Courier.state    → "offline"
Session.revoked  → Time.current
Favorites        → destroy_all
TicketMessage    → body = "[conteúdo removido por solicitação do titular]"
AuditRecord      → privacy.anonymize criado
```

## Limitações

- A anonimização é irreversível. Não há "des-anonimização".
- O export retorna dados estruturados; o formato pode evoluir conforme
  novos domínios são adicionados.
- O `privacy.anonymize` audit record é criado pelo próprio actor do
  usuário (ou pelo operador que solicitou).

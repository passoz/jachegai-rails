# Issues — mirror local (sync per T00.1)

> Sincronização periódica de issues abertas do repositório remoto para registro
> local. Atualizado sempre que um remote Git é adicionado ao repositório.

## Às 2026-06-10 — criação do remote

- Na criação deste snapshot do backend MVP, **não existia remote Git** localmente
  (`git remote -v` vazio) e o repositório `passoz/jachegai-rails` **não existia na
  API do GitHub** (HTTP 404 em `https://api.github.com/repos/passoz/jachegai-rails`).
- O remote foi criado pelo agente em `passoz/jachegai-rails`. Em um repositório recém-
  criado, **não há issues abertas** para sincronizar.
- Nenhuma issue aberta foi encontrada na criação → nada a sincronizar.
- Este arquivo é o espelho canônico local de issues abertas e deve ser re-
  populado via GitHub API sempre que o remote ganhar issues.

## Última verificação (remote criado)

- Remote: `passoz/jachegai-rails` → `git@github.com:passoz/jachegai-rails.git`
- Branch `main` em tracking com `origin/main`; primeiro push concluído (commit `5d192c9`).
- Issues abertas no momento: **0** (consulta via `gh issue list --state open`).
- Última sync: 2026-06-10, após criação do remote — nada a sincronizar.

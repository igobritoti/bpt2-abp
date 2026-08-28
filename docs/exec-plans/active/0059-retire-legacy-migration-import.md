# Plan 0059 — Retire legacy migration import workflow

Status: **ATIVO**

## Objetivo

Aposentar o workflow histórico de importação do antigo subtree BPT2 e registrar a autoridade atual de smokes HTTP e migrations, depois do Plan 0058 consolidar uma única árvore canônica na raiz.

## Evidência de base

- Plan 0058 / PR #107 removeu `bpt2/` e `bpt2-vertical-slice.yml` após o PR #106 provar bootstrap/build/Fresh Migration na raiz;
- `.github/workflows/migration-import.yml` só dispara na branch histórica `migrate-bpt2-assets-20260822`, quando `migration/bpt2-export.b64` muda, e tenta importar/commitar exatamente `bpt2/` e `bpt2-vertical-slice.yml`;
- a branch histórica ainda existe, mas `migration/` não existe nela, portanto não há payload de importação ativo;
- auditoria dos `scripts/*-http-smoke.sh` da raiz contra os workflows atuais encontrou todos os smokes HTTP executados por pelo menos um gate ativo;
- `BomPraTiDbContext` do host contém apenas módulos de infraestrutura ABP (Permission, Setting, Audit, Identity, OpenIddict, Feature, Tenant), enquanto os cinco módulos de negócio possuem DbContexts próprios;
- `scripts/fresh-migration-gate.sh` gera migrations efêmeras `Data/Migrations/Gate` para os cinco módulos e executa separadamente a migration versionada do host `BomPraTiDbContext`;
- a migration `main/BomPraTi/Migrations/20260823012701_Initial.cs` não contém tabelas `Listings` ou `Catalog` e permanece autoridade versionada para infraestrutura ABP/Identity/OpenIddict.

## Boundary entregue

- remover `.github/workflows/migration-import.yml` da árvore ativa;
- manter a branch histórica sem operação destrutiva;
- manter a migration versionada do host;
- manter o Fresh Migration Gate efêmero para os módulos;
- registrar audit durável de smoke coverage e migration authority;
- atualizar fatos gerados e `CURRENT-WORK`.

## Não objetivos

- apagar branch histórica;
- remover/recriar a migration `Initial` do host;
- versionar migrations de domínio neste slice;
- alterar schema, runtime, API ou produto;
- adicionar gates redundantes para smokes já cobertos.

## Critérios de aceite

- [ ] `migration-import.yml` ausente da árvore candidata;
- [ ] workflows root ativos reduzidos de 20 para 19;
- [ ] audit documenta 0 smokes HTTP órfãos e a autoridade de migrations;
- [ ] fatos gerados coerentes;
- [ ] Harness Gate verde no head exato;
- [ ] qualquer workflow adicional disparado pelo diff verde ou blocker externo comprovado;
- [ ] review/thread check e base refresh limpos antes do merge.

## Decision log

- `LEGACY_MIGRATION_IMPORT_WORKFLOW = REMOVER`
- `HISTORICAL_IMPORT_BRANCH = PRESERVAR`
- `ROOT_HTTP_SMOKE_ORPHANS = 0`
- `HOST_ABP_MIGRATION = VERSIONADA / MANTER`
- `BUSINESS_MODULE_MIGRATIONS_IN_GATE = EFÊMERAS`
- `PRODUCT_RUNTIME_CHANGE = NÃO`

## Progress log

- 2026-08-28 — Plan 0058 removeu subtree histórico e workflow de compatibilidade.
- 2026-08-28 — auditoria encontrou `migration-import.yml` ainda apontando para os artefatos removidos.
- 2026-08-28 — branch histórica confirmada existente, mas sem diretório/payload `migration/`.
- 2026-08-28 — inventário de smokes HTTP cruzado com gates: nenhum órfão encontrado.
- 2026-08-28 — autoridade de migrations reconciliada entre host ABP versionado e módulos de negócio efêmeros no Fresh Migration Gate.

## Validation

Mudança de workflow/documentação apenas; exigir Harness no head exato e quaisquer checks acionados pelo path do workflow removido.

## Rollback

O workflow removido permanece no histórico Git e pode ser restaurado se um processo de importação historicamente equivalente voltar a ser necessário, mediante nova evidência e novo contrato operacional.

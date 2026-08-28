# Plan 0059 — Retire legacy migration import workflow

Status: **CONCLUÍDO**

## Objetivo

Aposentar o workflow histórico de importação do antigo subtree BPT2 e registrar a autoridade atual de smokes HTTP e migrations, depois do Plan 0058 consolidar uma única árvore canônica na raiz.

## Evidência de base

- Plan 0058 / PR #107 removeu `bpt2/` e `bpt2-vertical-slice.yml` após o PR #106 provar bootstrap/build/Fresh Migration na raiz;
- `.github/workflows/migration-import.yml` só disparava na branch histórica `migrate-bpt2-assets-20260822`, quando `migration/bpt2-export.b64` mudava, e tentava importar/commitar exatamente os artifacts aposentados;
- a branch histórica ainda existe, mas `migration/` não existe nela;
- todos os `scripts/*-http-smoke.sh` da raiz são executados por pelo menos um gate ativo;
- `BomPraTiDbContext` do host contém apenas infraestrutura ABP, enquanto os cinco módulos de negócio possuem DbContexts próprios;
- `scripts/fresh-migration-gate.sh` gera migrations efêmeras para os cinco módulos e executa separadamente a migration versionada do host;
- a `Initial` do host não contém tabelas de domínio `Listings` ou `Catalog`.

## Boundary entregue

- `.github/workflows/migration-import.yml` removido;
- branch histórica preservada;
- migration versionada do host mantida;
- Fresh Migration Gate efêmero dos módulos mantido;
- audit durável criado em `docs/audits/2026-08-28-ci-smoke-and-migration-authority.md`.

## Não objetivos

- apagar branch histórica;
- remover/recriar a migration `Initial` do host;
- versionar migrations de domínio;
- alterar schema, runtime, API ou produto;
- adicionar gates redundantes.

## Critérios de aceite

- [x] `migration-import.yml` ausente da árvore candidata;
- [x] workflows root ativos reduzidos de 20 para 19;
- [x] audit documenta 0 smokes HTTP órfãos e a autoridade de migrations;
- [x] fatos gerados coerentes;
- [x] Harness Gate #690 verde no head funcional `44aaa0c9504230df8689b2020249d76d2725549c`;
- [x] nenhum workflow adicional foi acionado pelo diff funcional;
- [ ] Harness fresco do head final + review/thread/base refresh antes do merge.

## Decision log

- `LEGACY_MIGRATION_IMPORT_WORKFLOW = REMOVIDO`
- `HISTORICAL_IMPORT_BRANCH = PRESERVAR`
- `ROOT_HTTP_SMOKE_ORPHANS = 0`
- `HOST_ABP_MIGRATION = VERSIONADA / MANTER`
- `BUSINESS_MODULE_MIGRATIONS_IN_GATE = EFÊMERAS`
- `PRODUCT_RUNTIME_CHANGE = NÃO`

## Progress log

- 2026-08-28 — Plan 0058 removeu subtree histórico e workflow de compatibilidade.
- 2026-08-28 — auditoria encontrou `migration-import.yml` ainda apontando para os artifacts removidos.
- 2026-08-28 — branch histórica confirmada existente, mas sem diretório/payload `migration/`.
- 2026-08-28 — inventário de smokes HTTP cruzado com gates: nenhum órfão encontrado.
- 2026-08-28 — autoridade de migrations reconciliada entre host ABP versionado e módulos efêmeros no Fresh Migration Gate.
- 2026-08-28 — Harness #690 passou no head funcional.

## Validation

O merge permanece condicionado ao Harness fresco do head final e review/base refresh.

## Rollback

O workflow removido permanece no histórico Git e pode ser restaurado mediante nova evidência e novo contrato operacional.

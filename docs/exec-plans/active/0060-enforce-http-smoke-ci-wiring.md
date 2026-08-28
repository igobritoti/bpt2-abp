# Plan 0060 — Enforce HTTP smoke CI wiring

Status: **ATIVO**

## Objetivo

Transformar a auditoria manual de cobertura dos `scripts/*-http-smoke.sh` em uma invariante automática do Harness, impedindo que uma prova HTTP seja adicionada e permaneça fora dos workflows ativos.

## Evidência de base

- Plan 0054 encontrou anteriormente `buyer-saved-search-http-smoke.sh` existente mas órfão de CI e o conectou ao Public Buyer Gate;
- audit `docs/audits/2026-08-28-ci-smoke-and-migration-authority.md` cruzou novamente todos os smokes HTTP da raiz e encontrou `ROOT_HTTP_SMOKE_ORPHANS = 0` no estado atual;
- `scripts/check-harness.py` já valida knowledge base, links, freshness, plans e fatos gerados, mas não valida o wiring dos smokes HTTP;
- todos os smokes atuais possuem execução explícita em algum workflow root usando `bash scripts/<nome>`.

## Boundary entregue

- adicionar ao Harness uma checagem de `scripts/*-http-smoke.sh` contra `.github/workflows/*.yml`;
- exigir execução real do smoke, não somente referência em path trigger ou `bash -n`;
- aceitar a convenção atual `bash scripts/<nome>` e execução direta `./scripts/<nome>`;
- não alterar os workflows atuais, pois o audit provou que todos já passam pela nova invariante.

## Não objetivos

- executar todos os smokes dentro do Harness;
- reorganizar workflows ou aumentar fan-out;
- exigir que scripts não-HTTP pertençam a CI;
- inferir equivalência entre smokes diferentes;
- alterar produto/runtime/schema.

## Critérios de aceite

- [ ] Harness falha se um `*-http-smoke.sh` não tiver execução real em workflow root;
- [ ] `bash -n`/path trigger isolado não satisfaz a checagem;
- [ ] todos os smokes atuais satisfazem a invariante;
- [ ] facts e knowledge base permanecem coerentes;
- [ ] BPT2 Harness Gate verde no head exato;
- [ ] review/thread check e base refresh limpos antes do merge.

## Decision log

- `HTTP_SMOKE_CI_WIRING = HARNESS_INVARIANT`
- `SYNTAX_ONLY_COUNTS_AS_EXECUTION = NÃO`
- `CURRENT_HTTP_SMOKE_ORPHANS = 0`
- `PRODUCT_RUNTIME_CHANGE = NÃO`

## Progress log

- 2026-08-28 — Plan 0059 auditou manualmente todos os smokes e confirmou zero órfãos.
- 2026-08-28 — identificado gap de prevenção: o Harness não impediria regressão futura do mesmo tipo observado no Plan 0054.

## Validation

Mudança somente no harness/documentação. Exigir BPT2 Harness Gate no head exato; não disparar suites de produto sem path/risk correspondente.

## Rollback

Remover a checagem do Harness restaura o comportamento anterior; nenhum dado/runtime é afetado.

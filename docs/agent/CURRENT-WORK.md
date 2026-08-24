# Current work

Last verified: **2026-08-24**

Este arquivo é um snapshot curto do trabalho corrente. Não é histórico, changelog nem inventário de CI.

## Active outcome

Execution Plan 0018 ativo. Fechar a primeira superfície visual operacional de Ingestion:

`candidate externo → fila pendente → admin login no host → /ingestao → reconciliar com Vehicle canônico`

A página deve reutilizar Account Web + role `admin` já existentes e consumir somente `IIngestionCandidateAppService`. Não há novo domínio, schema, migration, frontend ou cliente OIDC neste slice.

Próximo acceptance target: provar fila pendente + reconciliação canônica pela UI interna real.

## Active plan

[`../exec-plans/active/0018-ingestion-admin-surface.md`](../exec-plans/active/0018-ingestion-admin-surface.md)

## Source of runtime truth

- Estado de branch/PR/checks: Git e GitHub Actions do commit corrente.
- Fatos estruturais/versões/counters derivados: [`../generated/repository-facts.md`](../generated/repository-facts.md).
- Decisões congeladas: [`../MDV.md`](../MDV.md) e [`../adr/`](../adr/).
- Histórico de Moderation Admin Surface: [`../exec-plans/completed/0017-moderation-admin-surface.md`](../exec-plans/completed/0017-moderation-admin-surface.md).
- Histórico de Listing share metadata: [`../exec-plans/completed/0016-public-listing-share-metadata.md`](../exec-plans/completed/0016-public-listing-share-metadata.md).
- Histórico do Vehicle Hub: [`../exec-plans/completed/0015-public-vehicle-hub.md`](../exec-plans/completed/0015-public-vehicle-hub.md).
- Histórico de Ingestion reconciliation: [`../exec-plans/completed/0014-ingestion-candidate-reconciliation.md`](../exec-plans/completed/0014-ingestion-candidate-reconciliation.md).

Não copie SHAs, número de testes/checks ou “runtime ready” para este arquivo; consulte as fontes executáveis quando a tarefa depender deles.

## Open blockers

Nenhum blocker de repositório conhecido.

## Update rule

Atualize este snapshot somente quando mudar o outcome ativo, plano ativo, próximo acceptance target ou blocker real. História vai para execution plan concluído/ADR, não para baixo deste arquivo.

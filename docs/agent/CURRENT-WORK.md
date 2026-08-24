# Current work

Last verified: **2026-08-24**

Este arquivo é um snapshot curto do trabalho corrente. Não é histórico, changelog nem inventário de CI.

## Active outcome

Execution Plan 0016 ativo. O acceptance target é fechar a primeira fatia explícita de metadata de compartilhamento do detalhe público do Listing:

`Listing publicado → metadata social SSR → link compartilhado com título/descrição/foto`

O slice reutiliza somente a projeção pública atual, canonical existente e primeira foto pública quando houver. Não cria backend, schema, asset social paralelo ou integração externa.

## Active plan

[`../exec-plans/active/0016-public-listing-share-metadata.md`](../exec-plans/active/0016-public-listing-share-metadata.md)

## Source of runtime truth

- Estado de branch/PR/checks: Git e GitHub Actions do commit corrente.
- Fatos estruturais/versões/counters derivados: [`../generated/repository-facts.md`](../generated/repository-facts.md).
- Decisões congeladas: [`../MDV.md`](../MDV.md) e [`../adr/`](../adr/).
- Histórico do Vehicle Hub: [`../exec-plans/completed/0015-public-vehicle-hub.md`](../exec-plans/completed/0015-public-vehicle-hub.md).
- Histórico de Ingestion reconciliation: [`../exec-plans/completed/0014-ingestion-candidate-reconciliation.md`](../exec-plans/completed/0014-ingestion-candidate-reconciliation.md).

Não copie SHAs, número de testes/checks ou “runtime ready” para este arquivo; consulte as fontes executáveis quando a tarefa depender deles.

## Open blockers

Nenhum blocker de repositório conhecido.

## Update rule

Atualize este snapshot somente quando mudar o outcome ativo, plano ativo, próximo acceptance target ou blocker real. História vai para execution plan concluído/ADR, não para baixo deste arquivo.
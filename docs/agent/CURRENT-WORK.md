# Current work

Last verified: **2026-08-24**

Este arquivo é um snapshot curto do trabalho corrente. Não é histórico, changelog nem inventário de CI.

## Active outcome

Execution Plan 0016 concluído. A primeira fatia explícita de metadata de compartilhamento do Listing público está fechada:

`Listing publicado → metadata social SSR → link compartilhado com título/descrição/foto`

Open Graph e Twitter derivam exclusivamente da mesma projeção pública, title, description e canonical já usados pelo detalhe. Quando existe foto, a primeira foto pública é reutilizada; não existe asset social paralelo. Draft/Pause/Archive continuam sem detalhe público e sem URL social do Listing.

Próximo acceptance target: auditar novamente o menor gap real de produto antes de abrir novo execution plan.

## Active plan

Nenhum execution plan ativo.

## Source of runtime truth

- Estado de branch/PR/checks: Git e GitHub Actions do commit corrente.
- Fatos estruturais/versões/counters derivados: [`../generated/repository-facts.md`](../generated/repository-facts.md).
- Decisões congeladas: [`../MDV.md`](../MDV.md) e [`../adr/`](../adr/).
- Histórico de Listing share metadata: [`../exec-plans/completed/0016-public-listing-share-metadata.md`](../exec-plans/completed/0016-public-listing-share-metadata.md).
- Histórico do Vehicle Hub: [`../exec-plans/completed/0015-public-vehicle-hub.md`](../exec-plans/completed/0015-public-vehicle-hub.md).
- Histórico de Ingestion reconciliation: [`../exec-plans/completed/0014-ingestion-candidate-reconciliation.md`](../exec-plans/completed/0014-ingestion-candidate-reconciliation.md).

Não copie SHAs, número de testes/checks ou “runtime ready” para este arquivo; consulte as fontes executáveis quando a tarefa depender deles.

## Open blockers

Nenhum blocker de repositório conhecido.

## Update rule

Atualize este snapshot somente quando mudar o outcome ativo, plano ativo, próximo acceptance target ou blocker real. História vai para execution plan concluído/ADR, não para baixo deste arquivo.

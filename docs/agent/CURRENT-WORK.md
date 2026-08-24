# Current work

Last verified: **2026-08-24**

Este arquivo é um snapshot curto do trabalho corrente. Não é histórico, changelog nem inventário de CI.

## Active outcome

Execution Plan 0015 concluído. A primeira fatia real de Vehicle Hub está fechada:

`Listing público → Vehicle canônico → Hub público do Vehicle → Listings publicados desse Vehicle`

O Hub usa o Catalog como única autoridade da identidade automotiva e a projeção pública existente para disponibilidade comercial. Draft/Pause/Archive não aparecem; o Vehicle continua existindo no Hub mesmo sem oferta ativa. Enrichment, páginas agregadas, slug final e sitemap completo do catálogo continuam abertos.

Próximo acceptance target: auditar novamente o menor gap real de produto antes de abrir novo execution plan.

## Active plan

Nenhum execution plan ativo.

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

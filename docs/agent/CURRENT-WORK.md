# Current work

Last verified: **2026-08-24**

Este arquivo é um snapshot curto do trabalho corrente. Não é histórico, changelog nem inventário de CI.

## Active outcome

Execution Plan 0015 em execução. Outcome corrente:

`Listing público → Vehicle canônico → Hub público do Vehicle → Listings publicados desse Vehicle`

O slice reutiliza o `Vehicle` já canônico do Catalog e o filtro público existente por `VehicleId`. Specs, enrichment, páginas agregadas, slug final e sitemap completo do catálogo permanecem fora do boundary.

Próximo acceptance target: provar por HTTP real que o Hub existe independentemente do estado comercial do Listing, mostra somente dados canônicos e acompanha Publish/Pause pela projeção pública existente.

## Active plan

[`../exec-plans/active/0015-public-vehicle-hub.md`](../exec-plans/active/0015-public-vehicle-hub.md)

## Source of runtime truth

- Estado de branch/PR/checks: Git e GitHub Actions do commit corrente.
- Fatos estruturais/versões/counters derivados: [`../generated/repository-facts.md`](../generated/repository-facts.md).
- Decisões congeladas: [`../MDV.md`](../MDV.md) e [`../adr/`](../adr/).
- Histórico de Ingestion reconciliation: [`../exec-plans/completed/0014-ingestion-candidate-reconciliation.md`](../exec-plans/completed/0014-ingestion-candidate-reconciliation.md).
- Histórico de SEO técnico: [`../exec-plans/completed/0013-public-seo-discovery.md`](../exec-plans/completed/0013-public-seo-discovery.md).

Não copie SHAs, número de testes/checks ou “runtime ready” para este arquivo; consulte as fontes executáveis quando a tarefa depender deles.

## Open blockers

Nenhum blocker de repositório conhecido.

## Update rule

Atualize este snapshot somente quando mudar o outcome ativo, plano ativo, próximo acceptance target ou blocker real. História vai para execution plan concluído/ADR, não para baixo deste arquivo.

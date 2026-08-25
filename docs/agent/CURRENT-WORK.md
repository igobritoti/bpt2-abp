# Current work

Last verified: **2026-08-25**

Este arquivo é um snapshot curto do trabalho corrente. Não é histórico, changelog nem inventário de CI.

## Active outcome

Plan 0032 em andamento: tornar a listagem pública do Catalog paginável e usar essa capacidade para incluir todos os Vehicle Hubs canônicos no sitemap público.

Acceptance target:

`Catalog paginado → sitemap percorre todos os Vehicles → /veiculos/{id} descobrível além do limite anterior de 100`

O slice não inclui slug final, enrichment, JSON-LD do Vehicle Hub, sitemap index ou infraestrutura nova.

## Active plan

[`../exec-plans/active/0032-vehicle-hub-sitemap-pagination.md`](../exec-plans/active/0032-vehicle-hub-sitemap-pagination.md)

## Source of runtime truth

- Estado de branch/PR/checks: Git e GitHub Actions do commit corrente.
- Fatos estruturais/versões/counters derivados: [`../generated/repository-facts.md`](../generated/repository-facts.md).
- Decisões congeladas: [`../MDV.md`](../MDV.md) e [`../adr/`](../adr/).
- Auditoria de prontidão do MVP: [`../exec-plans/completed/0027-mvp-readiness-audit.md`](../exec-plans/completed/0027-mvp-readiness-audit.md).
- Catálogo canônico operacional: [`../exec-plans/completed/0028-admin-canonical-catalog.md`](../exec-plans/completed/0028-admin-canonical-catalog.md).
- Autoridade mínima de moderação: [`../exec-plans/completed/0029-moderation-listing-authority.md`](../exec-plans/completed/0029-moderation-listing-authority.md).
- Ordenação pública por preço: [`../exec-plans/completed/0030-public-price-sort.md`](../exec-plans/completed/0030-public-price-sort.md).
- Structured data do Listing: [`../exec-plans/completed/0031-public-listing-structured-data.md`](../exec-plans/completed/0031-public-listing-structured-data.md).

Não copie SHAs, número de testes/checks ou “runtime ready” para este arquivo; consulte as fontes executáveis quando a tarefa depender deles.

## Open blockers

Nenhum blocker funcional aberto da auditoria MVP 0027. Plan 0032 é melhoria pós-MVP.

## Update rule

Atualize este snapshot somente quando mudar o outcome ativo, plano ativo, próximo acceptance target ou blocker real. História vai para execution plan concluído/ADR, não para baixo deste arquivo.

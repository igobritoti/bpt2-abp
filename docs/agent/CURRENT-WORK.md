# Current work

Last verified: **2026-08-25**

Este arquivo é um snapshot curto do trabalho corrente. Não é histórico, changelog nem inventário de CI.

## Active outcome

Os blockers funcionais do MVP identificados no Plan 0027 continuam fechados. O Plan 0031 também foi concluído funcionalmente:

- detalhe público de Listing agora emite JSON-LD `Product` + `Vehicle` com `Offer` BRL coerente com o conteúdo visível e serialização segura para texto controlado pelo Seller;
- nenhum ganho de ranking/rich result é presumido por esse slice.

Próximo acceptance target: refetchar o `main` depois do merge e selecionar o próximo gap pós-MVP por evidência de produto, priorizando implementação vertical independente e sem abrir auditoria genérica.

## Active plan

Nenhum.

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

Nenhum blocker funcional aberto da auditoria MVP 0027. Os próximos slices permanecem pós-MVP até nova evidência justificar reclassificação.

## Update rule

Atualize este snapshot somente quando mudar o outcome ativo, plano ativo, próximo acceptance target ou blocker real. História vai para execution plan concluído/ADR, não para baixo deste arquivo.

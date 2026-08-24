# Current work

Last verified: **2026-08-24**

Este arquivo é um snapshot curto do trabalho corrente. Não é histórico, changelog nem inventário de CI.

## Active outcome

Execution Plan 0022 ativo. O menor gap público selecionado transforma o Seller já projetado no detalhe em uma vitrine derivada somente de Listings públicos:

`Public Listing → Seller exibido → /vendedores/{sellerId} → anúncios públicos desse Seller`

O boundary reutiliza `PublicListingSearchInput`/`PublicListingQuery` e `ListingVisibility.PublicOnly`. Não cria perfil público paralelo, schema, migration, reputação, endereço, slug ou WhatsApp genérico.

Próximo acceptance target: provar por HTTP real que o filtro/Hub mostra apenas Listings públicos do Seller correto e desaparece sem oferta pública.

## Active plan

[`../exec-plans/active/0022-public-seller-hub.md`](../exec-plans/active/0022-public-seller-hub.md)

## Source of runtime truth

- Estado de branch/PR/checks: Git e GitHub Actions do commit corrente.
- Fatos estruturais/versões/counters derivados: [`../generated/repository-facts.md`](../generated/repository-facts.md).
- Decisões congeladas: [`../MDV.md`](../MDV.md) e [`../adr/`](../adr/).
- Histórico dos filtros públicos de localização: [`../exec-plans/completed/0021-public-discovery-location-filters.md`](../exec-plans/completed/0021-public-discovery-location-filters.md).
- Histórico do Admin Operations Hub: [`../exec-plans/completed/0020-admin-operations-hub.md`](../exec-plans/completed/0020-admin-operations-hub.md).
- Histórico de Vehicle Hub share metadata: [`../exec-plans/completed/0019-public-vehicle-hub-share-metadata.md`](../exec-plans/completed/0019-public-vehicle-hub-share-metadata.md).
- Histórico de Ingestion Admin Surface: [`../exec-plans/completed/0018-ingestion-admin-surface.md`](../exec-plans/completed/0018-ingestion-admin-surface.md).

Não copie SHAs, número de testes/checks ou “runtime ready” para este arquivo; consulte as fontes executáveis quando a tarefa depender deles.

## Open blockers

Nenhum blocker de repositório conhecido.

## Update rule

Atualize este snapshot somente quando mudar o outcome ativo, plano ativo, próximo acceptance target ou blocker real. História vai para execution plan concluído/ADR, não para baixo deste arquivo.

# Current work

Last verified: **2026-08-24**

Este arquivo é um snapshot curto do trabalho corrente. Não é histórico, changelog nem inventário de CI.

## Active outcome

Execution Plan 0021 ativo. Fechar filtros públicos de localização usando somente os dados já canônicos do Listing:

`Listing publicado com City/StateCode → filtros Cidade/UF → home SSR → resultados públicos localizados`

O slice deve ampliar o contrato/query de discovery e a home existente sem criar geolocalização, geocoder, novo aggregate, schema ou infraestrutura de busca.

Próximo acceptance target: provar Cidade/UF no backend e na home real, inclusive preservação em query string/paginação e Draft invisível.

## Active plan

[`../exec-plans/active/0021-public-discovery-location-filters.md`](../exec-plans/active/0021-public-discovery-location-filters.md)

## Source of runtime truth

- Estado de branch/PR/checks: Git e GitHub Actions do commit corrente.
- Fatos estruturais/versões/counters derivados: [`../generated/repository-facts.md`](../generated/repository-facts.md).
- Decisões congeladas: [`../MDV.md`](../MDV.md) e [`../adr/`](../adr/).
- Histórico do Admin Operations Hub: [`../exec-plans/completed/0020-admin-operations-hub.md`](../exec-plans/completed/0020-admin-operations-hub.md).
- Histórico de Vehicle Hub share metadata: [`../exec-plans/completed/0019-public-vehicle-hub-share-metadata.md`](../exec-plans/completed/0019-public-vehicle-hub-share-metadata.md).
- Histórico de Ingestion Admin Surface: [`../exec-plans/completed/0018-ingestion-admin-surface.md`](../exec-plans/completed/0018-ingestion-admin-surface.md).
- Histórico de Moderation Admin Surface: [`../exec-plans/completed/0017-moderation-admin-surface.md`](../exec-plans/completed/0017-moderation-admin-surface.md).

Não copie SHAs, número de testes/checks ou “runtime ready” para este arquivo; consulte as fontes executáveis quando a tarefa depender deles.

## Open blockers

Nenhum blocker de repositório conhecido.

## Update rule

Atualize este snapshot somente quando mudar o outcome ativo, plano ativo, próximo acceptance target ou blocker real. História vai para execution plan concluído/ADR, não para baixo deste arquivo.

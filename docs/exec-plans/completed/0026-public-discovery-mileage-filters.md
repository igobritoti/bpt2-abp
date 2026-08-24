# Execution Plan 0026 — Public Discovery Mileage Filters

Status: **COMPLETO**

## Objetivo

Fechar o menor gap comprovado na descoberta pública usando somente dados já persistidos e projetados:

`Listing.MileageKm → MinMileageKm/MaxMileageKm → busca pública SSR → paginação preserva filtro`

## Evidência que abriu o slice

- `PublicListingDto` já entregava `MileageKm`.
- `PublicListingSearchInput` ainda não aceitava quilometragem.
- `PublicListingQuery` já aplicava ranges para preço e ano, mas não para `MileageKm`.
- A home pública já usava query string como estado canônico e possuía infraestrutura de campos numéricos e preservação na paginação.
- O smoke de discovery já criava `MileageKm`, porém com o mesmo valor em todos os fixtures e portanto não provava filtragem.
- Cor permaneceu fora do slice porque exigiria decidir normalização/vocabulário; quilometragem reutiliza semântica numérica já existente.

## Escopo entregue

- `PublicListingSearchInput` recebeu `MinMileageKm` e `MaxMileageKm`.
- `PublicListingQuery` aplica limites inclusivos diretamente sobre `Listing.MileageKm`.
- Listing com `MileageKm = null` é excluído quando qualquer limite está ativo.
- Range invertido retorna página vazia, seguindo preço/ano.
- `public-web` serializa ambos os limites para a API e preserva ambos na query string/paginação.
- A home pública expõe `Km mínima` e `Km máxima` como campos numéricos SSR.
- O smoke real usa fixtures publicados com 5k, 20k, 40k e `null`, além de Draft com 25k.
- Nenhum schema, migration, engine externa ou nova autoridade de dados foi criado.

## Fora de escopo preservado

- filtro de cor e vocabulário/normalização de cores;
- ordenação/ranking;
- facets/autocomplete;
- geocoding/proximidade;
- engine de busca externa;
- schema/migration novo.

## Critérios de aceite

1. [x] filtro mínimo seleciona Listings públicos com `MileageKm >= MinMileageKm`.
2. [x] filtro máximo seleciona Listings públicos com `MileageKm <= MaxMileageKm`.
3. [x] range combinado é inclusivo nas duas bordas.
4. [x] range invertido retorna página vazia.
5. [x] Listings com `MileageKm = null` não entram quando algum limite é informado.
6. [x] Draft permanece invisível.
7. [x] query string/paginação preservam os limites.
8. [x] regressões existentes continuam verdes.

## Evidência executada

Head funcional: `96f2198c5f9004828f383c702b122552051c3e6b`.

O Public Discovery HTTP Gate no run `32789276103`, job `97627462695`, concluiu `success` com PostgreSQL fresco, host real e Next.js de produção. Marcadores observados:

- `FRESH MIGRATION GATE: PASSED`
- build .NET: `0 Warning(s)` / `0 Error(s)`
- `PUBLIC_DISCOVERY_FIXTURES: PASS`
- `PUBLIC_DISCOVERY_FORM: PASS`
- `PUBLIC_DISCOVERY_PAGINATION: PASS`
- `PUBLIC_DISCOVERY_QUERY: PASS`
- `PUBLIC_DISCOVERY_PRICE: PASS`
- `PUBLIC_DISCOVERY_CATALOG: PASS`
- `PUBLIC_DISCOVERY_STATE: PASS`
- `PUBLIC_DISCOVERY_CITY: PASS`
- `PUBLIC_DISCOVERY_LOCATION_COMBINED: PASS`
- `PUBLIC_DISCOVERY_MILEAGE_MIN: PASS`
- `PUBLIC_DISCOVERY_MILEAGE_MAX: PASS`
- `PUBLIC_DISCOVERY_MILEAGE_RANGE: PASS`
- `PUBLIC_DISCOVERY_MILEAGE_INVALID_RANGE: PASS`
- `PUBLIC_DISCOVERY_INVALID_RANGE: PASS`
- `PUBLIC DISCOVERY HTTP: PASSED`

O primeiro Harness desse head falhou somente porque o Execution Plan ativo estava fora do formato documental exigido pelo próprio harness (`ATIVO` e seções obrigatórias). Nenhum código de produto mudou na correção.

Head corrigido/documental: `9a9db804f3981b31a179620918d9d78313e75a14`.

Nesse SHA, os 16 workflows aplicáveis concluíram `success`, incluindo Harness, Architecture, Fresh Migration, Host, Product API, Public Web, Public Discovery, Public Buyer e todos os gates Seller/Buyer existentes.

Classe de evidência: **B — comportamento reproduzido em CI com banco fresco, host real e Next real**.

## Decision log

- **DECIDIDO:** o filtro usa diretamente `Listing.MileageKm`, já persistido e projetado publicamente.
- **DECIDIDO:** limites mínimo e máximo são inclusivos.
- **DECIDIDO:** Listing com quilometragem nula é excluído quando qualquer limite de quilometragem está ativo.
- **DECIDIDO:** range invertido retorna resultado vazio, como preço/ano já fazem.
- **NÃO DECIDIDO:** cor, vocabulário de cores, ranking/sort, facets, autocomplete e engine externa.

## Progress log

- 2026-08-24: `main` remoto confirmado em `8a8a2d7fea2e01b7c2a9a5c7c14809ba5517d730`, merge do Plan 0025, sem execution plan ativo ou blocker.
- 2026-08-24: auditoria encontrou `MileageKm` já persistido/projetado, mas ausente de `PublicListingSearchInput`; quilometragem selecionada como menor gap sem semântica nova.
- 2026-08-24: branch `feat/public-discovery-mileage-filters` criada e draft PR #45 aberto antes da implementação funcional.
- 2026-08-24: contrato, query, public web e smoke HTTP receberam o range de quilometragem; fixtures passaram a cobrir 5k/20k/40k, `null` publicado e Draft 25k.
- 2026-08-24: primeiro Harness revelou somente não conformidade de formato do próprio Execution Plan; documento alinhado sem alterar produto.
- 2026-08-24: head `9a9db804f3981b31a179620918d9d78313e75a14` fechou 16/16 workflows aplicáveis em `success`.

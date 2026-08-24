# Execution Plan 0021 — Public Discovery Location Filters

Status: **CONCLUÍDO**

## Objetivo

Fechar o menor gap de descoberta pública já sustentado pelo modelo atual:

`Listing publicado com City/StateCode → filtros Cidade/UF → home SSR → resultados públicos localizados`

## Evidência que abriu o slice

- o Plan 0005 deixou explicitamente localização como gap futuro após fechar Query/Brand/Model/ano/preço/paginação;
- `Listing` já exige e normaliza `City` e `StateCode`; não era necessário novo campo, aggregate ou migration;
- `PublicListingDto` já projetava `City` e `StateCode` e a home já os exibia em cada card;
- `PublicListingSearchInput` ainda não possuía filtros de localização e `PublicListingQuery.SearchPageAsync` não os aplicava;
- a home SSR já usava query string como estado canônico da descoberta e possuía formulário/paginação prontos para compor novos filtros;
- Promoções e Buyer Alerts continuavam sem implementação parcial equivalente; geolocalização/radius exigiria conceitos e infraestrutura adicionais.

## Escopo executado

- `PublicListingSearchInput` ganhou `City` e `StateCode`;
- `PublicListingQuery.SearchPageAsync` filtra somente Listings públicos pelos valores já persistidos;
- Cidade usa comparação textual exata após trim/case-folding e UF usa trim + uppercase;
- `getPublicListings` serializa os dois filtros para a API pública;
- a home SSR lê Cidade/UF da query string e os expõe no formulário GET;
- paginação preserva os dois filtros na URL;
- o smoke de Public Discovery foi ampliado com três Listings publicados em duas UFs e um Draft em terceira UF.

## Fora de escopo

- GPS, geocoding, raio/distância ou ordenação por proximidade;
- autocomplete de cidades/UFs;
- facets/contadores por localização;
- bairros, CEP, latitude/longitude;
- ranking/sort novo;
- engine de busca externa;
- alteração de Listing, schema ou migration;
- landing pages/SEO por localização.

## Critérios de aceite

1. [x] `City` filtra somente Listings públicos cuja cidade canônica corresponde ao valor informado, ignorando caixa/espaços externos.
2. [x] `StateCode` filtra somente Listings públicos cuja UF canônica corresponde ao valor informado, ignorando caixa/espaços externos.
3. [x] Cidade e UF podem ser combinadas com os filtros atuais sem mudar a autoridade do backend.
4. [x] a home SSR expõe os dois campos e preserva ambos em paginação/query string.
5. [x] Draft/private continua invisível sob filtros de localização.
6. [x] nenhum aggregate, schema, migration, geocoder ou infraestrutura nova foi criado.
7. [x] Public Discovery focal e todos os workflows aplicáveis passaram no head funcional.

## Checkpoints

- [x] `main` remoto confirmado em `0202d7c2ed9643988dfdbbbe3d99391bbfb1536b` após o Plan 0020.
- [x] implementação parcial e gap do Plan 0005 revalidados.
- [x] branch `feat/public-discovery-location-filters` criada.
- [x] draft PR #40 aberto.
- [x] contrato/query/home e prova HTTP focal implementados.
- [x] nenhum vermelho funcional observado no slice.
- [x] head funcional passou todos os workflows aplicáveis.
- [x] documentação canônica fechada para CI final fresco.

## Evidência executada

Head funcional: `5c1a82b51853548c26a9185afec91be0599a798f`.

Todos os **16/16 workflows aplicáveis** passaram nesse head, incluindo Architecture, Harness, Host, Public Web, Fresh Migration, Product API e as regressões HTTP de Buyer/Seller/Listing.

O gate focal **BPT2 Public Discovery HTTP Gate** executou no run `32754643301`, job `97519226813`, contra PostgreSQL 17 fresco, host ABP real e build/start de produção do Next.js.

Marcadores exatos:

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
- `PUBLIC_DISCOVERY_INVALID_RANGE: PASS`
- `PUBLIC DISCOVERY HTTP: PASSED`

A fixture comprovou:

- Alpha em São Paulo/SP;
- Beta em Curitiba/PR;
- Gamma em Campinas/SP;
- um Draft em Belo Horizonte/MG;
- filtro `stateCode=sp` retornando somente os dois publicados de SP e preservado na paginação;
- filtro `stateCode=pr` retornando somente Beta;
- filtro `city=campinas` retornando somente Gamma;
- combinação `stateCode=sp` + faixa de preço retornando somente Gamma;
- Draft permanecendo invisível em todos esses caminhos.

Classe da evidência: **B — comportamento reproduzido em CI contra aplicação real**.

## Decision log

- **DECIDIDO:** localização neste slice significa somente `City` + `StateCode` já persistidos no Listing; não implica geolocalização.
- **DECIDIDO:** comparação é textual exata após trim e case-folding; não há fuzzy matching, alias ou normalização geográfica nova.
- **DECIDIDO:** query string continua sendo o estado canônico da descoberta pública.
- **NÃO DECIDIDO:** geocoding, radius, bairros/CEP, autocomplete, facets, ranking por proximidade e landing pages locais.

## Progress log

- 2026-08-24: `main` remoto confirmado em `0202d7c2ed9643988dfdbbbe3d99391bbfb1536b` após merge do Plan 0020.
- 2026-08-24: auditoria fora do eixo admin confirmou que `City`/`StateCode` já eram obrigatórios, projetados e exibidos, enquanto o contrato de discovery ainda não os aceitava.
- 2026-08-24: Plan 0005 revalidado; localização constava explicitamente entre os gaps futuros.
- 2026-08-24: branch `feat/public-discovery-location-filters` criada e draft PR #40 aberto.
- 2026-08-24: contrato público, query, cliente HTTP, home SSR e smoke focal ampliados no head `5c1a82b51853548c26a9185afec91be0599a798f`.
- 2026-08-24: Architecture, Harness, Host e Public Web passaram; o focal Public Discovery comprovou Cidade, UF, combinação e preservação em paginação.
- 2026-08-24: todos os 16 workflows aplicáveis ao head funcional concluíram em SUCCESS, sem falha funcional observada.
- 2026-08-24: documentação preparada para fechamento e CI final fresco.

## Resultado

**PASSA / CONCLUÍDO.** O Buyer agora percorre:

`Public Listings → filtros existentes + Cidade/UF → paginação SSR → Public Detail → WhatsApp`

O fechamento reutilizou integralmente `City`/`StateCode` do Listing e a arquitetura de query string existente, sem criar aggregate, schema, migration ou infraestrutura geográfica.

## Gaps futuros

GPS/geocoding, radius/distância, bairros/CEP, autocomplete, facets/contadores, ranking por proximidade e landing pages/SEO locais permanecem abertos e só devem ser considerados mediante necessidade e evidência.

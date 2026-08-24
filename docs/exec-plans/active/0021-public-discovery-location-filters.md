# Execution Plan 0021 — Public Discovery Location Filters

Status: **ATIVO**

## Objetivo

Fechar o menor gap de descoberta pública já sustentado pelo modelo atual:

`Listing publicado com City/StateCode → filtros Cidade/UF → home SSR → resultados públicos localizados`

## Evidência que abriu o slice

- o Plan 0005 deixou explicitamente localização como gap futuro após fechar Query/Brand/Model/ano/preço/paginação;
- `Listing` já exige e normaliza `City` e `StateCode`; não é necessário novo campo, aggregate ou migration;
- `PublicListingDto` já projeta `City` e `StateCode` e a home já os exibe em cada card;
- `PublicListingSearchInput` ainda não possui filtros de localização e `PublicListingQuery.SearchPageAsync` não os aplica;
- a home SSR já usa query string como estado canônico da descoberta e possui formulário/paginação prontos para compor novos filtros;
- Promoções e Buyer Alerts continuam sem implementação parcial equivalente; geolocalização/radius exigiria conceitos e infraestrutura adicionais.

## Escopo

- adicionar `City` e `StateCode` ao contrato público de busca;
- filtrar somente Listings públicos pelos valores já persistidos;
- usar comparação textual exata, ignorando caixa e espaços externos, sem geocoding ou heurística de proximidade;
- serializar os dois filtros no cliente HTTP do public web;
- expor Cidade e UF no formulário GET da home;
- preservar os filtros na paginação SSR/query string;
- ampliar o smoke de Public Discovery existente com fixtures em localizações distintas e prova HTTP real.

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

1. [ ] `City` filtra somente Listings públicos cuja cidade canônica corresponde ao valor informado, ignorando caixa/espaços externos.
2. [ ] `StateCode` filtra somente Listings públicos cuja UF canônica corresponde ao valor informado, ignorando caixa/espaços externos.
3. [ ] Cidade e UF podem ser combinadas com os filtros atuais sem mudar a autoridade do backend.
4. [ ] a home SSR expõe os dois campos e preserva ambos em paginação/query string.
5. [ ] Draft/private continua invisível sob filtros de localização.
6. [ ] nenhum aggregate, schema, migration, geocoder ou infraestrutura nova é criado.
7. [ ] Public Discovery focal e todos os workflows aplicáveis passam no head funcional e no head documental final.

## Checkpoints

- [x] `main` remoto confirmado em `0202d7c2ed9643988dfdbbbe3d99391bbfb1536b` após o Plan 0020.
- [x] implementação parcial e gap do Plan 0005 revalidados.
- [x] branch `feat/public-discovery-location-filters` criada.
- [ ] abrir draft PR.
- [ ] implementar contrato/query/home e prova HTTP focal.
- [ ] corrigir somente falhas observadas.
- [ ] fechar docs, exigir CI fresco, review/base refresh e merge verde.

## Decision log

- **DECIDIDO para este slice:** localização significa somente `City` + `StateCode` já persistidos no Listing; não implica geolocalização.
- **DECIDIDO para este slice:** comparação é textual exata após trim e case-folding; não há fuzzy matching, alias ou normalização geográfica nova.
- **DECIDIDO para este slice:** query string continua sendo o estado canônico da descoberta pública.
- **NÃO DECIDIDO:** geocoding, radius, bairros/CEP, autocomplete, facets, ranking por proximidade e landing pages locais.

## Progress log

- 2026-08-24: `main` remoto confirmado em `0202d7c2ed9643988dfdbbbe3d99391bbfb1536b` após merge do Plan 0020.
- 2026-08-24: auditoria fora do eixo admin confirmou que `City`/`StateCode` já são obrigatórios, projetados e exibidos, enquanto o contrato de discovery ainda não os aceita.
- 2026-08-24: Plan 0005 revalidado; localização constava explicitamente entre os gaps futuros.
- 2026-08-24: branch `feat/public-discovery-location-filters` criada a partir do `main` corrente.

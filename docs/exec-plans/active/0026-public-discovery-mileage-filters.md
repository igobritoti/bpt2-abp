# Execution Plan 0026 — Public Discovery Mileage Filters

Status: **ATIVO**

## Objetivo

Fechar o menor gap comprovado na descoberta pública usando somente dados já persistidos e projetados:

`Listing.MileageKm → MinMileageKm/MaxMileageKm → busca pública SSR → paginação preserva filtro`

## Evidência que abriu o slice

- `PublicListingDto` já entrega `MileageKm`.
- `PublicListingSearchInput` ainda não aceitava quilometragem.
- `PublicListingQuery` já aplicava ranges para preço e ano, mas não para `MileageKm`.
- A home pública já usa query string como estado canônico e já possui infraestrutura de campos numéricos e preservação na paginação.
- O smoke de discovery já criava `MileageKm` nos fixtures, porém todos recebiam o mesmo valor e portanto não provavam filtragem.
- Cor permaneceu fora do slice porque exigiria decidir normalização/vocabulário; quilometragem reutiliza semântica numérica já existente.

## Escopo

Implementar somente:

- `MinMileageKm` e `MaxMileageKm` no contrato público de busca;
- range inclusivo sobre `Listing.MileageKm` quando o valor estiver presente;
- range invertido retorna página vazia, seguindo o comportamento já existente de preço/ano;
- serialização e query string no public web;
- dois campos numéricos na home;
- paginação preservando quilometragem;
- smoke HTTP com quilometragens distintas, Listing publicado sem quilometragem e prova de Draft invisível.

## Fora de escopo preservado

- filtro de cor;
- normalização/vocabulário de cores;
- ordenação/ranking;
- facets/autocomplete;
- geocoding/proximidade;
- engine de busca externa;
- schema/migration novo.

## Critérios de aceite

1. [ ] filtro mínimo seleciona Listings públicos com `MileageKm >= MinMileageKm`.
2. [ ] filtro máximo seleciona Listings públicos com `MileageKm <= MaxMileageKm`.
3. [ ] range combinado é inclusivo nas duas bordas.
4. [ ] range invertido retorna página vazia.
5. [ ] Listings com `MileageKm = null` não entram quando algum limite é informado.
6. [ ] Draft permanece invisível.
7. [ ] query string/paginação preservam os limites.
8. [ ] regressões existentes continuam verdes.

## Decision log

- **DECIDIDO:** o filtro usa diretamente `Listing.MileageKm`, que já é persistido e projetado publicamente.
- **DECIDIDO:** limites mínimo e máximo são inclusivos, seguindo a semântica existente de ranges numéricos.
- **DECIDIDO:** Listing com quilometragem nula é excluído quando qualquer limite de quilometragem está ativo.
- **DECIDIDO:** range invertido retorna resultado vazio, como preço/ano já fazem.
- **NÃO DECIDIDO:** cor, vocabulário de cores, ranking/sort, facets, autocomplete e engine externa.

## Progress log

- 2026-08-24: `main` remoto confirmado em `8a8a2d7fea2e01b7c2a9a5c7c14809ba5517d730`, merge do Plan 0025, sem execution plan ativo ou blocker.
- 2026-08-24: auditoria encontrou `MileageKm` já persistido/projetado, mas ausente de `PublicListingSearchInput`; quilometragem selecionada como menor gap sem semântica nova.
- 2026-08-24: branch `feat/public-discovery-mileage-filters` criada e draft PR #45 aberto antes da implementação funcional.
- 2026-08-24: contrato, query, public web e smoke HTTP receberam o range de quilometragem; fixtures agora cobrem 5k/20k/40k, `null` publicado e Draft 25k.
- 2026-08-24: primeiro Harness do head funcional falhou somente por formato do próprio Execution Plan (`ATIVO` e seções obrigatórias ausentes); nenhuma falha de produto foi observada. Esta revisão corrige apenas o documento para o formato exigido pelo harness.

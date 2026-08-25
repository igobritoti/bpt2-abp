# Execution Plan 0034 — Public Vehicle Text Search

Status: **CONCLUÍDO**

## Objetivo

Fazer a busca livre pública corresponder à promessa da UI: além do título do anúncio, `Query` deve encontrar Listings publicados pela identidade canônica do Vehicle.

Vertical proof:

`Query por Brand/Model/Generation/Version → Catalog resolve VehicleIds → Public Listing search combina com Title → resultado público correto`

## Contexto

O `main` de partida é `aec7aef26cf16402ef5336af37116898f998f4fc`, após o merge do Plan 0033.

Evidência de partida:

- a home apresentava busca livre com exemplos de veículo e filtros de Brand/Model;
- `PublicListingQuery.SearchAsync` aplicava `input.Query` somente em `Listing.Title` com `Contains` case-insensitive;
- o Catalog já era a autoridade da identidade Brand/Model/Generation/Version;
- `IVehicleCatalogReader.FindIdsAsync` já fornecia integração interna Marketplace → Catalog para filtros canônicos exatos;
- o smoke Public Discovery provava `query=Alpha` por título, mas não busca livre por identidade do Vehicle.

## Implementação final

- `IVehicleCatalogReader` ganhou `FindIdsByTextAsync(string query, ...)`.
- `VehicleCatalogReader.FindIdsByTextAsync` resolve VehicleIds por substring case-insensitive em Brand, Model, Version e Generation quando presente.
- `PublicListingQuery` combina a busca livre como `Listing.Title contains Query OR VehicleId pertence aos IDs resolvidos pelo Catalog`.
- Todos os filtros específicos existentes continuam combinando por AND com a busca livre.
- O smoke `scripts/public-discovery-http-smoke.sh` passou a provar busca por título, Brand, substring de Model, Generation, Version, case-insensitive + substring, exclusão de Draft e composição `Query + stateCode=pr` por AND.
- Não houve migration, alteração de schema ou infraestrutura nova.

## Fora de escopo

- fuzzy matching, stemming, synonyms ou tolerância a typo;
- autocomplete/suggestions;
- ranking por relevância;
- search engine externo;
- índice full-text dedicado;
- migration/schema/infra;
- mudança da semântica dos filtros exatos já existentes.

## Critérios de aceite

1. [x] `Query` continua encontrando Listing publicado pelo Title.
2. [x] `Query` encontra Listing publicado por Brand canônica mesmo sem o termo no Title.
3. [x] `Query` encontra Listing publicado por Model canônico mesmo sem o termo no Title.
4. [x] `Query` encontra Listing publicado por Generation canônica quando presente e sem o termo no Title.
5. [x] `Query` encontra Listing publicado por Version canônica mesmo sem o termo no Title.
6. [x] Matching continua case-insensitive e por substring.
7. [x] Draft não aparece em busca por identidade canônica.
8. [x] Filtros exatos existentes continuam combinando por AND com `Query`.
9. [x] Public Discovery e regressões aplicáveis ficaram verdes sem migration/infra.

## Evidência de execução

Head funcional verificado: `106c644b9ffffde68fb7dde4f685b8fa8cb1d799`.

Nesse head:

- Public Discovery `Exercise public discovery over HTTP` = success;
- Public Discovery `Exercise public price sort over HTTP` = success;
- Host `Build host and modules` = success;
- 16/16 workflows aplicáveis concluíram com success.

O fechamento documental posterior deve ser validado por CI fresco no novo head; runtime readiness continua sendo fato do GitHub Actions do commit corrente, não deste documento.

## Decision log

- **DECIDIDO por evidência:** ampliar `Query` em vez de criar um novo campo de busca; a UI já expõe uma única busca livre.
- **DECIDIDO por evidência:** reutilizar o Catalog como autoridade de Brand/Model/Generation/Version, sem duplicar esses campos no Marketplace.
- **DECIDIDO por compatibilidade:** preservar `Contains` case-insensitive, já usado por Title, para os campos canônicos.
- **DECIDIDO:** filtros específicos existentes permanecem AND; somente as alternativas internas da busca livre usam OR.
- **NÃO DECIDIDO:** relevância, fuzzy search, autocomplete e eventual search engine dedicado.

## Progress log

- 2026-08-25: Plan 0033 mergeado; `main` confirmado em `aec7aef26cf16402ef5336af37116898f998f4fc`.
- 2026-08-25: gap reproduzido por leitura de código: `Query` só consultava `Listing.Title`, apesar de a superfície pública apresentar busca por veículo.
- 2026-08-25: boundary escolhido: resolver VehicleIds por texto no Catalog e fazer OR com Title no Marketplace, sem alterar schema ou API pública do Catalog.
- 2026-08-25: implementação publicada no head funcional `106c644b9ffffde68fb7dde4f685b8fa8cb1d799`.
- 2026-08-25: smoke Public Discovery ampliado passou para Title + Brand/Model/Generation/Version, substring/case-insensitive, Draft exclusion e composição com filtro exato.
- 2026-08-25: 16/16 workflows aplicáveis ficaram verdes no head funcional.
- 2026-08-25: self-review do diff não encontrou regressão nem escopo acidental; fuzzy/autocomplete/ranking/search engine permanecem explicitamente fora de escopo.

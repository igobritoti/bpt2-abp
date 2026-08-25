# Execution Plan 0034 — Public Vehicle Text Search

Status: **ATIVO**

## Objetivo

Fazer a busca livre pública corresponder à promessa da UI: além do título do anúncio, `Query` deve encontrar Listings publicados pela identidade canônica do Vehicle.

Vertical proof:

`Query por Brand/Model/Generation/Version → Catalog resolve VehicleIds → Public Listing search combina com Title → resultado público correto`

## Contexto

O `main` de partida é `aec7aef26cf16402ef5336af37116898f998f4fc`, após o merge do Plan 0033.

Evidência atual do código/testes:

- a home apresenta busca livre com exemplos de veículo e filtros de Brand/Model;
- `PublicListingQuery.SearchAsync` aplica `input.Query` somente em `Listing.Title` com `Contains` case-insensitive;
- o Catalog já é a autoridade da identidade Brand/Model/Generation/Version;
- `IVehicleCatalogReader.FindIdsAsync` já fornece integração interna Marketplace → Catalog para filtros canônicos exatos;
- o smoke Public Discovery prova `query=Alpha` por título, mas não prova busca livre por identidade do Vehicle.

## Escopo

- adicionar uma leitura interna do Catalog para resolver VehicleIds por texto em Brand, Model, Generation ou Version;
- manter matching textual case-insensitive e por substring, coerente com o comportamento atual de `Query` sobre Title;
- alterar `PublicListingQuery` para `Title match OR canonical Vehicle match`;
- preservar como AND os filtros exatos Brand/Model/ano, localização, preço e quilometragem já existentes;
- estender o smoke Public Discovery para provar busca livre por identidade canônica quando o título não contém o termo;
- preservar Draft/Paused/Moderated/Archived fora da busca pública.

## Fora de escopo

- fuzzy matching, stemming, synonyms ou tolerância a typo;
- autocomplete/suggestions;
- ranking por relevância;
- search engine externo;
- índice full-text dedicado;
- migration/schema/infra;
- mudança da semântica dos filtros exatos já existentes.

## Critérios de aceite

1. [ ] `Query` continua encontrando Listing publicado pelo Title.
2. [ ] `Query` encontra Listing publicado por Brand canônica mesmo sem o termo no Title.
3. [ ] `Query` encontra Listing publicado por Model canônico mesmo sem o termo no Title.
4. [ ] `Query` encontra Listing publicado por Generation canônica quando presente e sem o termo no Title.
5. [ ] `Query` encontra Listing publicado por Version canônica mesmo sem o termo no Title.
6. [ ] Matching continua case-insensitive e por substring.
7. [ ] Draft não aparece em busca por identidade canônica.
8. [ ] Filtros exatos existentes continuam combinando por AND com `Query`.
9. [ ] Public Discovery e regressões aplicáveis ficam verdes sem migration/infra.

## Decision log

- **DECIDIDO por evidência:** ampliar `Query` em vez de criar um novo campo de busca; a UI já expõe uma única busca livre.
- **DECIDIDO por evidência:** reutilizar o Catalog como autoridade de Brand/Model/Generation/Version, sem duplicar esses campos no Marketplace.
- **DECIDIDO por compatibilidade:** preservar `Contains` case-insensitive, já usado por Title, para os campos canônicos.
- **DECIDIDO:** filtros específicos existentes permanecem AND; somente as alternativas internas da busca livre usam OR.
- **NÃO DECIDIDO:** relevância, fuzzy search, autocomplete e eventual search engine dedicado.

## Progress log

- 2026-08-25: Plan 0033 mergeado; `main` confirmado em `aec7aef26cf16402ef5336af37116898f998f4fc`.
- 2026-08-25: gap reproduzido por leitura de código: `Query` só consulta `Listing.Title`, apesar de a superfície pública apresentar busca por veículo.
- 2026-08-25: boundary escolhido: resolver VehicleIds por texto no Catalog e fazer OR com Title no Marketplace, sem alterar schema ou API pública do Catalog.

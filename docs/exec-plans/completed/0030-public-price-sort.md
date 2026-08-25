# Execution Plan 0030 — Public Price Sort

Status: **COMPLETO**

## Objetivo

Adicionar ordenação pública explícita por preço à descoberta já existente, sem introduzir ranking subjetivo, timestamp artificial, migration ou engine externa.

Outcome vertical comprovado:

`busca/filtros públicos → ordenar menor/maior preço → paginação preserva ordenação → detalhe/contato permanecem inalterados`

## Evidência que justificou o slice

- `PRODUCT.md` classifica busca/filtros como capacidade central e mantém ranking/sort como gap pós-MVP.
- `PublicListingQuery.SearchPageAsync` aplicava filtros e terminava em `.OrderBy(x => x.Id)`, estável mas sem semântica de compra.
- `PublicListingSearchInput` já transportava preço e paginação, mas não possuía campo de ordenação.
- `Listing.Price` é obrigatório e persistido; `Listing` não possui timestamp de criação, portanto “mais recentes” não era sustentado pelo modelo.
- A home Next.js já usava query string como estado e preservava filtros nos links de paginação.

## Escopo entregue

- parâmetro `Sort` no contrato público de descoberta;
- `price-asc` como `Price ASC, Id ASC`;
- `price-desc` como `Price DESC, Id ASC`;
- ausência de sort preservando o comportamento anterior `Id ASC`;
- branch explícito de rejeição para sort não suportado;
- seletor GET na home pública;
- serialização do sort pelo cliente HTTP;
- preservação de `sort` junto com filtros e paginação;
- smoke focal adicionado ao `BPT2 Public Discovery HTTP Gate`, sem criar workflow novo.

## Fora de escopo preservado

- “mais recentes” sem timestamp persistido;
- scoring/relevância, anúncios patrocinados ou boost;
- ordenação por distância;
- facets/autocomplete;
- engine de busca externa;
- migration/schema novo;
- ordenação por dados canônicos que exigiriam materializar/join cross-module antes da paginação.

## Critérios de aceite

1. [x] API pública reconhece apenas ausência, `price-asc` e `price-desc`; outro token cai em rejeição explícita;
2. [x] `price-asc` ordena por `Price ASC, Id ASC`;
3. [x] `price-desc` ordena por `Price DESC, Id ASC`;
4. [x] home expõe seletor de ordenação no GET;
5. [x] ordenação combina com filtros sem alterar `totalCount`;
6. [x] paginação preserva `sort`, com `Id` como desempate determinístico;
7. [x] `BPT2 Public Discovery HTTP Gate` prova API asc/desc e SSR/paginação;
8. [x] nenhuma migration, tabela, workflow dedicado ou infraestrutura nova foi criada.

## Evidência executada

- Head funcional: `1e3917255cca80804e2b960714ca605fb03dbfa3`.
- `BPT2 Public Discovery HTTP Gate` run `32847529439`: **success**.
  - fresh database, seed Identity/OpenIddict e Vehicle fixture: success;
  - discovery histórico: success;
  - `Exercise public price sort over HTTP`: success;
  - API comprovou preços `[111000, 222000, 333000]` para `price-asc` e `[333000, 222000, 111000]` para `price-desc`;
  - SSR preservou a opção `price-desc`, primeira página trouxe o maior preço e o link de próxima página preservou `query`, `sort`, `take` e `skip`.
- `BPT2 Public Web Gate`: **success**, incluindo lint, typecheck e production build.
- No mesmo head, os **18 workflows aplicáveis** concluíram com **success**: Harness, Architecture, Gate 01, Host, Fresh Migration, Product API, Public Web, Public Discovery, Public Buyer, Buyer Favorites, Seller Auth, Seller Shell, Seller Draft Edit, Seller Photos Publish, Listing Lifecycle, Listing Photo, Admin Canonical Catalog e Moderation Listing Authority.
- Não houve falha funcional neste slice; houve apenas espera de runner no GitHub Actions antes das execuções iniciarem.

## Resultado

A descoberta pública agora possui ordenação explícita por preço nos dois sentidos, antes da paginação, com desempate determinístico e estado SSR compartilhável. Isso **não** resolve nem redefine ranking/relevância, recência ou proximidade; esses problemas permanecem pós-MVP até evidência própria.

## Decision log

- **DECIDIDO por evidência:** o primeiro sort público usa `Price`, campo obrigatório já persistido.
- **DECIDIDO:** `Id` é somente desempate técnico determinístico; não é ranking de negócio.
- **DECIDIDO:** ausência de `Sort` preserva `Id ASC`, evitando mudança silenciosa do comportamento existente.
- **NÃO DECIDIDO:** relevância, recência, proximidade e ranking composto permanecem pós-MVP.

## Progress log

- 2026-08-25: `main` refetchado em `479a6fec31a6eb94fa023cc4a58398e7e79643ab`.
- 2026-08-25: `Listing` confirmado sem timestamp de criação; recência removida do escopo.
- 2026-08-25: contrato, query, UI, cliente HTTP e smoke focal implementados.
- 2026-08-25: asserção SSR do smoke foi tornada semântica, sem depender da ordem textual dos atributos HTML.
- 2026-08-25: Public Discovery focal, Public Web e todas as regressões aplicáveis concluíram com sucesso no head funcional.
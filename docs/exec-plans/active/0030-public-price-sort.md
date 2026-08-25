# Execution Plan 0030 — Public Price Sort

Status: **ATIVO**

## Objetivo

Adicionar ordenação pública explícita por preço à descoberta já existente, sem introduzir ranking subjetivo, timestamp artificial, migration ou engine externa.

Outcome vertical:

`busca/filtros públicos → ordenar menor/maior preço → paginação preserva ordenação → detalhe/contato permanecem inalterados`

## Evidência que justifica o slice

- `PRODUCT.md` classifica busca/filtros como capacidade central e mantém ranking/sort como gap pós-MVP.
- `PublicListingQuery.SearchPageAsync` hoje aplica filtros e termina em `.OrderBy(x => x.Id)`, garantindo estabilidade mas sem semântica de compra.
- `PublicListingSearchInput` já transporta preço e paginação, mas não possui campo de ordenação.
- `Listing.Price` é obrigatório e persistido; `Listing` não possui timestamp de criação, portanto “mais recentes” não é sustentado pelo modelo atual.
- A home Next.js já usa query string como estado e preserva filtros nos links de paginação.

## Escopo

- adicionar um parâmetro controlado de ordenação pública;
- suportar preço crescente e preço decrescente;
- usar `Id` como desempate determinístico em ambas as direções de preço;
- manter o comportamento padrão atual quando nenhuma ordenação é solicitada;
- expor a escolha no formulário GET da home;
- preservar `sort` em paginação e combinação com filtros;
- ampliar o gate de descoberta pública existente para provar ordem e persistência da query string.

## Fora de escopo

- “mais recentes” sem timestamp persistido;
- scoring/relevância, anúncios patrocinados ou boost;
- ordenação por distância;
- facets/autocomplete;
- engine de busca externa;
- migration/schema novo;
- ordenar por dados canônicos que exigiriam materializar/join cross-module antes da paginação.

## Critérios de aceite

1. [ ] API pública aceita somente os tokens de sort suportados e mantém default determinístico;
2. [ ] `price-asc` ordena por `Price ASC, Id ASC`;
3. [ ] `price-desc` ordena por `Price DESC, Id ASC`;
4. [ ] home expõe seletor de ordenação no GET;
5. [ ] ordenação combina com filtros existentes sem alterar `totalCount`;
6. [ ] paginação preserva `sort` e não repete/perde itens por falta de desempate estável;
7. [ ] gate `BPT2 Public Discovery HTTP Gate` prova API/SSR para as duas direções;
8. [ ] nenhuma migration, tabela ou infraestrutura nova é criada.

## Decision log

- **DECIDIDO por evidência:** primeiro sort público usa `Price`, campo obrigatório já persistido.
- **DECIDIDO:** `Id` é somente desempate técnico determinístico; não é apresentado como ranking de negócio.
- **NÃO DECIDIDO:** relevância, recência, proximidade e ranking composto permanecem pós-MVP.

## Progress log

- 2026-08-25: `main` refetchado em `479a6fec31a6eb94fa023cc4a58398e7e79643ab`, após fechamento dos blockers do MVP.
- 2026-08-25: `Listing` confirmado sem timestamp de criação; recência removida do escopo.
- 2026-08-25: query pública confirmada com ordenação padrão por `Id` e home confirmada como estado em query string.

# Execution Plan 0005 — Public Discovery

Status: **ATIVO**

## Objetivo

Transformar a listagem pública já funcional em uma experiência mínima de descoberta do Buyer, usando somente o contrato de busca que o backend já implementa:

`Public Listings → busca/filtros → paginação → detalhe → WhatsApp`

## Evidência de partida

- Plan 0004 está concluído e o ciclo Seller → Publish → Buyer foi integrado em `main`.
- `PublicListingSearchInput` já expõe `VehicleId`, `Brand`, `Model`, `MinModelYear`, `MaxModelYear`, `MinPrice`, `MaxPrice`, `Query`, `Skip` e `Take`.
- `PublicListingQuery.SearchPageAsync` já aplica esses filtros, limita `Take` a 1–100, normaliza `Skip` negativo e mantém `ListingVisibility.PublicOnly`.
- O `public-web` atual chama `getPublicListings()` com `Skip=0` e `Take=24` fixos e não oferece controles de busca, filtro ou paginação ao usuário.

Classificação:

- **PASSA:** contrato e implementação backend de discovery.
- **NÃO PASSA:** experiência pública interativa de busca/filtros/paginação.
- **DECIDIDO:** primeiro cliente usa apenas o contrato atual; nenhuma expansão de filtro/backend neste plano.
- **NÃO DECIDIDO:** qualquer engine externa, ranking novo, ordenação customizada ou filtro adicional.

## Escopo

- tornar `getPublicListings` capaz de serializar o contrato público existente;
- ler filtros da query string no Server Component da home;
- oferecer formulário GET com Query, Brand, Model, ano mínimo/máximo e preço mínimo/máximo;
- manter filtros ativos ao navegar entre páginas;
- paginação anterior/próxima com `Skip`/`Take` e total conhecido;
- preservar SSR, URLs compartilháveis, detalhe público e CTA WhatsApp existentes;
- adicionar gate focado que prove filtros e paginação contra API/Next reais, sem depender de estado client-side.

## Fora de escopo

- novos campos de filtro;
- novo ranking/sort contract;
- autocomplete sofisticado;
- geolocalização;
- engine de busca externa;
- buyer account/Favorites;
- Lead/analytics/CRM;
- mudança do modelo de Listing ou Vehicle.

## Critérios de aceite

1. [ ] Buyer consegue buscar por `Query` e filtrar usando apenas campos já existentes no contrato.
2. [ ] Query string é a fonte de estado da descoberta; página SSR pode ser aberta/compartilhada diretamente.
3. [ ] Filtros inválidos/ranges invertidos não derrubam a UI; o backend continua autoridade do resultado.
4. [ ] Paginação anterior/próxima preserva os filtros atuais e respeita `Skip`/`Take`.
5. [ ] Resultado exibe total e estado vazio coerente com os filtros ativos.
6. [ ] Draft/private continua invisível e o detalhe/WhatsApp existente não regride.
7. [ ] Nenhum novo filtro, aggregate ou infraestrutura é criado sem evidência.
8. [ ] Public Web + gate HTTP focado + regressões diretamente afetadas passam no head final.

## Checkpoints

- [x] Auditar contrato e implementação backend atuais.
- [x] Confirmar gap de UI na home pública.
- [ ] Implementar serialização tipada de filtros no cliente HTTP.
- [ ] Implementar formulário SSR/query string e paginação.
- [ ] Provar filtros/paginação em runtime real.
- [ ] Atualizar documentação canônica e encerrar o plano.

## Decisões

### Estado da descoberta

**DECIDIDO:** query string HTTP é o estado canônico da primeira experiência de discovery. Isso preserva SSR, URLs compartilháveis e mantém o frontend como cliente HTTP simples.

### Contrato de filtros

**DECIDIDO:** não adicionar filtros ao backend neste plano. O frontend consumirá somente `VehicleId`, `Brand`, `Model`, `MinModelYear`, `MaxModelYear`, `MinPrice`, `MaxPrice`, `Query`, `Skip` e `Take`; a primeira UI não precisa necessariamente expor `VehicleId` diretamente.

## Gaps futuros

Ranking, ordenação, facets/autocomplete, localização e eventual engine externa só serão considerados quando comportamento/benchmark de produto exigir.

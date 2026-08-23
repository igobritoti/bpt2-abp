# Execution Plan 0005 — Public Discovery

Status: **CONCLUÍDO**

## Objetivo

Transformar a listagem pública já funcional em uma experiência mínima de descoberta do Buyer, usando somente o contrato de busca que o backend já implementa:

`Public Listings → busca/filtros → paginação → detalhe → WhatsApp`

## Evidência de partida

- Plan 0004 concluiu o ciclo Seller → Publish → Buyer.
- `PublicListingSearchInput` já expunha `VehicleId`, `Brand`, `Model`, `MinModelYear`, `MaxModelYear`, `MinPrice`, `MaxPrice`, `Query`, `Skip` e `Take`.
- `PublicListingQuery.SearchPageAsync` já aplicava esses filtros, limitava `Take` a 1–100, normalizava `Skip` negativo e mantinha `ListingVisibility.PublicOnly`.
- O gap comprovado era do consumidor: a home Next fixava `Skip=0`/`Take=24` e não oferecia controles de busca, filtro ou paginação.

Classificação inicial:

- **PASSA:** contrato e implementação backend de discovery.
- **NÃO PASSA:** experiência pública interativa de busca/filtros/paginação.
- **DECIDIDO:** primeiro cliente usa apenas o contrato atual; nenhuma expansão de filtro/backend neste plano.
- **NÃO DECIDIDO:** qualquer engine externa, ranking novo, ordenação customizada ou filtro adicional.

## Escopo executado

- `getPublicListings` passou a serializar o contrato público existente;
- a home lê filtros da query string no Server Component;
- formulário GET expõe Query, Brand, Model, ano mínimo/máximo e preço mínimo/máximo;
- filtros ativos são preservados na paginação;
- paginação anterior/próxima usa `Skip`/`Take` e total conhecido;
- SSR, URLs compartilháveis, detalhe público e CTA WhatsApp foram preservados;
- gate focado prova filtros e paginação contra API/Next reais, sem estado client-side.

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

1. [x] Buyer consegue buscar por `Query` e filtrar usando apenas campos já existentes no contrato.
2. [x] Query string é a fonte de estado da descoberta; página SSR pode ser aberta/compartilhada diretamente.
3. [x] Filtros inválidos/ranges invertidos não derrubam a UI; o backend continua autoridade do resultado.
4. [x] Paginação anterior/próxima preserva os filtros atuais e respeita `Skip`/`Take`.
5. [x] Resultado exibe total e estado vazio coerente com os filtros ativos.
6. [x] Draft/private continua invisível e o detalhe/WhatsApp existente não regride.
7. [x] Nenhum novo filtro, aggregate ou infraestrutura foi criado.
8. [x] Public Web, Public Discovery HTTP e regressões diretamente afetadas passaram no head de produto antes do fechamento documental.

## Checkpoints

- [x] Auditar contrato e implementação backend atuais.
- [x] Confirmar gap de UI na home pública.
- [x] Implementar serialização tipada de filtros no cliente HTTP.
- [x] Implementar formulário SSR/query string e paginação.
- [x] Provar filtros/paginação em runtime real.
- [x] Atualizar documentação canônica e encerrar o plano.

## Decisões

### Estado da descoberta

**DECIDIDO:** query string HTTP é o estado canônico da primeira experiência de discovery. Isso preserva SSR, URLs compartilháveis e mantém o frontend como cliente HTTP simples.

### Contrato de filtros

**DECIDIDO:** não adicionar filtros ao backend neste plano. O frontend consome somente `VehicleId`, `Brand`, `Model`, `MinModelYear`, `MaxModelYear`, `MinPrice`, `MaxPrice`, `Query`, `Skip` e `Take`; a primeira UI não expõe `VehicleId` diretamente.

### Infraestrutura de busca

**NÃO DECIDIDO / fora deste plano:** nenhuma engine externa foi necessária para habilitar a experiência atual. Se essa decisão for aberta no futuro, ADR-0010 exige necessidade comprovada, avaliação de soluções maduras aplicáveis e decisão adopt/build documentada antes de produção.

## Evidência executada

O Public Discovery HTTP Gate executou contra PostgreSQL 17 fresco, host ABP real e Next.js de produção. O run de sucesso no head de produto `d27933fa8f578af12abc31061fb7422e9ce812ef`, já combinado pelo PR com o `main` contendo ADR-0010, comprovou:

- `PUBLIC_DISCOVERY_FIXTURES: PASS` — dois Listings publicados e um Draft;
- `PUBLIC_DISCOVERY_FORM: PASS`;
- `PUBLIC_DISCOVERY_PAGINATION: PASS` — `take=1`, avanço entre os dois Listings e preservação de `query`, `take` e `skip` no link;
- `PUBLIC_DISCOVERY_QUERY: PASS`;
- `PUBLIC_DISCOVERY_PRICE: PASS`;
- `PUBLIC_DISCOVERY_CATALOG: PASS` — Brand/Model/ModelYear pelo Vehicle canônico;
- `PUBLIC_DISCOVERY_INVALID_RANGE: PASS`;
- `PUBLIC DISCOVERY HTTP: PASSED`.

No mesmo head também passaram Public Web, Public Buyer, Harness, Seller Auth, Seller Shell, Seller Draft Edit e Seller Photos Publish.

O primeiro run funcional do novo gate falhou apenas porque a asserção procurava `2 anúncio(s)` como bytes contíguos no HTML SSR; React separava a expressão dinâmica com marcador de hidratação. O gate foi corrigido para validar texto visível via parser HTML, sem relaxar o resultado esperado.

Classe da evidência: **B — comportamento reproduzido em CI contra aplicação real**.

## Progress log

- 2026-08-23: Plan 0005 selecionado após o Plan 0004 porque o backend de discovery já passava e a home pública ainda não consumia interativamente o contrato.
- 2026-08-23: `getPublicListings` passou a serializar o contrato público existente; a home Next passou a ler Query/Brand/Model/ano/preço/Skip/Take pela query string e renderizar formulário GET + paginação SSR.
- 2026-08-23: Public Discovery HTTP Gate adicionado com dois Listings publicados e um Draft para provar formulário, Query, filtros de catálogo/preço, paginação e range invertido.
- 2026-08-23: Harness apontou a ausência mecânica de `Progress log`/`Decision log`; estrutura do plano corrigida.
- 2026-08-23: primeiro run funcional do gate revelou apenas uma asserção incompatível com marcadores de hidratação do HTML SSR; a prova passou após validar texto visível via parser.
- 2026-08-23: todos os oito workflows aplicáveis ao head de produto passaram, incluindo Public Discovery e Public Buyer.
- 2026-08-23: ADR-0010 foi integrada separadamente em `main`; o run verde de discovery utilizou o merge ref sobre esse `main`, sem alterar o escopo do Plan 0005.

## Decision log

- Query string é o estado canônico da primeira experiência de discovery.
- Reutilizar exclusivamente o `PublicListingSearchInput` já existente; nenhuma expansão de filtro/backend neste plano.
- Manter SSR e URLs compartilháveis, sem estado React para filtros/paginação.
- Não introduzir ranking, sort novo, autocomplete, localização ou engine externa sem necessidade comprovada.
- Qualquer futura decisão de infraestrutura de busca segue ADR-0010.

## Resultado

**PASSA / CONCLUÍDO.** O Buyer agora percorre:

`Public Listings → busca/filtros → paginação → Public Detail → Photo → WhatsApp`

O fechamento reutilizou integralmente o contrato público existente e não adicionou novo aggregate, filtro backend, ranking ou infraestrutura.

## Gaps futuros

Ranking, ordenação, facets/autocomplete, localização e eventual engine externa só serão considerados quando necessidade de produto e evidência exigirem. Buyer account/Favorites e demais capacidades permanecem fora deste plano e devem ser priorizados por nova auditoria de menor gap real.

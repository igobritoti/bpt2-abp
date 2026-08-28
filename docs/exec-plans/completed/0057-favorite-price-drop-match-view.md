# Plan 0057 — Favorite price-drop match view

Status: **CONCLUÍDO**

## Objetivo

Fechar o gap entre o ledger `FavoritePriceDropMatch` já detectado/persistido e a experiência Buyer: permitir que o próprio usuário consulte, in-app, o histórico de quedas de preço detectadas para seus Favorites.

## Evidência de base

- `FavoritePriceDropDetector` já cria ledger por `UserId`, `ListingId`, `ListingPriceChangeId`, preço anterior, novo preço e `DetectedAtUtc`;
- `favorite-price-drop-http-smoke.sh` já provava Draft ignorado, temporal eligibility, ausência de retroativo, replay idempotente, aumento ignorado e unfavorite impedindo match futuro;
- `IFavoriteAppService` não expunha leitura do ledger;
- `/favoritos` mostrava somente Listings atualmente públicas e não mostrava histórico de price-drop;
- delivery externo permanece boundary separado.

## Boundary entregue

1. DTO de leitura sem PII e sem estado de delivery;
2. `GetPriceDropMatchesAsync()` no Favorite app service, filtrado exclusivamente pelo `ICurrentUser.Id`;
3. ordering `DetectedAtUtc` desc + `Id` como desempate determinístico;
4. prova HTTP de autenticação, isolamento entre Buyers e preservação histórica após unfavorite;
5. histórico em `/favoritos`, com preço anterior, novo preço, instante e link ao detalhe público;
6. detalhe público permanece autoridade de disponibilidade atual — histórico não significa oferta ainda pública.

## Não objetivos

- e-mail/push/SMS/WhatsApp;
- read/unread, badge global ou contador persistido;
- nova tabela/schema;
- alterar detector, temporal eligibility ou replay;
- remover histórico quando houver unfavorite/pause/archive;
- snapshot enriquecido do Listing;
- provider/canal de delivery.

## Critérios de aceite

- [x] endpoint autenticado lista apenas matches do Buyer atual;
- [x] Buyer A nunca recebe match de Buyer B;
- [x] retorno inclui `ListingId`, `PreviousPrice`, `NewPrice` e `DetectedAtUtc`;
- [x] ordering é newest-first com desempate determinístico;
- [x] histórico continua consultável após unfavorite;
- [x] `/favoritos` mostra zero-state e histórico de quedas sem confundir disponibilidade atual;
- [x] detector/schema permanecem inalterados;
- [x] Favorite Price Drop HTTP, Public Web e Harness passaram no head funcional.

## Decision log

- `PRICE_DROP_LEDGER_VISIBILITY = BUYER IN-APP`
- `PRICE_DROP_HISTORY = PRESERVADO APÓS UNFAVORITE`
- `CURRENT_LISTING_VISIBILITY = AUTORIDADE DO DETALHE PÚBLICO`
- `EXTERNAL_DELIVERY = FORA DE ESCOPO`
- `READ_STATE = NÃO INVENTAR`

## Progress log

- 2026-08-28 — `main` confirmado no merge commit `9563c6fd15813732b51fe4060c6de65f52ce2648` do Plan 0056.
- 2026-08-28 — audit confirmou ledger/detector entregues e ausência de query/UI Buyer para price-drop.
- 2026-08-28 — DTO, query ownership-safe, client/UI e smoke de leitura implementados no head funcional `31ff5e6169cd9fa4af9725724b408bad111131f3`.
- 2026-08-28 — Harness, Architecture, Host, Public Web, Fresh Migration, Gate 01 e demais gates estruturais já observados passaram; `Exercise Favorite price-drop detection over HTTP` passou provando a nova rota, isolamento e histórico após unfavorite.

## Validation

Head funcional: `31ff5e6169cd9fa4af9725724b408bad111131f3`.

Evidência focal executada:
- BPT2 Harness Gate: success;
- BPT2 Public Web Gate: success;
- BPT2 Architecture Gate: success;
- BPT2 Fresh Migration Gate: success;
- Buyer Favorites HTTP job: `Exercise Buyer Favorites over HTTP` success e `Exercise Favorite price-drop detection over HTTP` success.

O merge continua condicionado a CI fresco do head final de closeout, review/thread check e base refresh.

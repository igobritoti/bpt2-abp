# Plan 0057 — Favorite price-drop match view

Status: **ATIVO**

## Objetivo

Fechar o gap entre o ledger `FavoritePriceDropMatch` já detectado/persistido e a experiência Buyer: permitir que o próprio usuário consulte, in-app, o histórico de quedas de preço detectadas para seus Favorites.

## Evidência de base

- `FavoritePriceDropDetector` já cria ledger por `UserId`, `ListingId`, `ListingPriceChangeId`, preço anterior, novo preço e `DetectedAtUtc`;
- `favorite-price-drop-http-smoke.sh` já prova Draft ignorado, temporal eligibility, ausência de retroativo, replay idempotente, aumento ignorado e unfavorite impedindo match futuro;
- `IFavoriteAppService` ainda não expõe leitura do ledger;
- `/favoritos` mostra somente Listings atualmente públicas e não mostra histórico de price-drop;
- delivery externo permanece boundary separado.

## Boundary entregue

1. adicionar DTO de leitura sem PII e sem estado de delivery;
2. expor `GetPriceDropMatchesAsync()` no Favorite app service, filtrado exclusivamente pelo `ICurrentUser.Id`;
3. ordenar `DetectedAtUtc` desc e `Id` como desempate determinístico;
4. provar por HTTP que cada Buyer vê somente seu ledger e que histórico persiste após unfavorite;
5. expor o histórico na página `/favoritos`, com preço anterior, novo preço, instante e link ao detalhe público;
6. tratar o detalhe público como autoridade de disponibilidade atual — histórico não significa oferta ainda pública.

## Não objetivos

- e-mail/push/SMS/WhatsApp;
- read/unread, badge global ou contador persistido;
- nova tabela/schema;
- alterar detector, temporal eligibility ou replay;
- remover histórico quando houver unfavorite/pause/archive;
- snapshot enriquecido do Listing;
- provider/canal de delivery.

## Critérios de aceite

- [ ] endpoint autenticado lista apenas matches do Buyer atual;
- [ ] Buyer A nunca recebe match de Buyer B;
- [ ] retorno inclui `ListingId`, `PreviousPrice`, `NewPrice` e `DetectedAtUtc`;
- [ ] ordering é newest-first com desempate determinístico;
- [ ] histórico continua consultável após unfavorite;
- [ ] `/favoritos` mostra zero-state e histórico de quedas sem confundir disponibilidade atual;
- [ ] detector/schema permanecem inalterados;
- [ ] Favorite Price Drop HTTP Gate, Public Web Gate e Harness passam no head aplicável.

## Decision log

- `PRICE_DROP_LEDGER_VISIBILITY = BUYER IN-APP`
- `PRICE_DROP_HISTORY = PRESERVADO APÓS UNFAVORITE`
- `CURRENT_LISTING_VISIBILITY = AUTORIDADE DO DETALHE PÚBLICO`
- `EXTERNAL_DELIVERY = FORA DE ESCOPO`
- `READ_STATE = NÃO INVENTAR`

## Progress log

- 2026-08-28 — `main` confirmado no merge commit `9563c6fd15813732b51fe4060c6de65f52ce2648` do Plan 0056.
- 2026-08-28 — audit confirmou ledger/detector entregues e ausência de query/UI Buyer para price-drop.

# Plan 0051 — Favorite price-drop UoW probe

Status: ATIVO

## Objetivo

Decidir por teste se o ledger de Favorite price-drop falha porque o detector persiste via `MarketplaceDbContext` injetado diretamente fora da boundary de repositório/UoW já usada pelo restante do fluxo de aplicação.

Este slice não envia notificações, não escolhe provider/canal e não cria runner.

## Decision log

- Evidência A: PR #77 corrigiu o bug Bash do smoke, Fresh Migration passou, Favorites regressivo passou e a primeira queda esperada para uma Listing publicada já favoritada deixou o ledger vazio.
- Evidência A: no código rejeitado do PR #77, `ListingCommandService` usa repositórios ABP, enquanto `FavoritePriceDropDetector` persiste `FavoritePriceDropMatch` diretamente via `MarketplaceDbContext`.
- Evidência B/C anterior do projeto: no trigger de Saved Search, uma boundary direta de DbContext produziu comportamento transacional incorreto no probe e foi substituída por repositório ABP antes de o rollback passar.
- Hipótese falsificável: trocar apenas a leitura/escrita do detector para `IRepository<Favorite, Guid>` e `IRepository<FavoritePriceDropMatch, Guid>` fará o mesmo smoke do PR #77 passar sem mudar sua semântica.
- Se a hipótese falhar, não aplicar correções adicionais neste slice; registrar a primeira falha real e fechar sem merge.

## Critérios de aceite

- Draft decrease continua sem ledger.
- Favorite existente antes da queda recebe exatamente um match para `ListingPriceChangeId`.
- Favorite criado depois da queda não recebe match retroativo.
- Replay do mesmo `ListingPriceChange` permanece idempotente.
- Aumento de preço não cria match.
- Unfavorite antes de uma queda posterior impede novo match para aquele Buyer.
- Fresh Migration passa com a tabela/índices do ledger.
- Buyer Favorites HTTP Gate passa com o smoke de price-drop e regressões existentes.
- CI final fresco do head exato, review/thread limpos e base refresh antes de merge.

## Progress log

- 2026-08-26 — Plan aberto sobre `main` fresco após PR #77 revelar falha funcional real.

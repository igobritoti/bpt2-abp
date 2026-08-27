# Plan 0051 — Favorite price-drop repository boundary

Status: **CONCLUÍDO**

## Objetivo

Testar a hipótese de que o detector de price-drop falhou no PR #77 por usar `MarketplaceDbContext` diretamente fora do padrão de repository/UoW já comprovado no trigger de Saved Search.

## Evidência de entrada

- PR #77 corrigiu o Bash e reproduziu falha funcional: Draft decrease foi ignorado corretamente, mas o primeiro match esperado após queda publicada ficou com ledger vazio.
- O experimento do trigger de Saved Search já rejeitou `MarketplaceDbContext` direto para o boundary transacional testado e passou após mover a persistência para repository ABP.
- `BomPraTiMarketplaceModule` registra default repositories para todas as entidades do `MarketplaceDbContext`.

## Mudança entregue

- detector passou a consultar/gravar via `IRepository<Favorite, Guid>` e `IRepository<FavoritePriceDropMatch, Guid>`;
- `Favorite` passou a registrar `CreatedAtUtc`, porque replay histórico exige saber se o Favorite já existia no instante da queda;
- replay filtra Favorites por `CreatedAtUtc <= ListingPriceChange.ChangedAtUtc`;
- `ChangedAtUtc` materializado com `DateTimeKind.Unspecified` é normalizado para UTC antes da query PostgreSQL;
- fixture de replay conclui o UoW e lê o ledger em novo scope, evitando falso verde pré-commit;
- provider, delivery, scheduler e runner permaneceram fora do slice.

## Contrato congelado

- Draft decrease → nenhum ledger;
- Favorite existente antes da queda → recebe match;
- Favorite criado depois → não recebe retroativo;
- replay → idempotente;
- aumento → ignorado;
- unfavorite antes da próxima queda → não recebe match futuro.

## Critérios de aceite

- **PASSA** somente se o smoke completo passar sem relaxamento e os regressivos aplicáveis permanecerem verdes;
- a fixture de replay deve observar o estado somente depois do commit do UoW;
- merge somente com CI fresco no head exato e base/review refresh limpos.

## Fora de escopo

- delivery/provider;
- notificações externas;
- runner/background worker;
- alterações no Comparator, Podium, discovery ou market intelligence.

## Progress log

- 2026-08-27 — slice reconstruído sobre `main` `acd7efd48bc6a00baa4a9187c769a611c1303085` e PR #82 aberto em draft.
- 2026-08-27 — repository boundary corrigiu a ausência do primeiro match, mas replay pós-commit revelou criação retroativa para Favorite posterior.
- 2026-08-27 — fixture endurecida para concluir o UoW antes de observar o ledger.
- 2026-08-27 — domínio mostrou ausência de timestamp de criação em `Favorite`; `CreatedAtUtc` foi adicionado e usado como boundary temporal do replay.
- 2026-08-27 — Npgsql reproduziu `DateTimeKind.Unspecified` no replay; detector passou a normalizar `ChangedAtUtc` para UTC antes da comparação.
- 2026-08-27 — no head `3f0102dc150ca4aa7c02195aa3e09017b875f497`, o step `Exercise Favorite price-drop detection over HTTP` passou com o contrato congelado completo.

## Decision log

- 2026-08-27 — repository ABP é o boundary de persistência adotado para o detector neste slice, por evidência do próprio repo e smoke funcional.
- 2026-08-27 — replay histórico exige provenance temporal mínima do Favorite; sem `CreatedAtUtc`, o requisito de não retroatividade é impossível de decidir por dado persistido.
- 2026-08-27 — nenhum teste foi relaxado para produzir verde; mudanças de fixture aumentaram observabilidade e rigor.
- 2026-08-27 — Favorite price-drop detection fica entregue somente após CI final fresco do head documental e merge verificado em `main`.

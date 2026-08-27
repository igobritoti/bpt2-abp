# Plan 0051 — Favorite price-drop repository boundary

Status: **ATIVO**

## Objetivo

Testar a hipótese de que o detector de price-drop falhou no PR #77 por usar `MarketplaceDbContext` diretamente fora do padrão de repository/UoW já comprovado no trigger de Saved Search.

## Evidência de entrada

- PR #77 corrigiu o Bash e reproduziu falha funcional: Draft decrease foi ignorado corretamente, mas o primeiro match esperado após queda publicada ficou com ledger vazio.
- O experimento do trigger de Saved Search já rejeitou `MarketplaceDbContext` direto para o boundary transacional testado e passou após mover a persistência para repository ABP.
- `BomPraTiMarketplaceModule` registra default repositories para todas as entidades do `MarketplaceDbContext`.

A analogia é hipótese arquitetural até o smoke confirmar ou refutar neste slice.

## Mudança experimental

- reconstruir o mesmo detector/ledger e o mesmo smoke do PR #77 sobre o `main` atual;
- substituir somente leitura/gravação do detector por `IRepository<Favorite, Guid>` e `IRepository<FavoritePriceDropMatch, Guid>`;
- manter `ListingCommandService` e os cenários HTTP semanticamente iguais ao retry reprovado;
- não introduzir provider, delivery, scheduler, runner ou nova regra de produto.

## Contrato congelado

- Draft decrease → nenhum ledger;
- Favorite existente antes da queda → recebe match;
- Favorite criado depois → não recebe retroativo;
- replay → idempotente;
- aumento → ignorado;
- unfavorite antes da próxima queda → não recebe match futuro.

## Critério de decisão

- **PASSA** somente se o smoke completo passar sem relaxamento e os regressivos aplicáveis permanecerem verdes;
- **REPROVADA** a hipótese se o primeiro match continuar ausente ou surgir outra falha funcional no mesmo contrato;
- merge somente com CI fresco no head exato e base/review refresh limpos.

## Fora de escopo

- delivery/provider;
- notificações externas;
- runner/background worker;
- alterações no Comparator, Podium, discovery ou market intelligence.

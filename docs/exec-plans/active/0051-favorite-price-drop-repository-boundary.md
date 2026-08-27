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

## Critérios de aceite

- **PASSA** somente se o smoke completo passar sem relaxamento e os regressivos aplicáveis permanecerem verdes;
- **REPROVADA** a hipótese se o primeiro match continuar ausente ou surgir outra falha funcional no mesmo contrato;
- a fixture de replay deve observar o estado somente depois do commit do UoW;
- merge somente com CI fresco no head exato e base/review refresh limpos.

## Fora de escopo

- delivery/provider;
- notificações externas;
- runner/background worker;
- alterações no Comparator, Podium, discovery ou market intelligence.

## Progress log

- 2026-08-27 — slice reconstruído sobre `main` `acd7efd48bc6a00baa4a9187c769a611c1303085` e PR #82 aberto em draft.
- 2026-08-27 — primeiro CI do repository boundary avançou além da falha original: Draft ignored, existing Favorite, no retroactive immediate check e replay check passaram; falhou na leitura seguinte após aumento.
- 2026-08-27 — fixture endurecida para concluir o UoW de replay antes de abrir novo scope e ler o ledger, eliminando leitura pré-commit como falso verde possível.

## Decision log

- 2026-08-27 — manter o contrato HTTP congelado; mudanças de teste só podem aumentar observabilidade/rigor, nunca relaxar asserções.
- 2026-08-27 — não concluir que repository boundary resolve todo o detector: há evidência de que corrige a ausência do primeiro match, mas o contrato completo continua em investigação.
- 2026-08-27 — `Favorite` atualmente não registra instante de criação; qualquer correção temporal para replay exige nova evidência antes de alterar domínio.

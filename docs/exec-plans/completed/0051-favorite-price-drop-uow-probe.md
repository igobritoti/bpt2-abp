# Plan 0051 — Favorite price-drop UoW probe

Status: **CONCLUÍDO**

## Objetivo

Decidir por teste a boundary transacional e temporal mínima para detectar queda de preço de uma Listing publicada para Buyers que já a haviam favoritado, sem escolher provider/canal de notificação e sem criar runner.

## Decision log

- Evidência A/B: PR #77 corrigiu o bug Bash do smoke; Fresh Migration e Favorites regressivo passaram, mas a primeira queda esperada deixava o ledger vazio quando o detector persistia por `MarketplaceDbContext` injetado diretamente.
- Evidência A/B: trocar o detector para `IRepository<Favorite, Guid>` e `IRepository<FavoritePriceDropMatch, Guid>` fez a primeira queda persistir dentro do UoW do comando.
- Evidência B: o probe determinístico mostrou que o cenário inicialmente interpretado como “aumento criou match” continha, na verdade, um segundo row `195000.00>180000.00` para um Buyer que favoritou depois daquela queda.
- Evidência B/C: o replay usava a audiência atual de Favorites e o fixture só flushava inserts do repositório no `CompleteAsync`; por isso `REPLAY_IDEMPOTENT` havia dado falso PASS antes de o row retroativo aparecer na leitura seguinte.
- Decisão: Favorite passa a registrar `CreatedAtUtc` para novos registros; replay considera apenas Favorites com timestamp conhecido e `CreatedAtUtc <= ListingPriceChange.ChangedAtUtc`.
- Decisão: Favorite legado com timestamp desconhecido (`null`) não recebe data inventada e não é promovido retroativamente para eventos históricos.
- Evidência B: o fixture passou a fazer `uow.SaveChangesAsync()` antes de ler o ledger e a expor saída determinística `PRICE_DROP_STATE:`; isso impede que inserts staged sejam ocultados pelo próprio instrumento de teste.
- Evidência B: um `ListingPriceChange` recarregado pelo fixture chegou com `DateTime.Kind=Unspecified`; o cutoff é normalizado para UTC antes de ser usado como parâmetro PostgreSQL `timestamptz`, sem alterar o instante semântico armazenado.
- Não decidido/não entregue: provider, canal, template, scheduler, runner ou entrega de notificação. O slice produz somente o ledger de detecção.

## Critérios de aceite

- [x] Draft decrease continua sem ledger.
- [x] Favorite existente antes da queda recebe exatamente um match para `ListingPriceChangeId`.
- [x] Favorite criado depois da queda não recebe match retroativo, inclusive sob replay.
- [x] Replay do mesmo `ListingPriceChange` permanece idempotente com flush explícito do UoW antes da leitura.
- [x] Aumento de preço não cria match.
- [x] Unfavorite antes de uma queda posterior impede novo match para aquele Buyer.
- [x] Fresh Migration passa com a tabela/índices do ledger e a coluna nullable de criação do Favorite.
- [x] Buyer Favorites HTTP Gate passa com o smoke de price-drop e regressões existentes no head funcional `fe68ba43c33390c4b77a21167a7afa32b18594d7`.
- [ ] CI final fresco do closeout documental, review/thread e base refresh — executados após este checkpoint antes de merge.

## Progress log

- 2026-08-26 — Plan aberto sobre `main` fresco após PR #77 revelar falha funcional real.
- 2026-08-26 — Harness do primeiro head revelou apenas formatação não canônica de `Status`; corrigido sem alterar produto.
- 2026-08-27 — Head `fb5c92b...`: 15/16 checks verdes; Buyer Favorites expôs comportamento pós-replay que parecia aumento de preço.
- 2026-08-27 — Saída do fixture tornada determinística; o estado provou dois rows da mesma queda, não um row de aumento.
- 2026-08-27 — Root cause: Favorite tardio entrava na audiência de replay e o fixture lia antes do flush do repositório/UoW.
- 2026-08-27 — `CreatedAtUtc` nullable + filtro temporal + `uow.SaveChangesAsync()` adicionados; legacy `null` permanece desconhecido.
- 2026-08-27 — Normalização UTC do cutoff eliminou incompatibilidade Npgsql de `DateTimeKind.Unspecified`.
- 2026-08-27 — `Exercise Favorite price-drop detection over HTTP` e o Buyer Favorites gate completo passaram no head funcional `fe68ba43c33390c4b77a21167a7afa32b18594d7`.

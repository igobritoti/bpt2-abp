# Plan 0055 — Public recency sort

Status: **CONCLUÍDO**

## Objetivo

Entregar ordenação pública por recência usando uma semântica temporal canônica e não manipulável por pause/re-publish.

## Evidência de base

- `PublicListingQuery` aceitava apenas default por `Id`, `price-asc` e `price-desc`.
- `Listing` não possuía instante canônico de publicação.
- `Publish()` pode ocorrer novamente depois de `Pause()`; portanto usar o último Publish como recência permitiria bump artificial.
- o trigger durável de Saved Search é único por Listing e já representa semanticamente a primeira publicação pública.
- o baseline modular gera migrations efêmeras no Fresh Migration Gate; arquivos `Data/Migrations/Gate` não são fonte versionada.

## Semântica congelada

- `FirstPublishedAtUtc` é definido somente na primeira transição para Published.
- pause/re-publish não altera `FirstPublishedAtUtc`.
- restore após moderação não altera `FirstPublishedAtUtc`.
- registros legados sem instante permanecem `null`; nenhum backfill artificial é autorizado.
- `recent-desc` ordena primeiro Listings com timestamp conhecido, do mais novo para o mais antigo, e usa `Id` como desempate determinístico; `null` fica depois dos conhecidos.
- Sort continua fora da identidade semântica de Saved Search.

## Boundary entregue

1. `Listing.FirstPublishedAtUtc?` persistido pelo Marketplace;
2. `Publish(DateTime)` define o instante apenas se ainda não existir;
3. `ListingCommandService` usa `DateTime.UtcNow` na publicação;
4. `PublicListingQuery` suporta `Sort=recent-desc` com nulls depois dos timestamps conhecidos;
5. public web aceita/preserva `recent-desc` e mostra “Mais recentes”;
6. smoke HTTP próprio prova ordem newest-first e ausência de bump após pause/re-publish;
7. smoke roda por último no Public Discovery HTTP Gate para evitar contaminação de regressões anteriores.

## Não objetivos

- ranking/relevance;
- sponsored bump;
- backfill de Listing legado;
- data de última edição;
- data de republicação;
- persistir Sort em Saved Search;
- job/background worker;
- engine externa.

## Critérios de aceite

- [x] primeira publicação grava instante UTC conhecido;
- [x] segunda publicação após Pause preserva o mesmo instante;
- [x] `recent-desc` retorna publicação mais nova antes da mais antiga;
- [x] pause/re-publish não promove artificialmente a Listing mais antiga;
- [x] registros sem timestamp não recebem valor inventado;
- [x] public web aceita/preserva `sort=recent-desc` e mostra “Mais recentes”;
- [x] price sorts e regressões anteriores do Public Discovery continuam verdes no head funcional;
- [x] Fresh Migration, Public Discovery, Public Web e Harness passaram no head funcional `c581ab8bee25efeb61e0b3ba8dbeb9584156486d`.

## Evidência executada

Head funcional: `c581ab8bee25efeb61e0b3ba8dbeb9584156486d`.

- **BPT2 Fresh Migration Gate**: success.
- **BPT2 Public Web Gate**: success.
- **BPT2 Harness Gate**: success.
- **BPT2 Architecture Gate**: success.
- **BPT2 Public Discovery HTTP Gate**: success.

No Public Discovery Gate, passaram no mesmo banco fresco e head:

- canonical Vehicle search;
- public discovery baseline;
- price sort;
- color filter;
- Saved Search color semantics;
- sponsored Listing contract;
- `Exercise public recency sort over HTTP`.

O smoke de recência prova especificamente:

`Older first publish → Newer first publish → recent-desc = Newer, Older → Pause Older → Republish Older → recent-desc continua Newer, Older`

Durante a primeira execução, múltiplos gates falharam no shared fixture porque `alert-trigger-rollback` ainda chamava a assinatura antiga `listing.Publish()`. Fresh Migration havia passado, isolando o problema como caller de fixture. O fixture foi corrigido para `listing.Publish(DateTime.UtcNow)`; o novo head voltou a passar Lifecycle, Listing Photo, Gate 01 e demais regressões já concluídas observadas.

## Decision log

- `RECENCY_SEMANTICS = FIRST_PUBLICATION`
- `REPUBLISH_BUMP = PROIBIDO`
- `LEGACY_BACKFILL = PROIBIDO SEM EVIDÊNCIA`
- `NULL_RECENCY = DEPOIS DOS TIMESTAMPS CONHECIDOS`
- `SAVED_SEARCH_SORT_IDENTITY = FORA DE ESCOPO / INALTERADO`
- `VERSIONED_MODULE_MIGRATION = NÃO NECESSÁRIA NO BASELINE ATUAL`; Fresh Migration gera a migration efêmera do módulo e provou o schema em PostgreSQL fresco.

## Progress log

- 2026-08-27 — `main` confirmado em `4872de87a78969d2649049b6040014fa39371d1d` após merge do audit de attribution.
- 2026-08-27 — domínio e query auditados: não existia timestamp de publicação; `Publish()` permite republicação após Pause.
- 2026-08-27 — política de migrations confirmada em `docs/LOCAL-DEVELOPMENT.md`: migrations de módulos são geradas efemeramente pelo Fresh Migration Gate.
- 2026-08-27 — `FirstPublishedAtUtc?`, `recent-desc`, UI e smoke implementados.
- 2026-08-27 — primeira rodada encontrou caller antigo no shared fixture; corrigido sem adicionar overload ou relaxar o contrato do domínio.
- 2026-08-27 — head funcional `c581ab8...` comprovou Fresh Migration, Public Web e Public Discovery, incluindo o smoke de no-bump.

## Resultado

**PASSA / CONCLUÍDO funcionalmente.** A ordenação pública por recência agora possui uma semântica persistida, reproduzível e resistente a bump por republicação. O closeout documental exige CI fresco no head final antes do merge do PR.

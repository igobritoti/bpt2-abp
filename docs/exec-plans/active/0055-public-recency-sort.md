# Plan 0055 — Public recency sort

Status: **ATIVO**

## Objetivo

Entregar ordenação pública por recência usando uma semântica temporal canônica e não manipulável por pause/re-publish.

## Evidência de base

- `PublicListingQuery` hoje aceita apenas default por `Id`, `price-asc` e `price-desc`.
- `Listing` não possui instante canônico de publicação.
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

## Escopo

1. persistir `Listing.FirstPublishedAtUtc?` no domínio Marketplace;
2. setar o timestamp apenas na primeira publicação;
3. suportar `Sort=recent-desc` no public query;
4. expor “Mais recentes” no public web e preservar query string/paginação;
5. criar smoke HTTP específico provando ordem e ausência de bump após pause/re-publish;
6. ligar o smoke ao Public Discovery HTTP Gate.

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

- [ ] primeira publicação grava instante UTC conhecido;
- [ ] segunda publicação após Pause preserva o mesmo instante;
- [ ] `recent-desc` retorna publicação mais nova antes da mais antiga;
- [ ] pause/re-publish não promove artificialmente a Listing mais antiga;
- [ ] registros sem timestamp não recebem valor inventado;
- [ ] public web aceita/preserva `sort=recent-desc` e mostra “Mais recentes”;
- [ ] price sorts e default continuam sem regressão;
- [ ] Fresh Migration, Public Discovery, Public Web e Harness passam no head final.

## Decision log

- `RECENCY_SEMANTICS = FIRST_PUBLICATION`
- `REPUBLISH_BUMP = PROIBIDO`
- `LEGACY_BACKFILL = PROIBIDO SEM EVIDÊNCIA`
- `NULL_RECENCY = DEPOIS DOS TIMESTAMPS CONHECIDOS`
- `SAVED_SEARCH_SORT_IDENTITY = FORA DE ESCOPO / INALTERADO`

## Progress log

- 2026-08-27 — `main` confirmado em `4872de87a78969d2649049b6040014fa39371d1d` após merge do audit de attribution.
- 2026-08-27 — domínio e query auditados: não existe timestamp de publicação; `Publish()` permite republicação após Pause.
- 2026-08-27 — política de migrations confirmada em `docs/LOCAL-DEVELOPMENT.md`: migrations de módulos são geradas efemeramente pelo Fresh Migration Gate.

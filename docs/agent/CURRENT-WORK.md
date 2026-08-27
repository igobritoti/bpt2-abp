# Current work

Last verified: **2026-08-27**

Este arquivo é um snapshot curto do trabalho corrente. Não é histórico, changelog nem inventário de CI.

## Active outcome

Testar em slice próprio a hipótese de persistence/UoW do detector de Favorite price-drop após a falha funcional reproduzível do PR #77.

O contrato permanece congelado: Draft decrease não cria ledger; Favorite já existente antes da queda recebe match; Favorite posterior não recebe retroativo; replay é idempotente; aumento é ignorado; unfavorite impede match futuro.

## Active plan

[`../exec-plans/active/0051-favorite-price-drop-repository-boundary.md`](../exec-plans/active/0051-favorite-price-drop-repository-boundary.md)

## Acceptance target

- reconstruir o slice do PR #77 sobre o `main` atual;
- trocar somente o detector de `MarketplaceDbContext` direto para repositories ABP;
- não alterar o smoke para fazê-lo passar;
- manter provider, delivery, scheduler e runner fora do slice;
- decidir por CI do head exato;
- merge somente verde e após base/review refresh.

## Próximos gatilhos independentes

- enrichment técnico publicado do Podium suficiente para Comparator;
- deployment/locking reproduzível para claim/retry/restart do runner de Saved Search;
- corpus + baseline + métrica para discovery avançado;
- dataset/licença/metodologia/provenance para inteligência de mercado;
- evidência operacional suficiente para trust/moderação avançada;
- tese comercial/parceria concreta para complementares;
- inventário atual reproduzível do Carros na Web.

## Source of runtime truth

- Estado de branch/PR/checks: Git e GitHub Actions do commit corrente.
- Produto: [`../PRODUCT.md`](../PRODUCT.md).
- Fatos derivados: [`../generated/repository-facts.md`](../generated/repository-facts.md).
- Decisões: [`../MDV.md`](../MDV.md) e [`../adr/`](../adr/).
- Roadmap concluído: [`../exec-plans/completed/0049-post-mvp-capability-completion.md`](../exec-plans/completed/0049-post-mvp-capability-completion.md).
- Checkpoint anterior: [`../audits/2026-08-26-post-plan0050-trigger-sweep.md`](../audits/2026-08-26-post-plan0050-trigger-sweep.md).

## Open blockers

- Favorite price-drop: em probe Plan 0051; PR #77 provou primeiro ledger esperado vazio com DbContext direto.
- Comparator: enrichment técnico publicado suficiente do Podium.
- Saved Search runner: sem distributed-lock provider/configuração e sem deployment contract cross-instance.
- Discovery avançado: sem corpus/baseline/métrica.
- Inteligência de mercado: sem dataset/licença/metodologia/provenance.
- Carros na Web: inventário público atual ainda não reproduzível; acesso direto continua falhando.

## Update rule

Atualize este snapshot somente quando mudar outcome, plano, acceptance target ou blocker real.

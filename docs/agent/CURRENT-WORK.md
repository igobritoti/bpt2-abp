# Current work

Last verified: **2026-08-27**

Este arquivo é um snapshot curto do trabalho corrente. Não é histórico, changelog nem inventário de CI.

## Active outcome

Nenhum execution plan funcional está ativo.

O Plan 0051 fechou o probe de Favorite price-drop. O detector passou o contrato congelado completo após três achados encadeados: repository ABP corrigiu a ausência do primeiro match; replay pós-commit revelou necessidade de provenance temporal do Favorite; `CreatedAtUtc` + normalização UTC de `ListingPriceChange.ChangedAtUtc` eliminaram retroatividade e preservaram idempotência no smoke.

## Active plan

**Nenhum.**

## Próximos gatilhos independentes

- deployment/locking reproduzível para claim/retry/restart do runner de Saved Search;
- enrichment técnico publicado do Podium suficiente para Comparator;
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
- Price-drop concluído: [`../exec-plans/completed/0051-favorite-price-drop-repository-boundary.md`](../exec-plans/completed/0051-favorite-price-drop-repository-boundary.md).
- Checkpoint anterior: [`../audits/2026-08-26-post-plan0050-trigger-sweep.md`](../audits/2026-08-26-post-plan0050-trigger-sweep.md).

## Open blockers

- Saved Search runner: sem distributed-lock provider/configuração e sem deployment contract cross-instance.
- Comparator: enrichment técnico publicado suficiente do Podium.
- Discovery avançado: sem corpus/baseline/métrica.
- Inteligência de mercado: sem dataset/licença/metodologia/provenance.
- Carros na Web: inventário público atual ainda não reproduzível; acesso direto continua falhando.

## Update rule

Atualize este snapshot somente quando mudar outcome, plano, acceptance target ou blocker real.

# Current work

Last verified: **2026-08-26**

Este arquivo é um snapshot curto do trabalho corrente. Não é histórico, changelog nem inventário de CI.

## Active outcome

Nenhum execution plan funcional está ativo.

O Plan 0049 foi encerrado por classificação. O retry de Favorite price-drop do PR #77 corrigiu o bug mecânico do smoke do PR #75, mas então revelou falha funcional reproduzível: Draft ignore passa, porém o primeiro match esperado para uma Listing publicada já favoritada permanece com ledger vazio. O PR #77 foi fechado sem merge.

Checkpoint atual: [`../audits/2026-08-26-post-plan0050-trigger-sweep.md`](../audits/2026-08-26-post-plan0050-trigger-sweep.md).

## Active plan

**Nenhum.**

## Próximos gatilhos de reabertura

- probe focado para a persistência/UoW do detector de Favorite price-drop;
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
- Checkpoint atual: [`../audits/2026-08-26-post-plan0050-trigger-sweep.md`](../audits/2026-08-26-post-plan0050-trigger-sweep.md).

## Open blockers

- Favorite price-drop: falha funcional reproduzida no PR #77; primeiro ledger esperado fica vazio.
- Comparator: enrichment técnico publicado suficiente do Podium.
- Saved Search runner: sem distributed-lock provider/configuração e sem deployment contract cross-instance.
- Discovery avançado: sem corpus/baseline/métrica.
- Inteligência de mercado: sem dataset/licença/metodologia/provenance.
- Carros na Web: inventário público atual ainda não reproduzível; acesso direto continua falhando.

## Update rule

Atualize este snapshot somente quando mudar outcome, plano, acceptance target ou blocker real.

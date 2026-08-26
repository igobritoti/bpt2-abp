# Current work

Last verified: **2026-08-26**

Este arquivo é um snapshot curto do trabalho corrente. Não é histórico, changelog nem inventário de CI.

## Active outcome

Validar em slice próprio o detector de price-drop de Favorites que foi fechado sem merge no PR #75 após uma falha mecânica do smoke Bash antes de o contrato funcional ser exercitado.

O retry não altera domínio por hipótese: primeiro corrige somente a inicialização de variáveis locais sob `set -u` e reroda o mesmo contrato. Se o comportamento funcional falhar depois disso, a falha passa a ser evidência de produto e o slice deve ser reavaliado sem mascarar o resultado.

## Active plan

[`../exec-plans/active/0050-favorite-price-drop-retry.md`](../exec-plans/active/0050-favorite-price-drop-retry.md)

## Acceptance target

- smoke Bash passa syntax;
- Fresh Migration permanece verde;
- Buyer Favorites regressivo permanece verde;
- Favorite price-drop prova Draft ignored, existing Favorite, no retroactive match, replay idempotent, increase ignored e unfavorite stops future match;
- nenhum provider, delivery, scheduler ou runner entra neste slice;
- merge somente com CI fresco no head exato e review/base refresh limpos.

## Source of runtime truth

- Estado de branch/PR/checks: Git e GitHub Actions do commit corrente.
- Produto e escopo consolidado: [`../PRODUCT.md`](../PRODUCT.md).
- Fatos estruturais/versões/counters derivados: [`../generated/repository-facts.md`](../generated/repository-facts.md).
- Decisões congeladas: [`../MDV.md`](../MDV.md) e [`../adr/`](../adr/).
- Plano ativo: [`../exec-plans/active/0050-favorite-price-drop-retry.md`](../exec-plans/active/0050-favorite-price-drop-retry.md).
- Último roadmap concluído: [`../exec-plans/completed/0049-post-mvp-capability-completion.md`](../exec-plans/completed/0049-post-mvp-capability-completion.md).
- Meta Carros na Web: [`../strategy/2026-08-25-carros-na-web-functional-coverage-goal.md`](../strategy/2026-08-25-carros-na-web-functional-coverage-goal.md).

Não copie SHAs, número de testes/checks ou “runtime ready” para este arquivo; consulte as fontes executáveis quando a tarefa depender deles.

## Open blockers

- Comparator: enrichment técnico publicado suficiente do Podium.
- Saved Search runner: claim/concurrency, retry e restart ainda não decididos por teste seguro.
- Favorite price-drop: em retry no Plan 0050; a única falha observada no PR #75 foi mecânica do smoke.
- Inteligência de mercado: dataset/licença/metodologia/provenance.
- Carros na Web: inventário público atual ainda não reproduzível.

## Update rule

Atualize este snapshot somente quando mudar o outcome ativo, plano ativo, próximo acceptance target ou blocker real. História vai para execution plan concluído/ADR, não para baixo deste arquivo.

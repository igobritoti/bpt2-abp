# Current work

Last verified: **2026-08-27**

Este arquivo é um snapshot curto do trabalho corrente. Não é histórico, changelog nem inventário de CI.

## Active outcome

Nenhum execution plan funcional está ativo.

O Plan 0051 fechou a boundary de detecção de queda de preço para Favorites: a primeira queda de uma Listing publicada produz ledger para Buyers que já haviam favoritado; replay é idempotente e temporalmente seguro; Favorite tardio não recebe queda histórica; aumento é ignorado; unfavorite impede somente eventos futuros.

A detecção permanece separada de delivery. Provider, canal, template, scheduler e runner não foram escolhidos nem entregues.

## Active plan

**Nenhum.**

O último plano concluído é [`../exec-plans/completed/0051-favorite-price-drop-uow-probe.md`](../exec-plans/completed/0051-favorite-price-drop-uow-probe.md).

## Próximos gatilhos de reabertura

Abrir novo plano somente quando houver evidência suficiente para uma boundary ainda não resolvida, por exemplo:

- contrato reproduzível de claim/concurrency/retry/restart para o runner de Saved Search;
- decisão de delivery/provider/privacy para alertas de Saved Search ou Favorite price-drop;
- enrichment técnico publicado do Podium suficiente para destravar o consumo BPT2/Comparador;
- corpus + baseline + métrica para discovery avançado;
- dataset/licença/metodologia/provenance para inteligência de mercado;
- provider/privacy/legal ou problema operacional observado para trust/moderação avançada;
- tese comercial/parceria concreta para Compra Assistida, financiamento, seguros, credits/payments;
- inventário atual reproduzível do Carros na Web para cálculo de cobertura.

## Source of runtime truth

- Estado de branch/PR/checks: Git e GitHub Actions do commit corrente.
- Produto: [`../PRODUCT.md`](../PRODUCT.md).
- Fatos derivados: [`../generated/repository-facts.md`](../generated/repository-facts.md).
- Decisões: [`../MDV.md`](../MDV.md) e [`../adr/`](../adr/).
- Último plano concluído: [`../exec-plans/completed/0051-favorite-price-drop-uow-probe.md`](../exec-plans/completed/0051-favorite-price-drop-uow-probe.md).
- Roadmap classificado: [`../exec-plans/completed/0049-post-mvp-capability-completion.md`](../exec-plans/completed/0049-post-mvp-capability-completion.md).

## Open blockers

- Alert delivery: nenhum provider/canal/runner foi decidido; o ledger de price-drop não equivale a notificação entregue.
- Comparator: enrichment técnico publicado suficiente do Podium.
- Saved Search runner: sem distributed-lock provider/configuração e sem deployment contract cross-instance.
- Discovery avançado: sem corpus/baseline/métrica.
- Inteligência de mercado: sem dataset/licença/metodologia/provenance.
- Carros na Web: inventário público atual ainda não reproduzível.

## Update rule

Atualize este snapshot somente quando mudar outcome, plano, acceptance target ou blocker real.

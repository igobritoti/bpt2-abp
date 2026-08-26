# Current work

Last verified: **2026-08-26**

Este arquivo é um snapshot curto do trabalho corrente. Não é histórico, changelog nem inventário de CI.

## Active outcome

Nenhum execution plan funcional está ativo.

O Plan 0049 foi encerrado por classificação após percorrer todos os blocos A–H. Nenhum bloco restante possui simultaneamente precondições suficientes, contrato falsificável e ausência de blocker para ser promovido sem inventar requisito, provider, dataset ou infraestrutura.

## Active plan

**Nenhum.**

O último plano concluído é [`../exec-plans/completed/0049-post-mvp-capability-completion.md`](../exec-plans/completed/0049-post-mvp-capability-completion.md).

## Próximos gatilhos de reabertura

Abrir um novo plano somente quando houver nova evidência suficiente em pelo menos um destes pontos:

- enrichment técnico publicado do Podium suficiente para destravar o contrato de consumo BPT2/Comparador;
- decisão reproduzível de claim/concurrency/retry/restart para o runner de Saved Search;
- correção futura, em slice próprio, do detector de price-drop que falhou no PR #75;
- corpus + baseline + métrica para discovery avançado;
- dataset/licença/metodologia/provenance para inteligência de mercado;
- provider/privacy/legal ou problema operacional observado para trust/moderação avançada;
- tese comercial/parceria concreta para Compra Assistida, financiamento, seguros, credits/payments;
- inventário atual reproduzível do Carros na Web para cálculo de cobertura.

## Source of runtime truth

- Estado de branch/PR/checks: Git e GitHub Actions do commit corrente.
- Produto e escopo consolidado: [`../PRODUCT.md`](../PRODUCT.md).
- Fatos estruturais/versões/counters derivados: [`../generated/repository-facts.md`](../generated/repository-facts.md).
- Decisões congeladas: [`../MDV.md`](../MDV.md) e [`../adr/`](../adr/).
- Último plano concluído: [`../exec-plans/completed/0049-post-mvp-capability-completion.md`](../exec-plans/completed/0049-post-mvp-capability-completion.md).
- Meta Carros na Web: [`../strategy/2026-08-25-carros-na-web-functional-coverage-goal.md`](../strategy/2026-08-25-carros-na-web-functional-coverage-goal.md).
- Boundary Podium 7: [`../adr/0011-podium7-catalog-integration-boundary.md`](../adr/0011-podium7-catalog-integration-boundary.md).

Não copie SHAs, número de testes/checks ou “runtime ready” para este arquivo; consulte as fontes executáveis quando a tarefa depender deles.

## Open blockers

- Comparator: enrichment técnico publicado suficiente do Podium.
- Saved Search runner: claim/concurrency, retry e restart ainda não decididos por teste seguro.
- Favorite price-drop detector: PR #75 fechado sem merge após falha no smoke específico.
- Inteligência de mercado: dataset/licença/metodologia/provenance.
- Carros na Web: inventário público atual ainda não reproduzível.

## Update rule

Atualize este snapshot somente quando mudar o outcome ativo, plano ativo, próximo acceptance target ou blocker real. História vai para execution plan concluído/ADR, não para baixo deste arquivo.

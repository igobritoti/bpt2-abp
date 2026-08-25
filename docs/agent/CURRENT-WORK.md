# Current work

Last verified: **2026-08-25**

Este arquivo é um snapshot curto do trabalho corrente. Não é histórico, changelog nem inventário de CI.

## Active outcome

Concluir progressivamente as capabilities restantes do Bom Pra Ti a partir do estado entregue, da matriz BPT1 → BPT2 e de benchmarks externos, sem reabrir decisões de arquitetura secundárias que não bloqueiam produto.

O Podium 7 está reconhecido como knowledge producer/alimentador do catálogo. O BPT2 continua owner do catálogo publicado. A topologia de repositório e eventual convergência Python→.NET estão **adiadas** até os triggers mensuráveis da ADR-0011.

A meta estratégica adicional é atingir pelo menos **90% das capabilities úteis/elegíveis do Carros na Web**, mirando 100% quando custo, dados, licenças, risco e valor justificarem.

## Active plan

[`../exec-plans/active/0049-post-mvp-capability-completion.md`](../exec-plans/active/0049-post-mvp-capability-completion.md)

## Acceptance target

O Plan 0049 deve primeiro atualizar a matriz restante após Lead closing + boundary Podium e selecionar **um único próximo slice** por dependência/valor.

Prioridade técnica atual:

1. provar o menor contrato de publication mapping/enrichment Podium → BPT2;
2. usar esse enrichment para destravar o Comparador 2–4 quando suficiente;
3. se houver blocker externo no mapping, avançar para gap independente seguro da matriz.

O inventário Carros na Web é uma trilha paralela e não interrompe um slice ativo sem evidência de blocker material.

## Source of runtime truth

- Estado de branch/PR/checks: Git e GitHub Actions do commit corrente.
- Produto e escopo consolidado: [`../PRODUCT.md`](../PRODUCT.md).
- Fatos estruturais/versões/counters derivados: [`../generated/repository-facts.md`](../generated/repository-facts.md).
- Decisões congeladas: [`../MDV.md`](../MDV.md) e [`../adr/`](../adr/).
- Plano ativo: [`../exec-plans/active/0049-post-mvp-capability-completion.md`](../exec-plans/active/0049-post-mvp-capability-completion.md).
- Meta Carros na Web: [`../strategy/2026-08-25-carros-na-web-functional-coverage-goal.md`](../strategy/2026-08-25-carros-na-web-functional-coverage-goal.md).
- Boundary Podium 7 concluída: [`../exec-plans/completed/0048-pbev-reconciliation-experiment.md`](../exec-plans/completed/0048-pbev-reconciliation-experiment.md).
- Auditoria monorepo/convergência: [`../audits/2026-08-25-podium7-monorepo-convergence-measurement.md`](../audits/2026-08-25-podium7-monorepo-convergence-measurement.md).
- Minimal Lead closing concluído: [`../exec-plans/completed/0047-minimal-lead-closing.md`](../exec-plans/completed/0047-minimal-lead-closing.md).
- Roadmap BPT1 → BPT2 concluído: [`../exec-plans/completed/0046-bpt1-capability-roadmap-audit.md`](../exec-plans/completed/0046-bpt1-capability-roadmap-audit.md).

Não copie SHAs, número de testes/checks ou “runtime ready” para este arquivo; consulte as fontes executáveis quando a tarefa depender deles.

## Open blockers

Nenhum blocker funcional externo conhecido.

A aquisição/reconciliation automotiva pertence ao Podium 7 e não deve ser duplicada no BPT2. A pesquisa pública do Carros na Web ainda não forneceu inventário atual reproduzível suficiente; isso bloqueia apenas o cálculo de cobertura do benchmark, não o desenvolvimento normal do BPT2.

## Update rule

Atualize este snapshot somente quando mudar o outcome ativo, plano ativo, próximo acceptance target ou blocker real. História vai para execution plan concluído/ADR, não para baixo deste arquivo.

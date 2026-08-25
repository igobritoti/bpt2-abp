# Current work

Last verified: **2026-08-25**

Este arquivo é um snapshot curto do trabalho corrente. Não é histórico, changelog nem inventário de CI.

## Active outcome

Nenhum execution plan está ativo.

O Plan 0048 concluiu a decisão de boundary Podium 7 ↔ BPT2: os projetos permanecem separados e a integração inicial será assíncrona por contrato versionado. A decisão está registrada em [`../adr/0011-podium7-catalog-integration-boundary.md`](../adr/0011-podium7-catalog-integration-boundary.md).

O próximo boundary funcional, ainda **não aberto como plano**, é o menor slice BPT2 de publication mapping do Podium: external canonical ID, redirects históricos, cardinalidade zero/um/muitos `VehicleId`, contract version e replay idempotente contra persistência real.

Comparador continua bloqueado até existir catálogo/enrichment publicado suficiente.

## Active plan

Nenhum.

## Acceptance target

Não há acceptance target ativo até a abertura do próximo execution plan.

Quando promovido, o próximo slice deve provar com o fixture Podium `2.0` já congelado que a persistência BPT2:

- não duplica replay;
- preserva correção sob o mesmo Podium ID;
- representa model-year 1:N explicitamente;
- processa `redirectsFrom` sem recriar duplicatas;
- não compara labels para resolver identidade;
- continua sem shared database ou dependência síncrona do Podium.

## Source of runtime truth

- Estado de branch/PR/checks: Git e GitHub Actions do commit corrente.
- Produto e escopo consolidado: [`../PRODUCT.md`](../PRODUCT.md).
- Fatos estruturais/versões/counters derivados: [`../generated/repository-facts.md`](../generated/repository-facts.md).
- Decisões congeladas: [`../MDV.md`](../MDV.md) e [`../adr/`](../adr/).
- Boundary Podium 7 concluída: [`../exec-plans/completed/0048-pbev-reconciliation-experiment.md`](../exec-plans/completed/0048-pbev-reconciliation-experiment.md).
- Auditoria da integração: [`../audits/2026-08-25-podium7-integration-boundary.md`](../audits/2026-08-25-podium7-integration-boundary.md).
- Minimal Lead closing concluído: [`../exec-plans/completed/0047-minimal-lead-closing.md`](../exec-plans/completed/0047-minimal-lead-closing.md).
- Roadmap BPT1 → BPT2 concluído: [`../exec-plans/completed/0046-bpt1-capability-roadmap-audit.md`](../exec-plans/completed/0046-bpt1-capability-roadmap-audit.md).

Não copie SHAs, número de testes/checks ou “runtime ready” para este arquivo; consulte as fontes executáveis quando a tarefa depender deles.

## Open blockers

Nenhum blocker funcional externo.

A aquisição direta do CSV PBEV deixou de ser blocker do BPT2 porque acquisition/reconciliation pertence ao Podium 7 pela boundary decidida. Qualquer problema de aquisição dessa fonte deve ser resolvido no contexto Podium, sem duplicar a pipeline no BPT2.

## Update rule

Atualize este snapshot somente quando mudar o outcome ativo, plano ativo, próximo acceptance target ou blocker real. História vai para execution plan concluído/ADR, não para baixo deste arquivo.

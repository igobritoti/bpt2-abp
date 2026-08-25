# Current work

Last verified: **2026-08-25**

Este arquivo é um snapshot curto do trabalho corrente. Não é histórico, changelog nem inventário de CI.

## Active outcome

Os blockers funcionais do MVP continuam fechados. O Plan 0047 concluiu o **fechamento mínimo de Lead** promovido pelo roadmap, com outcome `Won/Lost`, ownership server-side e idempotência, sem copiar o pipeline de cinco estados do BPT1.

O PR #67 está em fechamento: resta somente CI final fresco no head documental, review/base refresh e merge somente verde.

## Active plan

Nenhum execution plan ativo.

## Next acceptance target

Após integrar o PR #67 e refetch de `main`, o próximo boundary de investigação definido pela matriz do Plan 0046 é **Vehicle Enrichment — experimento de reconciliation PBEV**.

Isso ainda não autoriza implementação de Comparador nem ingestão automática. O próximo plano deve primeiro provar uma reconciliação segura entre a granularidade oficial `Marca/Modelo/Versão` e a identidade canônica do BPT2, sem inventar `ModelYear` ausente na fonte.

## Source of runtime truth

- Estado de branch/PR/checks: Git e GitHub Actions do commit corrente.
- Produto e escopo consolidado: [`../PRODUCT.md`](../PRODUCT.md).
- Fatos estruturais/versões/counters derivados: [`../generated/repository-facts.md`](../generated/repository-facts.md).
- Decisões congeladas: [`../MDV.md`](../MDV.md) e [`../adr/`](../adr/).
- Minimal Lead closing concluído: [`../exec-plans/completed/0047-minimal-lead-closing.md`](../exec-plans/completed/0047-minimal-lead-closing.md).
- Roadmap BPT1 → BPT2 concluído: [`../exec-plans/completed/0046-bpt1-capability-roadmap-audit.md`](../exec-plans/completed/0046-bpt1-capability-roadmap-audit.md).
- Matriz final da auditoria: [`../audits/2026-08-25-capability-final-decision-matrix.md`](../audits/2026-08-25-capability-final-decision-matrix.md).

Não copie SHAs, número de testes/checks ou “runtime ready” para este arquivo; consulte as fontes executáveis quando a tarefa depender deles.

## Open blockers

Nenhum blocker funcional conhecido. O PR #67 depende apenas dos gates finais do head corrente antes de review/merge.

## Update rule

Atualize este snapshot somente quando mudar o outcome ativo, plano ativo, próximo acceptance target ou blocker real. História vai para execution plan concluído/ADR, não para baixo deste arquivo.

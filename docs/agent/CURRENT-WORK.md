# Current work

Last verified: **2026-08-25**

Este arquivo é um snapshot curto do trabalho corrente. Não é histórico, changelog nem inventário de CI.

## Active outcome

Os blockers funcionais do MVP identificados no Plan 0027 continuam fechados. O Plan 0046 concluiu a auditoria BPT1 → BPT2 e foi arquivado em `exec-plans/completed/`.

A auditoria promoveu uma única próxima capability: **CRM — fechamento mínimo de Lead**, preservando `MarkContacted` e acrescentando apenas fechamento com outcome `Won/Lost`, sem copiar o pipeline de cinco estados do BPT1.

Esse próximo slice ainda não está ativo neste branch: primeiro o PR de auditoria precisa ser integrado e `main` refetched. Depois deve receber execution plan próprio a partir do novo head de `main`.

## Active plan

Nenhum execution plan ativo.

## Source of runtime truth

- Estado de branch/PR/checks: Git e GitHub Actions do commit corrente.
- Produto e escopo consolidado: [`../PRODUCT.md`](../PRODUCT.md).
- Fatos estruturais/versões/counters derivados: [`../generated/repository-facts.md`](../generated/repository-facts.md).
- Decisões congeladas: [`../MDV.md`](../MDV.md) e [`../adr/`](../adr/).
- Roadmap BPT1 → BPT2 concluído: [`../exec-plans/completed/0046-bpt1-capability-roadmap-audit.md`](../exec-plans/completed/0046-bpt1-capability-roadmap-audit.md).
- Matriz final da auditoria: [`../audits/2026-08-25-capability-final-decision-matrix.md`](../audits/2026-08-25-capability-final-decision-matrix.md).
- Auditoria de prontidão do MVP: [`../exec-plans/completed/0027-mvp-readiness-audit.md`](../exec-plans/completed/0027-mvp-readiness-audit.md).
- Public Hub Social Images: [`../exec-plans/completed/0045-public-hub-social-images.md`](../exec-plans/completed/0045-public-hub-social-images.md).

Não copie SHAs, número de testes/checks ou “runtime ready” para este arquivo; consulte as fontes executáveis quando a tarefa depender deles.

## Open blockers

Nenhum blocker funcional aberto. O próximo slice CRM é uma promoção por evidência do roadmap, não correção de blocker do MVP.

## Update rule

Atualize este snapshot somente quando mudar o outcome ativo, plano ativo, próximo acceptance target ou blocker real. História vai para execution plan concluído/ADR, não para baixo deste arquivo.

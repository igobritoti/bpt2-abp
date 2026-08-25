# Current work

Last verified: **2026-08-25**

Este arquivo é um snapshot curto do trabalho corrente. Não é histórico, changelog nem inventário de CI.

## Active outcome

Executar o experimento de **Vehicle Enrichment — reconciliation PBEV** definido pela matriz do Plan 0046, sem implementar Comparador e sem importar dados em produção antes de provar uma reconciliação segura.

O PR #67 de fechamento mínimo de Lead foi integrado. O experimento atual parte do `main` em `1471de8f69d0216f09d6c42c57a2ccbba900b2d7` e está no draft PR #68.

## Active plan

[`../exec-plans/active/0048-pbev-reconciliation-experiment.md`](../exec-plans/active/0048-pbev-reconciliation-experiment.md)

## Acceptance target

Provar ou refutar, com amostra reproduzível, se registros PBEV podem ser reconciliados deterministicamente à identidade canônica BPT2:

- sem inventar `ModelYear`;
- distinguindo `exact`, `normalized`, `ambiguous` e `unmatched`;
- preservando source/revision/provenance do artefato oficial;
- rejeitando ambiguidades em vez de resolvê-las por fuzzy opaco;
- decidindo por evidência se o target correto é `VehicleVersion`, `Vehicle`, observação independente ou combinação.

Comparador permanece bloqueado até o enrichment mínimo ser provado.

## Source of runtime truth

- Estado de branch/PR/checks: Git e GitHub Actions do commit corrente.
- Produto e escopo consolidado: [`../PRODUCT.md`](../PRODUCT.md).
- Fatos estruturais/versões/counters derivados: [`../generated/repository-facts.md`](../generated/repository-facts.md).
- Decisões congeladas: [`../MDV.md`](../MDV.md) e [`../adr/`](../adr/).
- Plano ativo: [`../exec-plans/active/0048-pbev-reconciliation-experiment.md`](../exec-plans/active/0048-pbev-reconciliation-experiment.md).
- Minimal Lead closing concluído: [`../exec-plans/completed/0047-minimal-lead-closing.md`](../exec-plans/completed/0047-minimal-lead-closing.md).
- Roadmap BPT1 → BPT2 concluído: [`../exec-plans/completed/0046-bpt1-capability-roadmap-audit.md`](../exec-plans/completed/0046-bpt1-capability-roadmap-audit.md).
- Matriz final da auditoria: [`../audits/2026-08-25-capability-final-decision-matrix.md`](../audits/2026-08-25-capability-final-decision-matrix.md).

Não copie SHAs, número de testes/checks ou “runtime ready” para este arquivo; consulte as fontes executáveis quando a tarefa depender deles.

## Open blockers

Nenhum blocker funcional externo. A aquisição direta do CSV anunciado pelo Inmetro/dados.gov.br ainda não foi resolvida pelo navegador atual; o schema oficial do artefato PBEV foi congelado pelo PDF oficial e a indisponibilidade do recurso CSV permanece explícita, sem fallback heurístico.

## Update rule

Atualize este snapshot somente quando mudar o outcome ativo, plano ativo, próximo acceptance target ou blocker real. História vai para execution plan concluído/ADR, não para baixo deste arquivo.

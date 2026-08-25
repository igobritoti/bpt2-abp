# Current work

Last verified: **2026-08-25**

Este arquivo é um snapshot curto do trabalho corrente. Não é histórico, changelog nem inventário de CI.

## Active outcome

Implementar o menor gap operacional de CRM promovido pelo Plan 0046: **fechamento mínimo de Lead**, preservando `MarkContacted` e acrescentando apenas encerramento com outcome `Won/Lost`, sem copiar o pipeline de cinco estados do BPT1.

O slice parte do `main` integrado pelo PR #66 e está sendo executado no draft PR #67.

## Active plan

[`../exec-plans/active/0047-minimal-lead-closing.md`](../exec-plans/active/0047-minimal-lead-closing.md)

## Acceptance target

Um Seller autenticado consegue, somente sobre Leads dos próprios Listings:

- preservar `MarkContacted` monotônico/idempotente;
- fechar Lead como `Won` ou `Lost`;
- repetir o mesmo fechamento sem novo efeito;
- receber erro determinístico para outcome conflitante;
- ler `ClosedAtUtc?` e outcome no histórico Seller;
- continuar lendo o Lead após Pause/Archive do Listing;
- sem `NEGOCIACAO`, reabertura, notes, attribution, dashboard ou automação neste slice.

## Source of runtime truth

- Estado de branch/PR/checks: Git e GitHub Actions do commit corrente.
- Produto e escopo consolidado: [`../PRODUCT.md`](../PRODUCT.md).
- Fatos estruturais/versões/counters derivados: [`../generated/repository-facts.md`](../generated/repository-facts.md).
- Decisões congeladas: [`../MDV.md`](../MDV.md) e [`../adr/`](../adr/).
- Plano ativo: [`../exec-plans/active/0047-minimal-lead-closing.md`](../exec-plans/active/0047-minimal-lead-closing.md).
- Roadmap BPT1 → BPT2 concluído: [`../exec-plans/completed/0046-bpt1-capability-roadmap-audit.md`](../exec-plans/completed/0046-bpt1-capability-roadmap-audit.md).
- Matriz final da auditoria: [`../audits/2026-08-25-capability-final-decision-matrix.md`](../audits/2026-08-25-capability-final-decision-matrix.md).

Não copie SHAs, número de testes/checks ou “runtime ready” para este arquivo; consulte as fontes executáveis quando a tarefa depender deles.

## Open blockers

Nenhum blocker externo conhecido. Falhas de CI devem ser tratadas um gate por vez.

## Update rule

Atualize este snapshot somente quando mudar o outcome ativo, plano ativo, próximo acceptance target ou blocker real. História vai para execution plan concluído/ADR, não para baixo deste arquivo.

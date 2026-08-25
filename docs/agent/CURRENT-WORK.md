# Current work

Last verified: **2026-08-25**

Este arquivo é um snapshot curto do trabalho corrente. Não é histórico, changelog nem inventário de CI.

## Active outcome

A auditoria de prontidão do MVP (Plan 0027) está funcionalmente fechada:

- `MVP-01` — carga operacional do catálogo canônico: resolvido pelo Plan 0028;
- `MVP-02` — autoridade mínima de moderação: resolvido pelo Plan 0029.

Não resta blocker funcional classificado como `BLOQUEIA MVP` pela auditoria 0027. Os gaps restantes daquela auditoria continuam classificados como pós-MVP até nova evidência justificar reclassificação.

Próximo acceptance target: refetchar o `main` e priorizar o primeiro gap pós-MVP por evidência, sem promover backlog a requisito ou blocker por preferência.

## Active plan

Nenhum.

## Source of runtime truth

- Estado de branch/PR/checks: Git e GitHub Actions do commit corrente.
- Fatos estruturais/versões/counters derivados: [`../generated/repository-facts.md`](../generated/repository-facts.md).
- Decisões congeladas: [`../MDV.md`](../MDV.md) e [`../adr/`](../adr/).
- Auditoria de prontidão do MVP: [`../exec-plans/completed/0027-mvp-readiness-audit.md`](../exec-plans/completed/0027-mvp-readiness-audit.md).
- Catálogo canônico operacional: [`../exec-plans/completed/0028-admin-canonical-catalog.md`](../exec-plans/completed/0028-admin-canonical-catalog.md).
- Autoridade mínima de moderação: [`../exec-plans/completed/0029-moderation-listing-authority.md`](../exec-plans/completed/0029-moderation-listing-authority.md).

Não copie SHAs, número de testes/checks ou “runtime ready” para este arquivo; consulte as fontes executáveis quando a tarefa depender deles.

## Open blockers

Nenhum blocker funcional aberto da auditoria MVP 0027.

## Update rule

Atualize este snapshot somente quando mudar o outcome ativo, plano ativo, próximo acceptance target ou blocker real. História vai para execution plan concluído/ADR, não para baixo deste arquivo.

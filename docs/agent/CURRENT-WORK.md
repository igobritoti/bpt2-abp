# Current work

Last verified: **2026-08-24**

Este arquivo é um snapshot curto do trabalho corrente. Não é histórico, changelog nem inventário de CI.

## Active outcome

Execution Plan 0017 ativo. Acceptance target:

`admin login no host → /moderacao → reports persistidos read-only`

O slice reutiliza a inbox do Plan 0012 e a autenticação MVC/Account Web já presente no host. Não cria política/ação de moderação, novo cliente OIDC nem frontend administrativo separado.

## Active plan

[`../exec-plans/active/0017-moderation-admin-surface.md`](../exec-plans/active/0017-moderation-admin-surface.md)

## Source of runtime truth

- Estado de branch/PR/checks: Git e GitHub Actions do commit corrente.
- Fatos estruturais/versões/counters derivados: [`../generated/repository-facts.md`](../generated/repository-facts.md).
- Decisões congeladas: [`../MDV.md`](../MDV.md) e [`../adr/`](../adr/).
- Histórico de Listing share metadata: [`../exec-plans/completed/0016-public-listing-share-metadata.md`](../exec-plans/completed/0016-public-listing-share-metadata.md).
- Histórico do Vehicle Hub: [`../exec-plans/completed/0015-public-vehicle-hub.md`](../exec-plans/completed/0015-public-vehicle-hub.md).

Não copie SHAs, número de testes/checks ou “runtime ready” para este arquivo; consulte as fontes executáveis quando a tarefa depender deles.

## Open blockers

Nenhum blocker de repositório conhecido.

## Update rule

Atualize este snapshot somente quando mudar o outcome ativo, plano ativo, próximo acceptance target ou blocker real. História vai para execution plan concluído/ADR, não para baixo deste arquivo.

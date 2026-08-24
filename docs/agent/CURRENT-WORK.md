# Current work

Last verified: **2026-08-24**

Este arquivo é um snapshot curto do trabalho corrente. Não é histórico, changelog nem inventário de CI.

## Active outcome

Execution Plan 0020 concluído. O primeiro ponto de entrada comum das superfícies administrativas está fechado:

`admin login no host → /admin → Moderação / Ingestão`

`/admin` reutiliza a role `admin` e o Account Web já existentes e contém somente navegação para as superfícies operacionais atuais. Não consulta dados nem cria autoridade, permission model, backend ou schema paralelo.

Próximo acceptance target: auditar novamente o menor gap real de produto antes de abrir novo execution plan.

## Active plan

Nenhum execution plan ativo.

## Source of runtime truth

- Estado de branch/PR/checks: Git e GitHub Actions do commit corrente.
- Fatos estruturais/versões/counters derivados: [`../generated/repository-facts.md`](../generated/repository-facts.md).
- Decisões congeladas: [`../MDV.md`](../MDV.md) e [`../adr/`](../adr/).
- Histórico do Admin Operations Hub: [`../exec-plans/completed/0020-admin-operations-hub.md`](../exec-plans/completed/0020-admin-operations-hub.md).
- Histórico de Vehicle Hub share metadata: [`../exec-plans/completed/0019-public-vehicle-hub-share-metadata.md`](../exec-plans/completed/0019-public-vehicle-hub-share-metadata.md).
- Histórico de Ingestion Admin Surface: [`../exec-plans/completed/0018-ingestion-admin-surface.md`](../exec-plans/completed/0018-ingestion-admin-surface.md).
- Histórico de Moderation Admin Surface: [`../exec-plans/completed/0017-moderation-admin-surface.md`](../exec-plans/completed/0017-moderation-admin-surface.md).

Não copie SHAs, número de testes/checks ou “runtime ready” para este arquivo; consulte as fontes executáveis quando a tarefa depender deles.

## Open blockers

Nenhum blocker de repositório conhecido.

## Update rule

Atualize este snapshot somente quando mudar o outcome ativo, plano ativo, próximo acceptance target ou blocker real. História vai para execution plan concluído/ADR, não para baixo deste arquivo.

# Current work

Last verified: **2026-08-24**

Este arquivo é um snapshot curto do trabalho corrente. Não é histórico, changelog nem inventário de CI.

## Active outcome

Execution Plan 0012 concluído. O primeiro consumo operacional dos sinais de moderação está fechado:

`Buyer sinaliza Listing → report persistido → operador admin autenticado consulta fila`

A inbox é read-only, reutiliza a role `admin` existente no baseline ABP, não expõe identidade/PII Buyer e preserva reports históricos quando o Listing deixa de estar público. Política de moderação, taxonomia, ações sobre Listing, scoring, notificações e frontend administrativo continuam abertos até evidência suficiente.

Próximo acceptance target: auditar novamente o menor gap real de produto antes de abrir novo execution plan. Nenhum Plan 0013 é presumido apenas porque o Plan 0012 terminou.

## Active plan

Nenhum execution plan ativo.

## Source of runtime truth

- Estado de branch/PR/checks: Git e GitHub Actions do commit corrente.
- Fatos estruturais/versões/counters derivados: [`../generated/repository-facts.md`](../generated/repository-facts.md).
- Decisões congeladas: [`../MDV.md`](../MDV.md) e [`../adr/`](../adr/).
- Histórico da Moderation Report Inbox: [`../exec-plans/completed/0012-moderation-report-inbox.md`](../exec-plans/completed/0012-moderation-report-inbox.md).
- Histórico do Buyer Listing Report: [`../exec-plans/completed/0011-buyer-listing-report.md`](../exec-plans/completed/0011-buyer-listing-report.md).

Não copie SHAs, número de testes/checks ou “runtime ready” para este arquivo; consulte as fontes executáveis quando a tarefa depender deles.

## Open blockers

Nenhum blocker de repositório conhecido. Decisões futuras de política de moderação continuam abertas até evidência operacional suficiente.

## Update rule

Atualize este snapshot somente quando mudar o outcome ativo, plano ativo, próximo acceptance target ou blocker real. História vai para execution plan concluído/ADR, não para baixo deste arquivo.

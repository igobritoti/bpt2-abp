# Current work

Last verified: **2026-08-24**

Este arquivo é um snapshot curto do trabalho corrente. Não é histórico, changelog nem inventário de CI.

## Active outcome

Execution Plan 0012 em andamento. O acceptance target atual é fechar o primeiro consumo operacional dos sinais de moderação já persistidos no Plan 0011:

`Buyer sinaliza Listing → report persistido → operador admin autenticado consulta fila`

A primeira inbox é deliberadamente read-only. O boundary de autorização reutiliza a role `admin` existente no baseline ABP e a projeção mínima não resolve nem expõe PII/perfil Buyer. Política de moderação, taxonomia, ações sobre Listing, scoring e notificações permanecem fora do slice.

## Active plan

[`../exec-plans/active/0012-moderation-report-inbox.md`](../exec-plans/active/0012-moderation-report-inbox.md)

## Source of runtime truth

- Estado de branch/PR/checks: Git e GitHub Actions do commit corrente.
- Fatos estruturais/versões/counters derivados: [`../generated/repository-facts.md`](../generated/repository-facts.md).
- Decisões congeladas: [`../MDV.md`](../MDV.md) e [`../adr/`](../adr/).
- Histórico do Buyer Listing Report: [`../exec-plans/completed/0011-buyer-listing-report.md`](../exec-plans/completed/0011-buyer-listing-report.md).

Não copie SHAs, número de testes/checks ou “runtime ready” para este arquivo; consulte as fontes executáveis quando a tarefa depender deles.

## Open blockers

Nenhum blocker de repositório conhecido. Decisões futuras de política de moderação continuam abertas até evidência operacional suficiente.

## Update rule

Atualize este snapshot somente quando mudar o outcome ativo, plano ativo, próximo acceptance target ou blocker real. História vai para execution plan concluído/ADR, não para baixo deste arquivo.

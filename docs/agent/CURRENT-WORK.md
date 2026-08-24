# Current work

Last verified: **2026-08-24**

Este arquivo é um snapshot curto do trabalho corrente. Não é histórico, changelog nem inventário de CI.

## Active outcome

Execution Plan 0014 em execução. Outcome corrente:

`candidate externo → registro persistido → fila pendente → operador admin reconcilia com Vehicle canônico`

O slice reutiliza o modelo persistente já existente em Ingestion e valida o destino exclusivamente por `Catalog.Contracts`. Connector externo, matching automático, background job e nova UI permanecem fora do boundary.

Próximo acceptance target: provar por HTTP real que somente admin registra/lista/reconcilia candidates, que `(Source, ExternalId)` não duplica registro e que reconciliation só aceita Vehicle canônico existente.

## Active plan

[`../exec-plans/active/0014-ingestion-candidate-reconciliation.md`](../exec-plans/active/0014-ingestion-candidate-reconciliation.md)

## Source of runtime truth

- Estado de branch/PR/checks: Git e GitHub Actions do commit corrente.
- Fatos estruturais/versões/counters derivados: [`../generated/repository-facts.md`](../generated/repository-facts.md).
- Decisões congeladas: [`../MDV.md`](../MDV.md) e [`../adr/`](../adr/).
- Histórico de SEO técnico: [`../exec-plans/completed/0013-public-seo-discovery.md`](../exec-plans/completed/0013-public-seo-discovery.md).

Não copie SHAs, número de testes/checks ou “runtime ready” para este arquivo; consulte as fontes executáveis quando a tarefa depender deles.

## Open blockers

Nenhum blocker de repositório conhecido.

## Update rule

Atualize este snapshot somente quando mudar o outcome ativo, plano ativo, próximo acceptance target ou blocker real. História vai para execution plan concluído/ADR, não para baixo deste arquivo.

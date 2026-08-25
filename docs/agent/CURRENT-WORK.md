# Current work

Last verified: **2026-08-24**

Este arquivo é um snapshot curto do trabalho corrente. Não é histórico, changelog nem inventário de CI.

## Active outcome

Execution Plan 0028 em execução para fechar o blocker `MVP-01` identificado pela auditoria de prontidão:

`admin → identidade automotiva canônica → catálogo público → Seller Draft`

O slice deve permitir que um ambiente novo crie `Brand → Model → Generation opcional → Version → Vehicle` por uma superfície administrativa suportada, sem executar `tests/BomPraTi.HttpLifecycleFixture` e sem adicionar connector/importador ou nova infraestrutura.

Próximo acceptance target: provar em PostgreSQL fresco que somente admin cria/reutiliza a identidade canônica, o Vehicle aparece no catálogo público e pode ser usado imediatamente para criar um Draft Seller.

## Active plan

[`../exec-plans/active/0028-admin-canonical-catalog.md`](../exec-plans/active/0028-admin-canonical-catalog.md)

## Source of runtime truth

- Estado de branch/PR/checks: Git e GitHub Actions do commit corrente.
- Fatos estruturais/versões/counters derivados: [`../generated/repository-facts.md`](../generated/repository-facts.md).
- Decisões congeladas: [`../MDV.md`](../MDV.md) e [`../adr/`](../adr/).
- Auditoria de prontidão do MVP: [`../exec-plans/completed/0027-mvp-readiness-audit.md`](../exec-plans/completed/0027-mvp-readiness-audit.md).

Não copie SHAs, número de testes/checks ou “runtime ready” para este arquivo; consulte as fontes executáveis quando a tarefa depender deles.

## Open blockers

- **MVP-01 — catálogo canônico (EM TRABALHO):** ambiente novo não possui caminho operacional suportado para criar o Vehicle canônico exigido por Listing.
- **MVP-02 — moderação:** operador lê denúncias, mas ainda não consegue retirar/restaurar Listing por autoridade administrativa do produto.

## Update rule

Atualize este snapshot somente quando mudar o outcome ativo, plano ativo, próximo acceptance target ou blocker real. História vai para execution plan concluído/ADR, não para baixo deste arquivo.

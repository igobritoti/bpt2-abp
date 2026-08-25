# Current work

Last verified: **2026-08-24**

Este arquivo é um snapshot curto do trabalho corrente. Não é histórico, changelog nem inventário de CI.

## Active outcome

O Execution Plan 0028 fechou o blocker `MVP-01`: um operador `admin` agora consegue criar/reutilizar `Brand → Model → Generation opcional → Version → Vehicle` por uma superfície suportada, e o gate focal provou em PostgreSQL fresco que o Vehicle criado entra no catálogo público e pode ser usado imediatamente em um Draft Seller sem `tests/BomPraTi.HttpLifecycleFixture`.

Resta um blocker funcional identificado pela auditoria de prontidão:

**MVP-02 — ação mínima de moderação:** Buyer reporta Listing público e admin consulta a fila, mas o operador ainda não possui autoridade de produto para retirar/restaurar a visibilidade do Listing denunciado sem que o Seller possa desfazer a decisão administrativa.

Próximo acceptance target: criar uma autoridade de moderação separada do lifecycle Seller e provar por HTTP que admin retira um Listing denunciado da descoberta pública, Seller não consegue republicá-lo enquanto moderado e admin consegue restaurá-lo.

## Active plan

Nenhum execution plan ativo.

## Source of runtime truth

- Estado de branch/PR/checks: Git e GitHub Actions do commit corrente.
- Fatos estruturais/versões/counters derivados: [`../generated/repository-facts.md`](../generated/repository-facts.md).
- Decisões congeladas: [`../MDV.md`](../MDV.md) e [`../adr/`](../adr/).
- Auditoria de prontidão do MVP: [`../exec-plans/completed/0027-mvp-readiness-audit.md`](../exec-plans/completed/0027-mvp-readiness-audit.md).
- Catálogo canônico operacional: [`../exec-plans/completed/0028-admin-canonical-catalog.md`](../exec-plans/completed/0028-admin-canonical-catalog.md).

Não copie SHAs, número de testes/checks ou “runtime ready” para este arquivo; consulte as fontes executáveis quando a tarefa depender deles.

## Open blockers

- **MVP-02 — moderação:** operador lê denúncias, mas ainda não consegue retirar/restaurar Listing por autoridade administrativa do produto.

## Update rule

Atualize este snapshot somente quando mudar o outcome ativo, plano ativo, próximo acceptance target ou blocker real. História vai para execution plan concluído/ADR, não para baixo deste arquivo.

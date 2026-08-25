# Current work

Last verified: **2026-08-25**

Este arquivo é um snapshot curto do trabalho corrente. Não é histórico, changelog nem inventário de CI.

## Active outcome

Execution Plan 0029 em execução para fechar o blocker `MVP-02` identificado pela auditoria de prontidão:

`Buyer report → admin withdraw → Moderated → invisível publicamente → Seller bloqueado → admin restore → Published`

O slice separa a autoridade de moderação do lifecycle Seller: `Paused` continua sendo pausa voluntária do anunciante; `Moderated` representa retirada administrativa e não pode ser revertido pelo Seller.

Próximo acceptance target: provar por HTTP que somente admin retira/restaura um Listing denunciado, o Listing moderado some da descoberta pública, o Seller não consegue republicar/editar enquanto moderado e a restauração o torna público novamente.

## Active plan

[`../exec-plans/active/0029-moderation-listing-authority.md`](../exec-plans/active/0029-moderation-listing-authority.md)

## Source of runtime truth

- Estado de branch/PR/checks: Git e GitHub Actions do commit corrente.
- Fatos estruturais/versões/counters derivados: [`../generated/repository-facts.md`](../generated/repository-facts.md).
- Decisões congeladas: [`../MDV.md`](../MDV.md) e [`../adr/`](../adr/).
- Auditoria de prontidão do MVP: [`../exec-plans/completed/0027-mvp-readiness-audit.md`](../exec-plans/completed/0027-mvp-readiness-audit.md).
- Catálogo canônico operacional: [`../exec-plans/completed/0028-admin-canonical-catalog.md`](../exec-plans/completed/0028-admin-canonical-catalog.md).

Não copie SHAs, número de testes/checks ou “runtime ready” para este arquivo; consulte as fontes executáveis quando a tarefa depender deles.

## Open blockers

- **MVP-02 — moderação (EM TRABALHO):** operador lê denúncias, mas ainda não consegue retirar/restaurar Listing por autoridade administrativa do produto.

## Update rule

Atualize este snapshot somente quando mudar o outcome ativo, plano ativo, próximo acceptance target ou blocker real. História vai para execution plan concluído/ADR, não para baixo deste arquivo.

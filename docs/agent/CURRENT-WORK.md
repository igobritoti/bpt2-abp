# Current work

Last verified: **2026-08-23**

Este arquivo é um snapshot curto do trabalho corrente. Não é histórico, changelog nem inventário de CI.

## Active outcome

Execution Plan 0003 concluído. O primeiro consumidor público real está comprovado até:

`Public Listing → Public Detail → Photo → WhatsApp Contact`

O public web permanece independente do host ABP e consome somente a API HTTP. Draft/private continua indisponível, o contato usa o `WhatsAppNumber` canônico de Sellers e o fluxo completo foi comprovado pelo gate HTTP real.

Próximo acceptance target: selecionar o menor próximo gap de produto antes de abrir nova feature ou novo execution plan. Não há plano de implementação ativo neste momento.

## Active plan

Nenhum execution plan ativo após o fechamento do Plan 0003.

## Source of runtime truth

- Estado de branch/PR/checks: Git e GitHub Actions do commit corrente.
- Fatos estruturais/versões/counters derivados: [`../generated/repository-facts.md`](../generated/repository-facts.md).
- Decisões congeladas: [`../MDV.md`](../MDV.md) e [`../adr/`](../adr/).

Não copie SHAs, número de testes/checks ou “runtime ready” para este arquivo; consulte as fontes executáveis quando a tarefa depender deles.

## Open blockers

Nenhum blocker de repositório conhecido.

## Update rule

Atualize este snapshot somente quando mudar o outcome ativo, plano ativo, próximo acceptance target ou blocker real. História vai para o execution plan concluído/ADR, não para baixo deste arquivo.

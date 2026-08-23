# Current work

Last verified: **2026-08-23**

Este arquivo é um snapshot curto do trabalho corrente. Não é histórico, changelog nem inventário de CI.

## Active outcome

Retomar o baseline de produto:

`Seller → Vehicle → Listing → Publish → Public Listing Query`

Próximo acceptance target: provar o lifecycle autenticado do Listing pelo caminho HTTP real, incluindo ownership, Draft invisível, Publish público e optimistic concurrency.

## Active plan

[`../exec-plans/active/0001-product-baseline.md`](../exec-plans/active/0001-product-baseline.md)

## Source of runtime truth

- Estado de branch/PR/checks: Git e GitHub Actions do commit corrente.
- Fatos estruturais/versões/counters derivados: [`../generated/repository-facts.md`](../generated/repository-facts.md).
- Decisões congeladas: [`../MDV.md`](../MDV.md) e [`../adr/`](../adr/).

Não copie SHAs, número de testes/checks ou “runtime ready” para este arquivo; consulte as fontes executáveis quando a tarefa depender deles.

## Open blockers

Nenhum blocker de repositório conhecido. Se surgir blocker externo real, registre-o aqui enquanto estiver ativo e remova/substitua quando resolvido.

## Update rule

Atualize este snapshot somente quando mudar o outcome ativo, plano ativo, próximo acceptance target ou blocker real. História vai para o execution plan concluído/ADR, não para baixo deste arquivo.

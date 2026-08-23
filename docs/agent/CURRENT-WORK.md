# Current work

Last verified: **2026-08-23**

Este arquivo é um snapshot curto do trabalho corrente. Não é histórico, changelog nem inventário de CI.

## Active outcome

Executar o primeiro fluxo público real do comprador conforme o Execution Plan 0003:

`Public Listing → Public Detail → WhatsApp Contact`

O Product Baseline de backend está concluído. O public web deve permanecer independente do host ABP, consumir somente a API HTTP e usar Next.js 16 Active LTS/App Router na primeira implementação conforme ADR-0009.

Próximo acceptance target: materializar a fundação do public web com gate próprio e, em seguida, expor no detalhe o `WhatsAppNumber` que já existe no contrato público de Seller. Não criar Lead persistido, chat ou nova infraestrutura antes que um requisito real exija isso.

## Active plan

[`../exec-plans/active/0003-public-buyer-contact.md`](../exec-plans/active/0003-public-buyer-contact.md)

## Source of runtime truth

- Estado de branch/PR/checks: Git e GitHub Actions do commit corrente.
- Fatos estruturais/versões/counters derivados: [`../generated/repository-facts.md`](../generated/repository-facts.md).
- Decisões congeladas: [`../MDV.md`](../MDV.md) e [`../adr/`](../adr/).

Não copie SHAs, número de testes/checks ou “runtime ready” para este arquivo; consulte as fontes executáveis quando a tarefa depender deles.

## Open blockers

Nenhum blocker de repositório conhecido. O formato exato de normalização/validação do WhatsApp permanece uma decisão local permitida pelo plano e deve ser resolvido apenas antes do CTA real.

## Update rule

Atualize este snapshot somente quando mudar o outcome ativo, plano ativo, próximo acceptance target ou blocker real. História vai para o execution plan concluído/ADR, não para baixo deste arquivo.

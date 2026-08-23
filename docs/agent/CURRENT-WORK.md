# Current work

Last verified: **2026-08-23**

Este arquivo é um snapshot curto do trabalho corrente. Não é histórico, changelog nem inventário de CI.

## Active outcome

Executar o primeiro fluxo público real do comprador conforme o Execution Plan 0003:

`Public Listing → Public Detail → WhatsApp Contact`

A fundação independente do public web já foi materializada e comprovada por CI com Next.js 16 Active LTS/App Router, TypeScript, ESLint e production build. O cliente continua desacoplado do host ABP e sua fronteira durável é a API HTTP.

Próximo acceptance target: expor na projeção pública de Listing o `WhatsAppNumber` que já existe e é normalizado no domínio Sellers, comprovando o contrato HTTP sem criar Lead persistido. Depois disso, conectar listagem/detalhe/CTA no public web.

## Active plan

[`../exec-plans/active/0003-public-buyer-contact.md`](../exec-plans/active/0003-public-buyer-contact.md)

## Source of runtime truth

- Estado de branch/PR/checks: Git e GitHub Actions do commit corrente.
- Fatos estruturais/versões/counters derivados: [`../generated/repository-facts.md`](../generated/repository-facts.md).
- Decisões congeladas: [`../MDV.md`](../MDV.md) e [`../adr/`](../adr/).

Não copie SHAs, número de testes/checks ou “runtime ready” para este arquivo; consulte as fontes executáveis quando a tarefa depender deles.

## Open blockers

Nenhum blocker de repositório conhecido. A normalização de WhatsApp deixou de ser decisão aberta: `SellerProfile` já persiste somente 8–15 dígitos incluindo country code.

## Update rule

Atualize este snapshot somente quando mudar o outcome ativo, plano ativo, próximo acceptance target ou blocker real. História vai para o execution plan concluído/ADR, não para baixo deste arquivo.

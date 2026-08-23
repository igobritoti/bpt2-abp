# Current work

Last verified: **2026-08-23**

Este arquivo é um snapshot curto do trabalho corrente. Não é histórico, changelog nem inventário de CI.

## Active outcome

Execution Plan 0004 ativo. O objetivo corrente é fechar o primeiro fluxo operacional real do Seller sobre a superfície autenticada já existente:

`Seller login → Seller profile → My Listings → Draft/Edit → Vehicle selection → Photos → Publish → Public Listing`

A auditoria inicial confirmou que perfil, My Listings, comandos de Listing, Vehicle search, Media upload e mutações de foto já existem. O gap mínimo de backend já identificado é uma leitura autenticada de detalhe/galeria para reabrir a edição de um Listing próprio.

Próximo acceptance target: provar a menor fronteira de UI/auth para o Seller usando Authorization Code + PKCE e decidir, por evidência, entre estender o cliente Next.js existente ou usar um cliente autenticado separado.

## Active plan

[`../exec-plans/active/0004-seller-self-service.md`](../exec-plans/active/0004-seller-self-service.md)

## Source of runtime truth

- Estado de branch/PR/checks: Git e GitHub Actions do commit corrente.
- Fatos estruturais/versões/counters derivados: [`../generated/repository-facts.md`](../generated/repository-facts.md).
- Decisões congeladas: [`../MDV.md`](../MDV.md) e [`../adr/`](../adr/).

Não copie SHAs, número de testes/checks ou “runtime ready” para este arquivo; consulte as fontes executáveis quando a tarefa depender deles.

## Open blockers

Nenhum blocker de repositório conhecido. O código donor do BPT1 não está disponível nas fontes GitHub acessíveis nesta auditoria; isso limita transplantar UX/código antigo, mas não bloqueia o Plan 0004 porque o backend BPT2 necessário já está majoritariamente exposto.

## Update rule

Atualize este snapshot somente quando mudar o outcome ativo, plano ativo, próximo acceptance target ou blocker real. História vai para o execution plan concluído/ADR, não para baixo deste arquivo.

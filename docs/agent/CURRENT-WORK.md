# Current work

Last verified: **2026-08-23**

Este arquivo é um snapshot curto do trabalho corrente. Não é histórico, changelog nem inventário de CI.

## Active outcome

Execution Plan 0004 ativo. O objetivo corrente é fechar o primeiro fluxo operacional real do Seller sobre a superfície autenticada já existente:

`Seller login → Seller profile → My Listings → Draft/Edit → Vehicle selection → Photos → Publish → Public Listing`

A fronteira de UI/auth e o Seller shell mínimo estão comprovados. A implementação inicial reutiliza o `public-web` em `/vender`, com cliente OpenIddict dedicado `BomPraTi_SellerWeb` e Authorization Code + PKCE. O fluxo executado prova login real pelo Account, troca PKCE por access token, leitura/edição do Seller Profile com normalização canônica no backend, `Meus anúncios` filtrado pelo usuário autenticado e logout.

O gap mínimo de backend já identificado para o próximo bloco é uma leitura autenticada de detalhe/galeria para reabrir a edição de um Listing próprio. `GetMine` continua sendo listagem e não substitui esse read model de edição.

Próximo acceptance target: implementar a leitura mínima de edição e o fluxo `Vehicle canônico → criar Draft → reabrir/editar Listing próprio`, preservando ownership server-side e `ConcurrencyStamp`. Fotos/publicação permanecem no checkpoint seguinte.

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

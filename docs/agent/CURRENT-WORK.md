# Current work

Last verified: **2026-08-23**

Este arquivo é um snapshot curto do trabalho corrente. Não é histórico, changelog nem inventário de CI.

## Active outcome

Execution Plan 0004 ativo. O objetivo corrente é fechar o primeiro fluxo operacional real do Seller sobre a superfície autenticada já existente:

`Seller login → Seller profile → My Listings → Draft/Edit → Vehicle selection → Photos → Publish → Public Listing`

A fronteira de UI/auth, o Seller shell mínimo e o checkpoint Draft/Edit estão comprovados. A experiência Seller reutiliza o `public-web` em `/vender`, com cliente OpenIddict dedicado `BomPraTi_SellerWeb` e Authorization Code + PKCE. O Seller escolhe um Vehicle da API canônica, cria um Listing que nasce Draft, reabre apenas Listing próprio pelo read model autenticado e salva alterações usando o `ConcurrencyStamp` devolvido pelo backend; stale update continua resultando em 409.

A leitura mínima de edição foi resolvida por `SellerListingQuery.GetMineByIdAsync`, que filtra `listingId + CurrentUser` no servidor e devolve o Listing com a galeria/ordem atual. Não houve nova regra de domínio, aggregate ou dependência entre implementações de módulos.

Próximo acceptance target: concluir o checkpoint de fotos e publicação — `Media upload → attach/remove/reorder ListingPhoto → Publish/Pause/Archive → Public Listing`, preservando ownership, Draft privado e os boundaries já comprovados.

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

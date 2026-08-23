# Current work

Last verified: **2026-08-23**

Este arquivo é um snapshot curto do trabalho corrente. Não é histórico, changelog nem inventário de CI.

## Active outcome

Execution Plan 0004 concluído. O primeiro ciclo operacional real do Seller está comprovado sobre a mesma fronteira HTTP/OIDC do produto:

`Seller login → Seller profile → My Listings → Vehicle canônico → Draft/Edit → Photos → Publish → Public Listing`

A experiência Seller reutiliza o `public-web` sob `/vender`, com cliente OpenIddict dedicado `BomPraTi_SellerWeb` e Authorization Code + PKCE. Ownership permanece server-side, edição usa `ConcurrencyStamp`, Media valida uploads, ListingPhoto controla galeria/ordem e Publish/Pause/Archive continuam regras do backend.

O gate final comprovou em PostgreSQL fresco e Next.js de produção: login PKCE, Profile, Draft/My Listings, edição, upload/attach/reorder/remove, bloqueio de segundo Seller, Draft privado, Publish público, Pause privado, republish público e Archive privado.

Próximo acceptance target: selecionar por evidência o menor gap real de produto antes de abrir novo execution plan. Nenhum Plan 0005 é presumido apenas porque o Plan 0004 terminou.

## Active plan

Nenhum execution plan ativo.

## Source of runtime truth

- Estado de branch/PR/checks: Git e GitHub Actions do commit corrente.
- Fatos estruturais/versões/counters derivados: [`../generated/repository-facts.md`](../generated/repository-facts.md).
- Decisões congeladas: [`../MDV.md`](../MDV.md) e [`../adr/`](../adr/).
- Histórico do Seller Self-Service: [`../exec-plans/completed/0004-seller-self-service.md`](../exec-plans/completed/0004-seller-self-service.md).

Não copie SHAs, número de testes/checks ou “runtime ready” para este arquivo; consulte as fontes executáveis quando a tarefa depender deles.

## Open blockers

Nenhum blocker de repositório conhecido. O código donor do BPT1 continua indisponível nas fontes GitHub acessíveis; isso limita transplante auditável de UX/código antigo, mas não bloqueia os fluxos BPT2 já comprovados.

## Update rule

Atualize este snapshot somente quando mudar o outcome ativo, plano ativo, próximo acceptance target ou blocker real. História vai para execution plan concluído/ADR, não para baixo deste arquivo.

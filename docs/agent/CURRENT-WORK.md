# Current work

Last verified: **2026-08-23**

Este arquivo é um snapshot curto do trabalho corrente. Não é histórico, changelog nem inventário de CI.

## Active outcome

Execution Plan 0006 concluído. O primeiro ciclo autenticado de Favorite do Buyer está fechado:

`Public Detail → Buyer login → Favorite/Unfavorite → Meus favoritos`

O Buyer usa o cliente OIDC público dedicado `BomPraTi_BuyerWeb` com Authorization Code + PKCE, sem alterar `BomPraTi_SellerWeb`. A API deriva `UserId` de `ICurrentUser`, só aceita add para Listing atualmente público e projeta `Meus favoritos` pela mesma autoridade pública de Listing. Pause oculta sem apagar a relação; republish restaura; unfavorite remove.

O Buyer Favorites HTTP Gate comprovou o fluxo em PostgreSQL fresco + host ABP + Account/OIDC real + Next de produção. O head de produto também manteve verdes todos os workflows aplicáveis.

Próximo acceptance target: auditar novamente o menor gap real de produto antes de abrir novo execution plan. Nenhum Plan 0007 é presumido apenas porque o Plan 0006 terminou.

## Active plan

Nenhum execution plan ativo.

## Source of runtime truth

- Estado de branch/PR/checks: Git e GitHub Actions do commit corrente.
- Fatos estruturais/versões/counters derivados: [`../generated/repository-facts.md`](../generated/repository-facts.md).
- Decisões congeladas: [`../MDV.md`](../MDV.md) e [`../adr/`](../adr/).
- Histórico do Buyer Favorites: [`../exec-plans/completed/0006-buyer-favorites.md`](../exec-plans/completed/0006-buyer-favorites.md).
- Histórico do Public Discovery: [`../exec-plans/completed/0005-public-discovery.md`](../exec-plans/completed/0005-public-discovery.md).

Não copie SHAs, número de testes/checks ou “runtime ready” para este arquivo; consulte as fontes executáveis quando a tarefa depender deles.

## Open blockers

Nenhum blocker de repositório conhecido. Decisões futuras de infraestrutura continuam adiadas até necessidade real e seguem ADR-0010 quando forem abertas.

## Update rule

Atualize este snapshot somente quando mudar o outcome ativo, plano ativo, próximo acceptance target ou blocker real. História vai para execution plan concluído/ADR, não para baixo deste arquivo.

# Current work

Last verified: **2026-08-23**

Este arquivo é um snapshot curto do trabalho corrente. Não é histórico, changelog nem inventário de CI.

## Active outcome

Execution Plan 0006 ativo. O objetivo corrente é fechar o menor ciclo autenticado restante do Buyer:

`Public Detail → Buyer login → Favorite/Unfavorite → Meus favoritos`

A auditoria de `main` confirmou que `Favorite` e `MarketplaceFavorites` já existem com unicidade `(UserId, ListingId)`, mas não existe Contract/AppService/UI. O cliente OIDC atual é deliberadamente Seller; o Buyer usará cliente público dedicado com Authorization Code + PKCE sem alterar essa fronteira.

Próximo acceptance target: provar em runtime que identidade é derivada no servidor, Draft não pode ser favoritado, Published pode, duplicata é idempotente, Pause oculta da lista sem perder a relação, republish restaura e unfavorite remove.

## Active plan

[`../exec-plans/active/0006-buyer-favorites.md`](../exec-plans/active/0006-buyer-favorites.md)

## Source of runtime truth

- Estado de branch/PR/checks: Git e GitHub Actions do commit corrente.
- Fatos estruturais/versões/counters derivados: [`../generated/repository-facts.md`](../generated/repository-facts.md).
- Decisões congeladas: [`../MDV.md`](../MDV.md) e [`../adr/`](../adr/).
- Histórico do Public Discovery: [`../exec-plans/completed/0005-public-discovery.md`](../exec-plans/completed/0005-public-discovery.md).

## Open blockers

Nenhum blocker conhecido. O plano não requer infraestrutura nova; ADR-0010 não abre avaliação de fornecedor sem necessidade infra.

## Update rule

Atualize este snapshot somente quando mudar o outcome ativo, plano ativo, próximo acceptance target ou blocker real. História vai para execution plan concluído/ADR, não para baixo deste arquivo.

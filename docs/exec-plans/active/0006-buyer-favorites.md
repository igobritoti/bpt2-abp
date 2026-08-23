# Execution Plan 0006 — Buyer Favorites

Status: **ATIVO**

## Objetivo

Fechar o menor ciclo autenticado restante do Buyer usando a estrutura `Favorite` já existente:

`Public Detail → Buyer login → Favorite/Unfavorite → Meus favoritos`

## Evidência de partida

- `Favorite` já existe como aggregate de Marketplace com `UserId` e `ListingId`.
- `MarketplaceFavorites` já existe no DbContext com unicidade `(UserId, ListingId)`.
- Não existe Contract/AppService/UI de Favorite.
- O cliente OIDC existente é explicitamente Seller (`BomPraTi_SellerWeb`, callback `/vender/callback`), portanto não será reutilizado implicitamente para Buyer.
- Public Listing já concentra a regra de visibilidade pública.

Classificação:
- **PASSA:** estrutura de domínio/persistência de Favorite.
- **NÃO PASSA:** capacidade operacional Buyer de salvar/remover/listar favoritos.
- **DECIDIDO:** Buyer usa cliente OIDC público dedicado com Authorization Code + PKCE, preservando o cliente Seller.
- **DECIDIDO:** `UserId` é sempre derivado de `ICurrentUser`; browser nunca escolhe proprietário do Favorite.
- **DECIDIDO:** apenas Listing atualmente público pode ser adicionado e apenas Listings ainda públicos aparecem em `Meus favoritos`.
- **NÃO DECIDIDO:** notificações, pastas/listas, ranking por favoritos, analytics ou perfil Buyer adicional.

## Escopo

- cliente OIDC `BomPraTi_BuyerWeb` com PKCE;
- application service Favorite autenticado;
- add idempotente, remove, estado e lista do usuário atual;
- reutilizar `IPublicListingQuery` como autoridade de visibilidade/projeção pública;
- CTA no detalhe público e página `/favoritos`;
- gate real API + OIDC + Next.

## Fora de escopo

- perfil Buyer;
- alertas de preço/disponibilidade;
- compartilhamento de listas;
- Lead/analytics/CRM;
- ranking baseado em favoritos;
- infraestrutura nova.

## Critérios de aceite

1. [ ] Buyer autentica pelo cliente dedicado usando Authorization Code + PKCE.
2. [ ] API de Favorite exige autenticação e deriva `UserId` no servidor.
3. [ ] Draft/private não pode ser favoritado.
4. [ ] Add duplicado é idempotente sob a unicidade existente.
5. [ ] `Meus favoritos` retorna somente favoritos do usuário atual que continuam públicos.
6. [ ] Pause remove o item da projeção pública sem apagar silenciosamente a intenção; republish o faz reaparecer.
7. [ ] Unfavorite remove a relação.
8. [ ] Detalhe público oferece CTA e `/favoritos` oferece login/lista/remove/logout.
9. [ ] Seller auth, Buyer público e gates diretamente afetados continuam verdes.
10. [ ] Nenhuma infraestrutura é adicionada; ADR-0010 permanece satisfeita por não haver nova necessidade infra.

## Checkpoints

- [x] Auditar aggregate/tabela e ausência de serviço Favorite.
- [x] Auditar fronteira OIDC Seller e decidir cliente Buyer dedicado.
- [ ] Implementar backend Favorite e auth Buyer.
- [ ] Implementar UI Buyer.
- [ ] Provar fluxo real e regressões.
- [ ] Atualizar documentação canônica e encerrar o plano.

## Progress log

- 2026-08-23: Favorite selecionado após Plan 0005 por ser o menor gap vertical com estrutura de domínio/persistência já existente.
- 2026-08-23: fronteira Seller preservada; Buyer terá cliente OIDC dedicado em vez de generalização prematura.

## Decision log

- OIDC Buyer dedicado, Authorization Code + PKCE.
- Ownership de Favorite exclusivamente por `ICurrentUser`.
- Visibilidade de Favorite delega à projeção pública existente de Listing.
- Nenhuma infraestrutura nova neste plano.

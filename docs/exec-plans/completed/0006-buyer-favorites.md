# Execution Plan 0006 — Buyer Favorites

Status: **CONCLUÍDO**

## Objetivo

Fechar o menor ciclo autenticado restante do Buyer usando a estrutura `Favorite` já existente:

`Public Detail → Buyer login → Favorite/Unfavorite → Meus favoritos`

## Evidência de partida

- `Favorite` já existia como aggregate de Marketplace com `UserId` e `ListingId`.
- `MarketplaceFavorites` já existia no DbContext com unicidade `(UserId, ListingId)`.
- Não existia Contract/AppService/UI de Favorite.
- O cliente OIDC existente era explicitamente Seller (`BomPraTi_SellerWeb`, callback `/vender/callback`) e não foi generalizado implicitamente para Buyer.
- Public Listing já concentrava a regra de visibilidade pública.

Classificação inicial:

- **PASSA:** estrutura de domínio/persistência de Favorite.
- **NÃO PASSA:** capacidade operacional Buyer de salvar/remover/listar favoritos.
- **DECIDIDO:** Buyer usa cliente OIDC público dedicado com Authorization Code + PKCE, preservando o cliente Seller.
- **DECIDIDO:** `UserId` é sempre derivado de `ICurrentUser`; browser nunca escolhe proprietário do Favorite.
- **DECIDIDO:** apenas Listing atualmente público pode ser adicionado e apenas Listings ainda públicos aparecem em `Meus favoritos`.
- **NÃO DECIDIDO:** notificações, pastas/listas, ranking por favoritos, analytics ou perfil Buyer adicional.

## Escopo executado

- cliente OIDC `BomPraTi_BuyerWeb` público e dedicado com Authorization Code + PKCE;
- application service Favorite autenticado;
- add idempotente, remove, consulta de estado e lista do usuário atual;
- `IPublicListingQuery` reutilizado como autoridade de visibilidade/projeção pública;
- CTA de Favorite no detalhe público e página `/favoritos`;
- gate real com PostgreSQL fresco, ABP Account/OIDC, API e Next.js de produção;
- prova adicional de isolamento de ownership com dois Buyers autenticados distintos.

## Fora de escopo

- perfil Buyer;
- alertas de preço/disponibilidade;
- compartilhamento de listas;
- Lead/analytics/CRM;
- ranking baseado em favoritos;
- infraestrutura nova.

## Critérios de aceite

1. [x] Buyer autentica pelo cliente dedicado usando Authorization Code + PKCE.
2. [x] API de Favorite exige autenticação e deriva `UserId` no servidor.
3. [x] Draft/private não pode ser favoritado.
4. [x] Add duplicado é idempotente no fluxo HTTP comprovado e a unicidade `(UserId, ListingId)` permanece como guarda de persistência.
5. [x] `Meus favoritos` retorna somente favoritos do usuário atual que continuam públicos; dois Buyers distintos foram provados isolados no mesmo Listing.
6. [x] Pause remove o item da projeção pública sem apagar a relação; republish o faz reaparecer.
7. [x] Unfavorite remove somente a relação do usuário atual; remover Buyer A não remove o Favorite de Buyer B.
8. [x] Detalhe público oferece CTA e `/favoritos` oferece login/lista/remove/logout.
9. [x] Seller auth, Buyer público e demais gates diretamente afetados permaneceram verdes no head de produto.
10. [x] Nenhuma infraestrutura foi adicionada; ADR-0010 não precisou abrir avaliação de fornecedor/capacidade.

## Checkpoints

- [x] Auditar aggregate/tabela e ausência de serviço Favorite.
- [x] Auditar fronteira OIDC Seller e decidir cliente Buyer dedicado.
- [x] Implementar backend Favorite e auth Buyer.
- [x] Implementar UI Buyer.
- [x] Provar fluxo real e regressões.
- [x] Provar isolamento de Favorite entre dois Buyers distintos.
- [x] Atualizar documentação canônica e encerrar o plano.

## Decisões

### Autenticação Buyer

**DECIDIDO:** `BomPraTi_BuyerWeb` é um cliente OpenIddict público separado de `BomPraTi_SellerWeb`, usando Authorization Code + PKCE. A primeira composição continua dentro do mesmo `public-web`, mas com sessão, callback e client id próprios para Buyer.

### Ownership

**DECIDIDO:** a API nunca recebe `UserId` como escolha do browser. Add, remove, estado e lista derivam o usuário de `ICurrentUser`. A prova HTTP com dois usuários confirmou que as relações para o mesmo Listing são independentes por Buyer.

### Visibilidade

**DECIDIDO:** Favorite guarda a intenção do usuário, mas a experiência Buyer só projeta Listing atualmente público. Add exige projeção pública existente; `GetMineAsync` e estado reutilizam `IPublicListingQuery`. Pause oculta sem apagar a relação e republish restaura a projeção.

### Infraestrutura

**DECIDIDO:** nenhuma nova capacidade de infraestrutura foi necessária. ADR-0010 permanece aplicável a necessidades futuras, mas não justifica avaliação de solução de mercado quando não há capacidade infra a adotar/construir.

## Evidência executada

O Buyer Favorites HTTP Gate executou contra PostgreSQL 17 fresco, host ABP real, Account login real, troca Authorization Code + PKCE por access token e Next.js de produção. No head final de produto `cb9b8d260c89ce80c7aaaf88b68c73cccfba8c22`, integrado pelo PR #23, comprovou:

- `BUYER_FAVORITE_ROUTES: PASS`;
- `BUYER_FAVORITE_ANONYMOUS_BLOCKED: PASS`;
- `BUYER_AUTH_PKCE_TOKEN: PASS`;
- `BUYER_FAVORITE_DRAFT_BLOCKED: PASS`;
- `BUYER_FAVORITE_IDEMPOTENT_ADD: PASS`;
- `BUYER_FAVORITE_MINE: PASS`;
- `BUYER_FAVORITE_PUBLIC_VISIBILITY: PASS`;
- `BUYER_FAVORITE_REMOVE: PASS`;
- `BUYER_FAVORITE_WEB: PASS`;
- `BUYER FAVORITES HTTP: PASSED`.

Nesse head passaram **16/16 workflows aplicáveis**: Architecture, Harness, Host, Fresh Migration, Gate 01, Product API, Listing Lifecycle, Listing Photo, Public Web, Public Buyer, Public Discovery, Seller Auth, Seller Shell, Seller Draft Edit, Seller Photos Publish e Buyer Favorites.

Como fechamento de segurança, o gate focado foi endurecido e executado novamente no head `37f84a6caa29b1c10a1406be98893b5b92c95710`. Ele criou um segundo usuário real de fixture e comprovou adicionalmente:

- Buyer B começa com `mine=[]` e `is-favorite=false` depois de Buyer A favoritar o Listing;
- Buyer A e Buyer B podem favoritar o mesmo Listing independentemente;
- Pause oculta a projeção para ambos e republish restaura cada relação persistida;
- remover o Favorite de Buyer A não remove a relação de Buyer B;
- `BUYER_FAVORITE_USER_ISOLATION: PASS`;
- `BUYER FAVORITES HTTP: PASSED`.

A autenticação de produto continua Authorization Code + PKCE. O password grant usado para obter o token do segundo usuário existe somente no caminho de fixture/smoke já estabelecido e não foi introduzido como UX de autenticação Buyer.

O primeiro run do novo gate falhou apenas porque o teste presumiu rotas REST diferentes das convenções realmente geradas pelo ABP. O Swagger observado mostrou `POST/DELETE /api/app/favorite?listingId=...` e que `IsFavoriteAsync` não recebia verbo GET pela convenção de nome. O contrato foi alinhado ao framework (`GetIsFavoriteAsync` e rotas geradas), sem controller customizado; o run seguinte passou integralmente.

O primeiro run da prova adicional de dois usuários falhou por uma declaração Bash incompatível com `set -u` na própria fixture (`local` expandia `username` antes da atribuição). A fixture foi corrigida sem mudança de produto, e o run seguinte passou a prova de isolamento completa.

Classe da evidência: **B — comportamento reproduzido em CI contra aplicação real**.

## Progress log

- 2026-08-23: Favorite selecionado após Plan 0005 por ser o menor gap vertical com estrutura de domínio/persistência já existente.
- 2026-08-23: fronteira Seller preservada; Buyer recebeu cliente OIDC dedicado em vez de generalização prematura.
- 2026-08-23: backend Favorite passou a derivar ownership de `ICurrentUser` e reutilizar a projeção pública de Listing para add/list/state.
- 2026-08-23: `/favoritos`, callback Buyer e CTA no detalhe público foram implementados no cliente Next existente atrás do boundary HTTP/OIDC.
- 2026-08-23: primeiro gate revelou apenas uma hipótese errada sobre convenções de rota ABP; contrato/cliente/teste foram alinhados ao Swagger executado.
- 2026-08-23: o Buyer Favorites HTTP Gate passou o fluxo completo e os 16 workflows aplicáveis ficaram verdes no head final de produto.
- 2026-08-23: fechamento adicional criou um segundo Buyer e comprovou isolamento de list/state/add/remove para o mesmo Listing; após corrigir uma falha restrita à fixture Bash, `BUYER_FAVORITE_USER_ISOLATION: PASS` ficou verde.

## Decision log

- OIDC Buyer dedicado, Authorization Code + PKCE.
- Ownership de Favorite exclusivamente por `ICurrentUser`.
- Relações Favorite são isoladas por Buyer mesmo quando apontam para o mesmo Listing.
- Favorite só pode ser criado para Listing atualmente público.
- `Meus favoritos` é uma projeção pública das relações persistidas; Pause oculta e republish restaura sem excluir a intenção.
- Usar as convenções HTTP geradas pelo ABP em vez de controller/rota artificial.
- Nenhuma infraestrutura nova neste plano.

## Resultado

**PASSA / CONCLUÍDO.** O Buyer agora percorre:

`Public Detail → Buyer login → Favorite/Unfavorite → Meus favoritos`

A capacidade reutiliza o aggregate/tabela existentes, preserva a fronteira Seller, mantém ownership no servidor, tem isolamento de dois Buyers comprovado por HTTP real e não adiciona infraestrutura.

## Gaps futuros

Perfil Buyer, alertas, compartilhamento de listas, ranking/analytics por Favorite e demais capacidades só devem ser abertos quando forem o menor gap real comprovado por nova auditoria.

# Execution Plan 0038 — Self-registered Buyer Favorites

Status: **ATIVO**

## Objetivo

Fortalecer a prova do ciclo Buyer sem adicionar feature: substituir a identidade privilegiada `admin` usada pelo Buyer Favorites E2E por um usuário comum criado pelo self-registration já comprovado nos Plans 0036/0037.

Vertical proof:

`fresh DB → self-registration → BuyerWeb Authorization Code + PKCE → Favorite → Meus favoritos`

## Contexto

Base remota verificada: `815a6b0f9cadbde944bd97a3d8f5c53b6e188f31`, após o merge do Plan 0037.

Evidência atual:

- o Plan 0036 provou self-registration real em banco fresco;
- o Plan 0037 conectou self-registration ao SellerWeb sem usar `admin` no caminho positivo;
- `scripts/buyer-favorites-http-smoke.sh` ainda autentica explicitamente `admin / 1q2w3E*` no Authorization Code + PKCE de `BomPraTi_BuyerWeb`;
- o mesmo smoke cria um segundo Buyer pela API administrativa `/api/identity/users` para provar isolamento;
- `admin` continua necessário apenas para montar o Seller/Listing fixture e publicar/pausar o anúncio; isso não faz parte da identidade Buyer.

## Escopo

- alterar somente o smoke Buyer Favorites existente;
- criar o Buyer principal anonimamente por `POST /api/account/register`;
- usar esse Buyer no login Account que alimenta Authorization Code + PKCE de `BomPraTi_BuyerWeb`;
- criar o segundo Buyer também por self-registration e preservar a prova de isolamento;
- manter `admin` somente nas operações de fixture Seller/Listing que exigem essa identidade no smoke atual;
- preservar Draft bloqueado, add idempotente, mine/is-favorite, isolamento, pause/republish e remove.

## Fora de escopo

- mudar política de self-registration;
- criar role Buyer;
- confirmação de e-mail;
- perfil Buyer;
- alterar Favorite/Listing;
- migration/schema/infra;
- duplicar o Buyer Auth flow em novo gate.

## Critérios de aceite

1. [ ] Buyer principal é criado via self-registration em banco fresco.
2. [ ] Buyer principal conclui Account login + Authorization Code/PKCE no cliente BuyerWeb.
3. [ ] o access token auto-cadastrado atravessa Draft blocked, Favorite add/mine/is-favorite e remove.
4. [ ] segundo Buyer é criado via self-registration e preserva isolamento de Favorites.
5. [ ] pause/republish continuam preservando a semântica já provada.
6. [ ] `admin` não é usado como identidade Buyer positiva.
7. [ ] nenhuma regra de produto, schema ou infraestrutura é adicionada.

## Decision log

- **DECIDIDO por evidência:** este slice é hardening de prova, não feature.
- **DECIDIDO:** reutilizar o Buyer Favorites HTTP Gate porque ele já prova o cliente `BomPraTi_BuyerWeb` e o ciclo de Favorites.
- **DECIDIDO:** manter `admin` apenas como fixture Seller/Listing; remover seu uso como Buyer.
- **NÃO DECIDIDO:** role Buyer, confirmação de e-mail ou perfil Buyer adicional.

## Progress log

- 2026-08-25: `main` remoto confirmado em `815a6b0f9cadbde944bd97a3d8f5c53b6e188f31`.
- 2026-08-25: gap reproduzido por leitura do smoke: BuyerWeb PKCE positivo autentica `admin`, e o segundo Buyer é criado via API administrativa.

# Execution Plan 0038 — Self-registered Buyer Favorites

Status: **CONCLUÍDO**

## Objetivo

Fortalecer a prova do ciclo Buyer sem adicionar feature: substituir identidades Buyer privilegiadas/admin-created no Buyer Favorites E2E por usuários comuns criados pelo self-registration já comprovado nos Plans 0036/0037.

Vertical proof:

`fresh DB → self-registration → BuyerWeb Authorization Code + PKCE → Favorite → Meus favoritos`

## Contexto

Base remota de abertura: `815a6b0f9cadbde944bd97a3d8f5c53b6e188f31`, após o merge do Plan 0037.

Evidência que abriu o slice:

- o Plan 0036 provou self-registration real em banco fresco;
- o Plan 0037 conectou self-registration ao SellerWeb sem usar `admin` no caminho positivo;
- `scripts/buyer-favorites-http-smoke.sh` ainda autenticava `admin / 1q2w3E*` no Authorization Code + PKCE de `BomPraTi_BuyerWeb`;
- o mesmo smoke criava um segundo Buyer pela API administrativa `/api/identity/users` para provar isolamento;
- `admin` era necessário apenas para montar o Seller/Listing fixture e publicar/pausar o anúncio.

## Escopo entregue

- Buyer principal criado anonimamente por `POST /api/account/register`;
- Buyer principal usado no login Account que alimenta Authorization Code + PKCE de `BomPraTi_BuyerWeb`;
- segundo Buyer também criado por self-registration antes da prova de isolamento;
- `admin` mantido somente nas operações de fixture Seller/Listing;
- preservadas as provas de Draft bloqueado, add idempotente, mine/is-favorite, isolamento, pause/republish e remove;
- nenhuma regra de produto, schema, migration ou infraestrutura adicionada.

## Fora de escopo

- mudar política de self-registration;
- criar role Buyer;
- confirmação de e-mail;
- perfil Buyer;
- alterar Favorite/Listing;
- migration/schema/infra;
- duplicar o Buyer Auth flow em novo gate.

## Critérios de aceite

1. [x] Buyer principal é criado via self-registration em banco fresco.
2. [x] Buyer principal conclui Account login + Authorization Code/PKCE no cliente BuyerWeb.
3. [x] o access token auto-cadastrado atravessa Draft blocked, Favorite add/mine/is-favorite e remove.
4. [x] segundo Buyer é criado via self-registration e preserva isolamento de Favorites.
5. [x] pause/republish continuam preservando a semântica já provada.
6. [x] `admin` não é usado como identidade Buyer positiva.
7. [x] nenhuma regra de produto, schema ou infraestrutura é adicionada.

## Evidência executada

Head funcional: `b20ad9212c3571c5052064e217c488f9d38407a5`.

Buyer Favorites HTTP Gate, run `32864593733`, job `97856606762`, em PostgreSQL fresco e host ABP real:

- `FRESH MIGRATION GATE: PASSED`
- `BUYER_FAVORITE_SELF_REGISTRATION: PASS`
- `BUYER_FAVORITE_ANONYMOUS_BLOCKED: PASS`
- `BUYER_AUTH_PKCE_TOKEN: PASS`
- `BUYER_FAVORITE_DRAFT_BLOCKED: PASS`
- `BUYER_FAVORITE_IDEMPOTENT_ADD: PASS`
- `BUYER_FAVORITE_MINE: PASS`
- `BUYER_FAVORITE_SECOND_SELF_REGISTRATION: PASS`
- `BUYER_FAVORITE_USER_ISOLATION: PASS`
- `BUYER_FAVORITE_PUBLIC_VISIBILITY: PASS`
- `BUYER_FAVORITE_REMOVE: PASS`
- `BUYER_FAVORITE_WEB: PASS`
- `BUYER FAVORITES HTTP: PASSED`
- Buyer Listing Report smoke: PASSED
- Moderation Report Inbox/Admin Surface smoke: PASSED

Harness Gate também passou no head funcional.

Classe da evidência: **B — comportamento observado/reproduzido no CI do BPT2**.

## Decision log

- **DECIDIDO por evidência:** este slice é hardening de prova, não feature.
- **DECIDIDO:** reutilizar o Buyer Favorites HTTP Gate porque ele já prova o cliente `BomPraTi_BuyerWeb` e o ciclo de Favorites.
- **DECIDIDO:** manter `admin` apenas como fixture Seller/Listing; remover seu uso como Buyer.
- **NÃO DECIDIDO:** role Buyer, confirmação de e-mail ou perfil Buyer adicional.

## Progress log

- 2026-08-25: `main` remoto confirmado em `815a6b0f9cadbde944bd97a3d8f5c53b6e188f31`.
- 2026-08-25: gap reproduzido por leitura do smoke: BuyerWeb PKCE positivo autenticava `admin`, e o segundo Buyer era criado via API administrativa.
- 2026-08-25: smoke alterado para self-registration dos dois Buyers, mantendo `admin` apenas como fixture Seller/Listing.
- 2026-08-25: head funcional passou Harness e Buyer Favorites HTTP Gate completo; smokes agregados de report/moderação também permaneceram verdes.

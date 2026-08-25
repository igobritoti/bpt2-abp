# Execution Plan 0037 — Self-registered Seller Shell

Status: **ATIVO**

## Objetivo

Fortalecer a prova do ciclo Seller sem adicionar feature: substituir a identidade privilegiada `admin` usada pelo Seller Shell E2E por um usuário comum criado pelo self-registration já comprovado no Plan 0036.

Vertical proof:

`fresh DB → self-registration → SellerWeb Authorization Code + PKCE → SellerProfile → Draft → My Listings`

## Contexto

Base remota verificada: `82d188e2bae90bad2eb65ab5d375b11915de3c4f`, após o merge do Plan 0036.

Evidência atual:

- o Plan 0036 provou `usuário anônimo → self-registration → identidade criada → autenticação com credencial própria`;
- `scripts/seller-shell-http-smoke.sh` ainda autentica explicitamente `admin / 1q2w3E*` antes de provar SellerProfile, Draft e My Listings;
- portanto, a prova Seller atual usa uma identidade privilegiada e não demonstra no mesmo runtime que um usuário comum auto-cadastrado consegue atravessar o Seller shell;
- o produto já permite `SellerProfile.Upsert` para a identidade autenticada; nenhuma role Seller nova foi definida como requisito.

## Escopo

- alterar somente o smoke Seller Shell existente;
- criar um usuário único anonimamente por `POST /api/account/register`;
- usar esse usuário no login Account que alimenta Authorization Code + PKCE de `BomPraTi_SellerWeb`;
- manter as provas existentes de OIDC discovery, PKCE/token, SellerProfile, Draft, My Listings e logout;
- não usar credencial `admin` no ciclo Seller positivo.

## Fora de escopo

- mudar política de self-registration;
- criar role Seller;
- confirmação de e-mail;
- onboarding guiado;
- alterar SellerProfile ou Listing;
- migration/schema/infra;
- duplicar o Seller Auth gate.

## Critérios de aceite

1. [ ] Seller Shell cria uma identidade via self-registration em banco fresco.
2. [ ] o usuário auto-cadastrado conclui Account login + Authorization Code/PKCE no cliente SellerWeb.
3. [ ] o mesmo access token cria e consulta SellerProfile.
4. [ ] o mesmo access token cria Draft e o encontra em My Listings.
5. [ ] logout existente continua verde.
6. [ ] o ciclo positivo Seller Shell não usa `admin`.
7. [ ] nenhuma regra de produto, schema ou infraestrutura é adicionada.

## Decision log

- **DECIDIDO por evidência:** este slice é hardening de prova, não feature; conecta duas capacidades já existentes.
- **DECIDIDO:** reutilizar o Seller Shell gate porque ele já é a prova real do cliente `BomPraTi_SellerWeb` e do primeiro onboarding Seller.
- **NÃO DECIDIDO:** role Seller, confirmação de e-mail ou onboarding adicional.

## Progress log

- 2026-08-25: `main` remoto confirmado em `82d188e2bae90bad2eb65ab5d375b11915de3c4f`.
- 2026-08-25: Public Discovery, Seller Hub, sitemap/admin hub, moderação histórica e wiring dos principais smokes foram auditados e não abriram gap material.
- 2026-08-25: gap de prova reproduzido por leitura do smoke: Seller Shell autentica `admin` antes de criar SellerProfile e Draft.

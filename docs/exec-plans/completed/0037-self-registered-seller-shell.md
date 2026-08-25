# Execution Plan 0037 — Self-registered Seller Shell

Status: **CONCLUÍDO**

## Objetivo

Fortalecer a prova do ciclo Seller sem adicionar feature: substituir a identidade privilegiada `admin` usada pelo Seller Shell E2E por um usuário comum criado pelo self-registration já comprovado no Plan 0036.

Vertical proof:

`fresh DB → self-registration → SellerWeb Authorization Code + PKCE → SellerProfile → Draft → My Listings`

## Contexto

Base remota verificada: `82d188e2bae90bad2eb65ab5d375b11915de3c4f`, após o merge do Plan 0036.

Antes deste slice:

- o Plan 0036 provou `usuário anônimo → self-registration → identidade criada → autenticação com credencial própria`;
- `scripts/seller-shell-http-smoke.sh` ainda autenticava explicitamente `admin / 1q2w3E*` antes de provar SellerProfile, Draft e My Listings;
- portanto, a prova Seller usava uma identidade privilegiada e não demonstrava no mesmo runtime que um usuário comum auto-cadastrado conseguia atravessar o Seller shell.

## Escopo executado

- somente `scripts/seller-shell-http-smoke.sh` mudou funcionalmente;
- o smoke cria um usuário único anonimamente por `POST /api/account/register`;
- essa identidade comum é usada no Account Login que alimenta Authorization Code + PKCE de `BomPraTi_SellerWeb`;
- o mesmo access token cria e consulta SellerProfile;
- o mesmo access token cria Draft e o encontra em My Listings;
- logout existente permanece no mesmo fluxo;
- `admin` deixou de ser usado no caminho positivo Seller Shell.

## Fora de escopo

- mudar política de self-registration;
- criar role Seller;
- confirmação de e-mail;
- onboarding guiado;
- alterar SellerProfile ou Listing;
- migration/schema/infra;
- duplicar o Seller Auth gate.

## Critérios de aceite

1. [x] Seller Shell cria uma identidade via self-registration em banco fresco.
2. [x] o usuário auto-cadastrado conclui Account login + Authorization Code/PKCE no cliente SellerWeb.
3. [x] o mesmo access token cria e consulta SellerProfile.
4. [x] o mesmo access token cria Draft e o encontra em My Listings.
5. [x] logout existente continua verde.
6. [x] o ciclo positivo Seller Shell não usa `admin`.
7. [x] nenhuma regra de produto, schema ou infraestrutura foi adicionada.

## Evidência executada

Head funcional: `0f7f9858b964d153866d152f97a503a35fa1357a`.

O **BPT2 Seller Shell HTTP Gate** passou no run `32863030144`, job `97851442541`, contra PostgreSQL 17 fresco e host ABP real.

Marcadores executados:

- `FRESH MIGRATION GATE: PASSED`
- build .NET: `0 Warning(s)` / `0 Error(s)`
- `SELLER_SHELL_OIDC_DISCOVERY: PASS`
- `SELLER_SHELL_SELF_REGISTRATION: PASS`
- `SELLER_SHELL_ACCOUNT_LOGIN: PASS`
- `SELLER_SHELL_PKCE_TOKEN: PASS`
- `SELLER_SHELL_PROFILE_UPSERT: PASS`
- `SELLER_SHELL_PROFILE_CURRENT: PASS`
- `SELLER_SHELL_DRAFT_CREATE: PASS`
- `SELLER_SHELL_MY_LISTINGS: PASS`
- `SELLER_SHELL_LOGOUT_ENDPOINT: PASS`
- `SELLER SHELL HTTP: PASSED`

O **BPT2 Harness Gate** também passou no head funcional.

Classe da evidência: **B — comportamento reproduzido em CI contra aplicação real**.

## Decision log

- **DECIDIDO por evidência:** um usuário comum auto-cadastrado consegue tornar-se Seller operacional usando somente capacidades já existentes.
- **DECIDIDO por evidência:** nenhuma role Seller adicional é necessária para o ciclo atual; criar uma agora seria requisito novo sem evidência.
- **DECIDIDO:** o Seller Shell E2E deixa de depender da identidade privilegiada `admin` no caminho positivo.
- **NÃO DECIDIDO:** confirmação de e-mail, role Seller futura ou onboarding adicional.

## Progress log

- 2026-08-25: `main` remoto confirmado em `82d188e2bae90bad2eb65ab5d375b11915de3c4f`.
- 2026-08-25: Public Discovery, Seller Hub, sitemap/admin hub, moderação histórica e wiring dos principais smokes foram auditados e não abriram gap material.
- 2026-08-25: gap de prova reproduzido: Seller Shell autenticava `admin` antes de criar SellerProfile e Draft.
- 2026-08-25: smoke alterado somente para registrar e autenticar usuário comum; restante do ciclo Seller preservado.
- 2026-08-25: self-review confirmou mudança funcional restrita ao bloco de registro e troca das credenciais do login positivo.
- 2026-08-25: Harness e Seller Shell HTTP Gate passaram no head funcional.

## Resultado

**PASSA / CONCLUÍDO.** O BPT2 agora possui uma prova única e contínua de:

`usuário anônimo → self-registration → SellerWeb PKCE → SellerProfile → Draft → My Listings`

sem depender de `admin` como identidade do vendedor.

# Execution Plan 0039 — Self-registered Buyer Listing Reports

Status: **CONCLUÍDO**

## Objetivo

Fortalecer a prova do ciclo Buyer sem adicionar feature: substituir os Buyers criados pela API administrativa no Buyer Listing Report E2E por usuários comuns criados via self-registration já comprovado nos Plans 0036–0038.

Vertical proof:

`fresh DB → self-registration → Buyer token → Listing Report → is-reported / isolation / history`

## Contexto

Base remota de início: `fe0b5a4497142a763754c4c8bb85c1c8b3685dae`, após o merge do Plan 0038.

Evidência inicial:

- Plans 0036–0038 provaram self-registration, Seller Shell e Buyer Favorites com usuários comuns;
- `scripts/buyer-listing-report-http-smoke.sh` criava dois Buyers via `POST /api/identity/users` usando `ADMIN_TOKEN`;
- `admin` era necessário somente para montar o Seller/Listing fixture e publicar/pausar o anúncio.

## Implementação

- `create_user()` administrativo foi substituído por `register_user()` anônimo via `POST /api/account/register`;
- os dois Buyers do smoke são auto-cadastrados;
- `admin` permanece apenas para SellerProfile, criação/publicação/pause da Listing fixture;
- nenhuma regra de Listing Report, schema, migration ou infraestrutura foi alterada.

## Fora de escopo preservado

- role Buyer;
- confirmação de e-mail;
- perfil Buyer;
- resolução/fechamento de report;
- mudança de regra de Listing Report;
- migration/schema/infra;
- novo workflow.

## Critérios de aceite

1. [x] os dois Buyers são criados via self-registration em banco fresco.
2. [x] nenhum Buyer positivo é provisionado por `/api/identity/users`.
3. [x] anonymous blocked e Draft blocked continuam verdes.
4. [x] report idempotente e `is-reported` continuam verdes.
5. [x] isolamento entre Buyers continua verde.
6. [x] histórico do report após pause continua verde.
7. [x] `admin` permanece apenas como fixture Seller/Listing.
8. [x] nenhuma regra de produto, schema ou infraestrutura é adicionada.

## Evidência executada

Buyer Favorites HTTP Gate, em PostgreSQL fresco, passou com:

- `BUYER_REPORT_ROUTES: PASS`
- `BUYER_REPORT_ANONYMOUS_BLOCKED: PASS`
- `BUYER_REPORT_SELF_REGISTRATION: PASS`
- `BUYER_REPORT_DRAFT_BLOCKED: PASS`
- `BUYER_REPORT_IDEMPOTENT: PASS`
- `BUYER_REPORT_PERSISTED: PASS`
- `BUYER_REPORT_USER_ISOLATION: PASS`
- `BUYER_REPORT_HISTORY_PRESERVED: PASS`
- `BUYER LISTING REPORT HTTP: PASSED`

Regressões agregadas também passaram: Buyer Favorites e Moderation Report Inbox/Admin Surface.

## Decision log

- **DECIDIDO por evidência:** este slice é hardening de prova, não feature.
- **DECIDIDO:** reutilizar o Buyer Favorites HTTP Gate porque ele já agrega o Buyer Listing Report smoke.
- **DECIDIDO:** manter `admin` apenas como fixture Seller/Listing.
- **NÃO PROMOVIDO:** role Buyer, confirmação de e-mail, perfil Buyer ou workflow de resolução de report.

## Progress log

- 2026-08-25: `main` remoto confirmado em `fe0b5a4497142a763754c4c8bb85c1c8b3685dae`.
- 2026-08-25: gap reproduzido: dois Buyers eram criados pela API administrativa `/api/identity/users`.
- 2026-08-25: smoke alterado para self-registration dos dois Buyers.
- 2026-08-25: Harness passou no head funcional.
- 2026-08-25: Buyer Favorites HTTP Gate passou integralmente; Listing Report confirmou self-registration, Draft block, idempotência, persisted state, isolamento e history preserved.

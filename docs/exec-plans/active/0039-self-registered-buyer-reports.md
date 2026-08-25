# Execution Plan 0039 — Self-registered Buyer Listing Reports

Status: **ATIVO**

## Objetivo

Fortalecer a prova do ciclo Buyer sem adicionar feature: substituir os Buyers criados pela API administrativa no Buyer Listing Report E2E por usuários comuns criados via self-registration já comprovado nos Plans 0036–0038.

Vertical proof:

`fresh DB → self-registration → Buyer token → Listing Report → is-reported / isolation / history`

## Contexto

Base remota verificada: `fe0b5a4497142a763754c4c8bb85c1c8b3685dae`, após o merge do Plan 0038.

Evidência atual:

- Plans 0036–0038 provaram self-registration, Seller Shell e Buyer Favorites com usuários comuns;
- `scripts/buyer-listing-report-http-smoke.sh` ainda cria explicitamente dois Buyers via `POST /api/identity/users` usando `ADMIN_TOKEN`;
- os tokens desses Buyers exercitam Draft blocked, report idempotente, `is-reported`, isolamento e histórico após pause;
- `admin` continua necessário somente para montar o Seller/Listing fixture e publicar/pausar o anúncio.

## Escopo

- alterar somente o smoke Buyer Listing Report existente;
- criar os dois Buyers anonimamente por `POST /api/account/register`;
- preservar a obtenção de token dos Buyers pelo cliente de teste existente;
- preservar anonymous blocked, Draft blocked, idempotência, persisted state, isolamento e history preserved;
- manter `admin` somente nas operações de fixture Seller/Listing.

## Fora de escopo

- role Buyer;
- confirmação de e-mail;
- perfil Buyer;
- resolução/fechamento de report;
- mudança de regra de Listing Report;
- migration/schema/infra;
- novo workflow.

## Critérios de aceite

1. [ ] os dois Buyers são criados via self-registration em banco fresco.
2. [ ] nenhum Buyer positivo é provisionado por `/api/identity/users`.
3. [ ] anonymous blocked e Draft blocked continuam verdes.
4. [ ] report idempotente e `is-reported` continuam verdes.
5. [ ] isolamento entre Buyers continua verde.
6. [ ] histórico do report após pause continua verde.
7. [ ] `admin` permanece apenas como fixture Seller/Listing.
8. [ ] nenhuma regra de produto, schema ou infraestrutura é adicionada.

## Decision log

- **DECIDIDO por evidência:** este slice é hardening de prova, não feature.
- **DECIDIDO:** reutilizar o Buyer Favorites HTTP Gate, que já agrega o Buyer Listing Report smoke.
- **DECIDIDO:** manter `admin` apenas como fixture Seller/Listing.

## Progress log

- 2026-08-25: `main` remoto confirmado em `fe0b5a4497142a763754c4c8bb85c1c8b3685dae`.
- 2026-08-25: gap reproduzido por leitura do smoke: dois Buyers são criados pela API administrativa `/api/identity/users`.

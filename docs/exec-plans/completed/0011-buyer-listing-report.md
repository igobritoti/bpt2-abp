# Execution Plan 0011 — Buyer Listing Report

Status: **COMPLETO**

## Objetivo

Abrir a primeira fatia real de moderação permitindo que um Buyer autenticado sinalize um Listing atualmente público, com persistência server-side e sem política de moderação prematura.

Fluxo:

`Public Listing → Buyer autenticado → sinalizar anúncio → sinal persistido`

## Evidência que abriu o slice

- `docs/PRODUCT.md` mantinha moderação como capacidade central ainda não implementada.
- Os ciclos públicos, Buyer, Seller e Lead já estavam comprovados.
- Marketplace já possuía identidade Buyer por `ICurrentUser` e autoridade de visibilidade pública por `IPublicListingQuery`.

## Escopo entregue

- `ListingReport` no Marketplace com `UserId`, `ListingId` e `CreatedAtUtc`.
- Um único sinal por Buyer+Listing.
- criação somente para Listing atualmente público;
- ownership derivado de `ICurrentUser`, sem `UserId` enviado pelo cliente;
- estado consultável pelo próprio Buyer;
- ação no detalhe público reutilizando a sessão `BomPraTi_BuyerWeb`;
- prova HTTP real no gate Buyer existente.

## Fora de escopo

- motivo/taxonomia de denúncia;
- texto livre;
- painel ou fila administrativa;
- remoção/suspensão automática de Listing;
- scoring, threshold, rate limiting distribuído ou jobs;
- resolução de perfil/PII do Buyer;
- notificação ao Seller.

## Critérios de aceite

- [x] rota convencional de report existe e exige autenticação;
- [x] Draft/private não pode ser reportado;
- [x] report de Listing público persiste;
- [x] repetição pelo mesmo Buyer é idempotente;
- [x] outro Buyer não herda o estado do primeiro;
- [x] sinal persistido continua registrado após o Listing deixar de ser público;
- [x] Public Web compila com a ação de sinalizar;
- [x] todos os 16 workflows aplicáveis ficaram verdes no head funcional.

## Evidência executada

Head funcional: `e18c951f35e600fa1e0a86c944390ce112250acc`.

Buyer Favorites HTTP Gate, em PostgreSQL fresco e host ABP real:

- `BUYER_REPORT_ROUTES: PASS`
- `BUYER_REPORT_ANONYMOUS_BLOCKED: PASS`
- `BUYER_REPORT_DRAFT_BLOCKED: PASS`
- `BUYER_REPORT_IDEMPOTENT: PASS`
- `BUYER_REPORT_PERSISTED: PASS`
- `BUYER_REPORT_USER_ISOLATION: PASS`
- `BUYER_REPORT_HISTORY_PRESERVED: PASS`
- `BUYER LISTING REPORT HTTP: PASSED`

O mesmo run preservou verde Buyer Favorites, Authorization Code + PKCE e o build de produção do Next.js. No head funcional, os 16 workflows aplicáveis passaram.

Classe da evidência: **B — comportamento observado/reproduzido no CI do BPT2**.

## Progress log

- 2026-08-23: slice aberto a partir do menor gap central ainda ausente: moderação.
- 2026-08-23: implementados aggregate, service, UI e smoke HTTP.
- 2026-08-23: primeiro Harness Gate falhou apenas por formato obrigatório do plan; produto não foi alterado.
- 2026-08-23: primeiro smoke funcional observou no Swagger a rota ABP `POST /api/app/listing-report/report/{listingId}`; cliente e teste foram alinhados sem controller customizado nem alteração de domínio.
- 2026-08-23: gate focal passou integralmente e o head funcional fechou 16/16 workflows verdes.

## Decision log

- 2026-08-23: o primeiro sinal de moderação não recebe motivo nem efeito automático; taxonomia/política permanece aberta até evidência operacional.
- 2026-08-23: o sinal é autenticado, pertence ao `ICurrentUser` e é idempotente por Buyer+Listing.
- 2026-08-23: criação exige Listing atualmente público; sinal já persistido é histórico e não é apagado quando a publicação muda.

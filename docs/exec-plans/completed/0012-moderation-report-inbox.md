# Execution Plan 0012 — Moderation Report Inbox

Status: **COMPLETO**

## Objetivo

Fechar o primeiro loop operacional de moderação expondo uma fila read-only de `ListingReport` somente para operador autorizado, sem inventar política de moderação.

Fluxo:

`Buyer sinaliza Listing → report persistido → operador admin autenticado consulta fila`

## Evidência que abriu o slice

- `docs/PRODUCT.md` define moderação e administração como capacidades centrais.
- O Plan 0011 já persiste `ListingReport`, mas o contrato existente só permitia criar o sinal e consultar o estado do próprio Buyer.
- Não existia query de moderação/admin consumindo os sinais persistidos.
- SEO básico já possuía metadata dinâmica no detalhe público; promoções, Vehicle Hub e ingestão não fechavam um loop operacional já iniciado.

## Escopo entregue

- query autenticada para listar reports;
- autorização restrita à role `admin` já existente no baseline ABP;
- retorno mínimo com identidade do report, Listing, título/status do Listing e instante do sinal;
- ordenação determinística por mais recente;
- histórico consultável mesmo quando o Listing deixa de estar público;
- nenhuma identidade/PII Buyer exposta na projeção;
- prova HTTP real cobrindo autorização, visibilidade e histórico.

## Fora de escopo

- motivo/taxonomia ou texto livre;
- aprovar/rejeitar denúncia;
- remover, pausar ou suspender Listing automaticamente;
- workflow/status de moderação;
- scoring, thresholds ou priorização;
- notificação ao Seller/Buyer;
- perfil/PII do Buyer;
- novo frontend/admin shell ou novo cliente OIDC.

## Critérios de aceite

- [x] rota convencional da inbox existe;
- [x] anônimo não acessa;
- [x] Buyer autenticado sem role admin não acessa;
- [x] admin autenticado recebe reports persistidos;
- [x] itens de Listings pausados continuam na fila como histórico;
- [x] query não expõe PII Buyer;
- [x] todos os workflows aplicáveis ficam verdes no head funcional.

## Evidência executada

Head funcional: `b8ec5cbb7366d6232201a6461ec35067d8bcb247`.

Buyer Favorites HTTP Gate, run `32726499321`, job `97428861411`, em PostgreSQL fresco e host ABP real:

- `MODERATION_REPORT_ROUTES: PASS`
- `MODERATION_REPORT_ANONYMOUS_BLOCKED: PASS`
- `MODERATION_REPORT_NON_ADMIN_BLOCKED: PASS`
- `MODERATION_REPORT_ADMIN_VISIBLE: PASS`
- `MODERATION_REPORT_BUYER_PII_HIDDEN: PASS`
- `MODERATION_REPORT_HISTORY_PRESERVED: PASS`
- `MODERATION REPORT INBOX HTTP: PASSED`

O mesmo run preservou verdes Buyer Favorites, Buyer Listing Report, fresh migration, build Release sem warnings/erros e build de produção do Next.js. No head funcional, os 14 workflows aplicáveis passaram.

Classe da evidência: **B — comportamento observado/reproduzido no CI do BPT2**.

## Progress log

- 2026-08-24: slice aberto a partir do gap operacional deixado pelo Plan 0011: sinal persistido sem consumidor de moderação.
- 2026-08-24: implementados contrato, query read-only restrita a `admin` e smoke HTTP.
- 2026-08-24: um Harness Gate intermediário falhou porque `repository-facts.md` ainda registrava zero planos ativos; o fato gerado foi sincronizado sem alteração de produto.
- 2026-08-24: Swagger confirmou a rota convencional `GET /api/app/moderation-listing-report-query`; não foi necessário controller customizado.
- 2026-08-24: a conversão de `ListingStatus` para string foi movida para depois do `ToListAsync` para não depender de tradução do provider EF; o comportamento final passou no gate real.
- 2026-08-24: head funcional fechou 14/14 workflows aplicáveis verdes.

## Decision log

- 2026-08-24: primeira inbox é read-only; política/ações de moderação continuam NÃO DECIDIDAS.
- 2026-08-24: autorização mínima reutiliza a role `admin` já presente no baseline ABP; não é criada taxonomia própria de roles neste slice.
- 2026-08-24: a projeção operacional não expõe `UserId` nem perfil/PII Buyer.
- 2026-08-24: report já ocorrido é histórico e permanece na inbox quando o Listing deixa de estar público.

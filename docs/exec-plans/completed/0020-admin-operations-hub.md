# Execution Plan 0020 — Admin Operations Hub

Status: **COMPLETO**

## Objetivo

Fechar o primeiro ponto de entrada comum para as superfícies administrativas já comprovadas no host:

`admin login no host → /admin → Moderação / Ingestão`

## Evidência que abriu o slice

- `PRODUCT.md` mantinha administração como capacidade central e um shell administrativo genérico como decisão ainda aberta.
- os Plans 0017 e 0018 já entregavam duas superfícies Razor internas reais no mesmo host: `/moderacao` e `/ingestao`.
- ambas as PageModels usam exatamente `[Authorize(Roles = "admin")]` e reutilizam o Account Web do host.
- `main/BomPraTi/Pages` continha apenas essas duas superfícies operacionais e não possuía ponto de entrada administrativo comum.
- Promoções, Buyer Alerts e JSON-LD continuavam sem implementação parcial pesquisável; iniciá-los exigiria conceito de produto ou vocabulário novo.
- o Product API Gate já executava PostgreSQL fresco, host real, Account Web e o fluxo de Ingestion, permitindo adicionar a prova focal sem inaugurar workflow novo.

## Escopo entregue

- Razor Page `/admin` no host existente;
- PageModel protegido pela mesma role `admin` das superfícies agregadas;
- hub sem dependências de application service ou dados próprios;
- links explícitos para `/moderacao` e `/ingestao`;
- smoke HTTP próprio incorporado ao Product API Gate existente;
- prova de anônimo, usuário autenticado sem `admin`, admin, links e destinos reais.

## Fora de escopo

- menu global do tema ABP ou `IMenuContributor`;
- layout administrativo compartilhado;
- dashboard, métricas, contadores ou novas queries;
- permissões administrativas granulares além da role `admin` atual;
- ações de moderação novas;
- autocomplete/matching/automação de Ingestion;
- novo frontend/admin SPA;
- backend, contrato, schema, migration ou infraestrutura nova.

## Critérios de aceite

1. [x] anônimo em `/admin` é enviado ao Account Login.
2. [x] usuário autenticado sem role `admin` é bloqueado.
3. [x] admin autenticado recebe `/admin` 200 e vê as duas operações existentes.
4. [x] os links apontam para `/moderacao` e `/ingestao` sem copiar lógica ou dados dessas superfícies.
5. [x] os boundaries de autorização e comportamento das páginas existentes permanecem intactos.
6. [x] o gate HTTP focal e os doze workflows aplicáveis passaram no head funcional.
7. [x] docs fecham somente o hub; menu/layout/dashboard/permissões granulares continuam NÃO DECIDIDOS.

## Evidência executada

Head funcional comprovado: `f03b68c0851927e22172478893cd6bd4810ee642`.

`BPT2 Product API Gate`, run `32751988092`, job `97510829630`, usando PostgreSQL fresco e host ABP real:

- `FRESH MIGRATION GATE: PASSED`
- build Release: `0 Warning(s)` / `0 Error(s)`
- `PRODUCT API SMOKE: PASSED`
- `INGESTION CANDIDATE HTTP: PASSED`
- `INGESTION ADMIN SURFACE HTTP: PASSED`
- `ADMIN_HUB_ANONYMOUS_BLOCKED: PASS`
- `ADMIN_HUB_NON_ADMIN_BLOCKED: PASS`
- `ADMIN_HUB_ADMIN_VISIBLE: PASS`
- `ADMIN_HUB_LINKS: PASS`
- `ADMIN_HUB_TARGETS_REACHABLE: PASS`
- `ADMIN OPERATIONS HUB HTTP: PASSED`

No mesmo head, os doze workflows aplicáveis concluíram `success`: Harness, Host, Listing Photo, Listing HTTP Lifecycle, Product API, Seller Auth, Seller Draft Edit, Public Discovery, Seller Photos/Publish, Seller Shell, Buyer Favorites e Public Buyer.

A prova usa login real do Account Web. O usuário sem role é criado pela API de Identity já existente e recebe 403 ou o redirect de AccessDenied; o admin recebe `/admin` 200. Os links são verificados no HTML e os dois destinos são acessados com a mesma sessão admin e retornam 200.

Classe da evidência: **B — comportamento observado/reproduzido no CI do BPT2**.

## Decision log

- **DECIDIDO:** `/admin` é somente composição/navegação das superfícies administrativas existentes; não cria nova autoridade de negócio.
- **DECIDIDO:** o primeiro hub reutiliza a role `admin` já comprovada, sem permission model paralelo.
- **DECIDIDO:** o hub não consulta contadores/dados; Moderação e Ingestion continuam autoridades dos próprios fluxos.
- **NÃO DECIDIDO:** menu global, layout administrativo compartilhado, dashboard/métricas, permissões granulares e frontend admin separado.

## Progress log

- 2026-08-24: `main` remoto confirmado em `36bb494145796c3ff0e5bf938b692465997cffe2` após merge do Plan 0019.
- 2026-08-24: auditoria confirmou duas superfícies admin reais e isoladas, sem hub comum; candidatos Promoções/Alerts/JSON-LD não possuíam implementação parcial equivalente.
- 2026-08-24: branch `feat/admin-operations-hub` criada e draft PR #39 aberto antes da implementação.
- 2026-08-24: `/admin` implementado como Razor Page sem dependências de negócio; smoke focal adicionado ao Product API Gate já existente.
- 2026-08-24: nenhum gate funcional falhou; Product API focal e 12/12 workflows aplicáveis passaram no head `f03b68c0851927e22172478893cd6bd4810ee642`.
- 2026-08-24: fechamento documental iniciado; readiness de merge deve usar CI fresco do head documental final.

# Execution Plan 0018 — Ingestion Admin Surface

Status: **COMPLETO**

## Objetivo

Fechar a primeira superfície visual operacional de Ingestion reutilizando o loop já comprovado no Plan 0014:

`candidate externo → fila pendente → admin login no host → /ingestao → reconciliar com Vehicle canônico`

## Evidência que abriu o slice

- `PRODUCT.md` mantinha Ingestion como capacidade central e UI de Ingestion como decisão aberta.
- o Plan 0014 já entregava `IIngestionCandidateAppService`, fila pendente, reconciliação para Vehicle canônico e role `admin` com prova HTTP real.
- o Plan 0017 já havia comprovado Razor Page interna no host ABP reutilizando Account Web e role `admin`, sem novo frontend/OIDC.
- Promoções e Buyer Alerts seguiam sem implementação parcial equivalente; enrichment/aggregate pages do Vehicle Hub exigiam decisões adicionais.
- portanto a menor extensão real era compor a API de Ingestion existente em uma superfície interna do host, sem alterar domínio ou schema.

## Escopo entregue

- `/ingestao` como Razor Page no host ABP;
- acesso restrito à role `admin`;
- leitura exclusivamente por `IIngestionCandidateAppService.GetPendingAsync`;
- exibição de Source, ExternalId, RawIdentity, Confidence e Provenance;
- formulário por candidate com `recordId` do registro persistido e `VehicleId` informado pelo operador;
- POST usa exclusivamente `IIngestionCandidateAppService.ReconcileAsync`;
- Vehicle inexistente é rejeitado, a página apresenta validação e o candidate permanece pendente;
- Vehicle canônico existente é aceito pelo backend e o candidate deixa de aparecer na fila;
- prova usa Account Web real e preserva integralmente as assertions de API do Plan 0014.

## Fora de escopo

- connector/source real;
- scraping, polling, scheduler ou background job;
- fuzzy/automatic matching e confidence threshold;
- criação/alteração automática do Catalog;
- workflow multiestado, approval/reject/undo;
- busca/autocomplete de Vehicle na UI;
- shell administrativo genérico;
- novo frontend ou cliente OIDC;
- schema/migration.

## Critérios de aceite

1. [x] `/ingestao` existe no host; anônimo e usuário sem `admin` não obtêm a fila.
2. [x] admin autenticado via Account Web vê candidate pendente real e seus campos já persistidos.
3. [x] formulário de reconcile usa `recordId` do servidor + `VehicleId` informado e não cria autoridade automotiva paralela.
4. [x] Vehicle inexistente não reconcilia nem remove o candidate da fila.
5. [x] Vehicle canônico existente reconcilia e o candidate deixa de aparecer na fila.
6. [x] nenhuma mudança de domínio/schema/migration/cliente OIDC foi introduzida.
7. [x] build e doze workflows aplicáveis passaram no head funcional; connector/matching/workflow continuam NÃO DECIDIDOS.

## Evidência executada

Head funcional comprovado: `4041c84e207521c437f91d9ac604c08145a28ca9`.

`BPT2 Product API Gate`, run `32745405828`, job `97489617742`, com PostgreSQL fresco, host ABP real, Account Web real e Vehicle canônico do fixture:

- `FRESH MIGRATION GATE: PASSED`
- build Release: `0 Warning(s)` / `0 Error(s)`
- `INGESTION_CANDIDATE_ROUTES: PASS`
- `INGESTION_ANONYMOUS_BLOCKED: PASS`
- `INGESTION_PAGE_ANONYMOUS_BLOCKED: PASS`
- `INGESTION_NON_ADMIN_BLOCKED: PASS`
- `INGESTION_PAGE_NON_ADMIN_BLOCKED: PASS`
- `INGESTION_ADMIN_CREATE: PASS`
- `INGESTION_EXTERNAL_ID_DEDUPED: PASS`
- `INGESTION_PENDING_VISIBLE: PASS`
- `INGESTION_UNKNOWN_VEHICLE_REJECTED: PASS`
- `INGESTION_CANONICAL_VEHICLE_RECONCILED: PASS`
- `INGESTION_RECONCILED_REMOVED_FROM_PENDING: PASS`
- `INGESTION CANDIDATE HTTP: PASSED`
- `INGESTION_PAGE_ADMIN_VISIBLE: PASS`
- `INGESTION_PAGE_UNKNOWN_VEHICLE_REJECTED: PASS`
- `INGESTION_PAGE_CANONICAL_VEHICLE_RECONCILED: PASS`
- `INGESTION_PAGE_RECONCILED_REMOVED: PASS`
- `INGESTION ADMIN SURFACE HTTP: PASSED`

No mesmo head, os doze workflows aplicáveis concluíram `success`: Harness, Host, Product API, Listing HTTP Lifecycle, Listing Photo, Public Buyer, Public Discovery, Buyer Favorites, Seller Auth, Seller Draft/Edit, Seller Shell e Seller Photos/Publish.

Classe da evidência: **B — comportamento observado/reproduzido no CI do BPT2**.

## Falhas observadas e correções focais

1. O primeiro Harness Gate detectou somente diferença de formatação em `repository-facts.md`: o gerador escreve o nome do plan ativo entre crases. O arquivo gerado foi alinhado sem mudança funcional.
2. A primeira prova da página chegou a HTTP 200 e aos campos do candidate, mas a assertion de `Confidence` dependia de uma representação não determinística. A view passou a reutilizar uma única representação invariant `0.###` para célula e atributo de prova.
3. A segunda prova demonstrou que o host não possuía `_ViewImports` com MVC TagHelpers: `asp-page-handler` era emitido literalmente e não havia antiforgery automático. A página passou a usar action explícita `/ingestao?handler=Reconcile`, `@Html.AntiForgeryToken()` e renderização explícita do `ModelState`; nenhuma regra de domínio mudou.
4. A terceira prova mostrou que a aplicação já rejeitava corretamente Vehicle inexistente e preservava o candidate, mas o teste procurava texto UTF-8 cru em HTML entity-encoded. O smoke passou a decodificar entidades HTML antes da assertion.

Nenhuma dessas correções enfraqueceu autorização, validação canônica ou gates.

## Decision log

- **DECIDIDO:** a primeira UI de Ingestion vive no host ABP existente em `/ingestao` e exige role `admin`.
- **DECIDIDO:** a UI consome somente `IIngestionCandidateAppService`; Catalog continua sendo a autoridade canônica validada pelo backend.
- **DECIDIDO:** Vehicle inexistente não reconcilia e não remove o candidate pendente; reconciliação bem-sucedida remove o registro da fila pendente existente.
- **NÃO DECIDIDO:** source/connector, matching automático, threshold, workflow de aprovação, background jobs, autocomplete/busca de Vehicle e shell admin genérico.

## Progress log

- 2026-08-24: `main` remoto confirmado em `092475e16e046bc92e13e89aa23cecded66e12b1` após o Plan 0017.
- 2026-08-24: auditoria confirmou `GetPendingAsync` + `ReconcileAsync` como implementação parcial suficiente e UI de Ingestion como menor gap componível sem novo subsistema.
- 2026-08-24: branch `feat/ingestion-admin-surface` criada e draft PR #37 aberto antes da implementação funcional.
- 2026-08-24: `/ingestao` implementado como Razor Page `admin` consumindo somente `IIngestionCandidateAppService`; a prova API do Plan 0014 foi preservada e uma candidate separada foi usada para a prova UI.
- 2026-08-24: falhas de harness/formatação e harness HTTP foram corrigidas uma por vez, sem ampliar o produto.
- 2026-08-24: head funcional `4041c84e207521c437f91d9ac604c08145a28ca9` fechou o gate focal e todos os doze workflows aplicáveis verdes.

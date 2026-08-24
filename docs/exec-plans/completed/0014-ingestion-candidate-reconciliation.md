# Execution Plan 0014 — Ingestion Candidate Reconciliation

Status: **COMPLETO**

## Objetivo

Fechar o primeiro loop operacional real do módulo Ingestion reutilizando o modelo e o boundary já existentes:

`candidate externo → registro persistido → fila pendente → operador admin reconcilia com Vehicle canônico`

## Evidência que abriu o slice

- `PRODUCT.md` mantém ingestão de fontes externas como capacidade central e o Catalog como autoridade canônica.
- `IngestionRecord` já persistia `Source`, `ExternalId`, `RawIdentity`, `Confidence`, `Provenance` e `ReconciledVehicleId`.
- `IngestionDbContext` já possuía índice único em `(Source, ExternalId)` e índice em `ReconciledVehicleId`.
- `IngestionCandidateDto` já existia em Contracts.
- Ingestion já dependia somente de `BomPraTi.Catalog.Contracts`, cujo `IVehicleCatalogReader` permite validar um `vehicleId` canônico.
- Promoções e Vehicle Hub não tinham implementação parcial equivalente; connector/job/UI de ingestão exigiriam decisões e infraestrutura ainda não justificadas.

## Escopo entregue

- `IIngestionCandidateAppService` exposto por conventional controllers ABP;
- todas as operações restritas à role `admin` já existente;
- criação de candidate preservando os campos já modelados;
- deduplicação pela identidade externa já congelada no schema, `(Source, ExternalId)`;
- fila read-only de registros com `ReconciledVehicleId == null`;
- reconciliação somente após validação do `Vehicle` por `IVehicleCatalogReader` em `Catalog.Contracts`;
- prova HTTP real integrada ao `BPT2 Product API Gate`.

## Fora de escopo

- connector para fonte externa real;
- scraping, polling, scheduler ou background job;
- fuzzy matching, threshold automático de confidence ou algoritmo de reconciliação;
- criação/alteração automática do catálogo canônico;
- UI/painel de ingestão;
- workflow multiestado, undo/reopen ou nova migration;
- promoções, Vehicle Hub e extensões não necessárias a este loop.

## Critérios de aceite

- [x] superfície HTTP de Ingestion existe via conventional controllers do ABP;
- [x] anônimo recebe 401 e usuário autenticado sem role `admin` recebe 403;
- [x] admin registra candidate preservando Source/ExternalId/RawIdentity/Confidence/Provenance;
- [x] repetir o mesmo `(Source, ExternalId)` reutiliza o mesmo registro e não cria segundo registro;
- [x] registro novo aparece na fila pendente;
- [x] reconciliation para `vehicleId` inexistente retorna 404 e mantém o registro pendente;
- [x] reconciliation para Vehicle canônico existente persiste `ReconciledVehicleId`;
- [x] registro reconciliado deixa de aparecer na fila pendente;
- [x] build, boundary guard, fresh database, prova HTTP focal e harness passaram no head funcional;
- [x] docs canônicos foram fechados sem transformar connector/job/UI em requisito.

## Evidência executada

Head funcional: `b1a1dfbb3b0cb16b69ef7ffbc629a5f585f1441c`.

`BPT2 Product API Gate`, run `32732015986`, após fresh database e seed de Vehicle canônico:

- `INGESTION_CANDIDATE_ROUTES: PASS`
- `INGESTION_ANONYMOUS_BLOCKED: PASS`
- `INGESTION_NON_ADMIN_BLOCKED: PASS`
- `INGESTION_ADMIN_CREATE: PASS`
- `INGESTION_EXTERNAL_ID_DEDUPED: PASS`
- `INGESTION_PENDING_VISIBLE: PASS`
- `INGESTION_UNKNOWN_VEHICLE_REJECTED: PASS`
- `INGESTION_CANONICAL_VEHICLE_RECONCILED: PASS`
- `INGESTION_RECONCILED_REMOVED_FROM_PENDING: PASS`
- `INGESTION CANDIDATE HTTP: PASSED`

No mesmo head também passaram Harness, Architecture, Host, Fresh Migration e Gate 01. O primeiro Product API run falhou somente porque o smoke presumiu incorretamente `{recordId}` no path; o Swagger observado demonstrou `/api/app/ingestion-candidate/reconcile` com `recordId` e `vehicleId` como query params. O teste foi corrigido sem alteração funcional.

Classe da evidência: **B — comportamento observado/reproduzido no CI do BPT2**.

## Progress log

- 2026-08-24: `main` remoto revalidado antes do slice; nenhum plano ativo ou blocker humano.
- 2026-08-24: auditoria encontrou Ingestion parcialmente modelado, mas sem superfície operacional.
- 2026-08-24: draft PR #33 aberto antes da implementação funcional.
- 2026-08-24: Harness inicialmente detectou apenas `repository-facts.md` desatualizado após abertura do plano; fato gerado foi sincronizado.
- 2026-08-24: primeiro smoke funcional encontrou apenas mismatch de rota esperada; Swagger foi tratado como evidência e o smoke ajustado.
- 2026-08-24: head funcional fechou todos os workflows aplicáveis verdes e o loop de reconciliation passou integralmente.

## Decision log

- **DECIDIDO para este slice:** operações de ingestão são internas e usam a role `admin` já existente; não foi criada identidade/role nova.
- **DECIDIDO para este slice:** o Catalog continua autoridade canônica; Ingestion só reconcilia para Vehicle validado por `IVehicleCatalogReader`.
- **DECIDIDO para este slice:** `(Source, ExternalId)` continua sendo a identidade externa deduplicada expressa pelo índice único existente; o primeiro registro é preservado porque o aggregate não oferece edição de payload.
- **NÃO DECIDIDO:** connector/source concreto, matching automático, threshold de confidence, workflow de aprovação, background jobs e UI.

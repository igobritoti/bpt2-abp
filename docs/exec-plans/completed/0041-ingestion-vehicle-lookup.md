# Execution Plan 0041 — Ingestion Vehicle Lookup

Status: **COMPLETO**

## Objetivo

Melhorar a superfície operacional de Ingestion sem criar nova autoridade: permitir que o admin encontre Vehicles canônicos por identidade textual antes de reconciliar um candidate, reutilizando o Catalog já existente.

Vertical proof:

`candidate pendente → admin /ingestao → busca Brand/Model/Generation/Version → Vehicle canônico visível → reconcile existente`

## Contexto

Base remota original: `921312d6601bac0eb07b71ff2c05a79575f282ef`, após o merge do Plan 0040.

Evidência que motivou o slice:

- o Plan 0018 deixou explicitamente autocomplete/busca de Vehicle fora de escopo e a UI exigia digitar `VehicleId` manualmente;
- o Plan 0034 adicionou `IVehicleCatalogReader.FindIdsByTextAsync`, com busca por Brand/Model/Generation/Version;
- `IVehicleCatalogReader.GetManyAsync` e `VehicleRefDto` já resolviam ids para identidade canônica legível;
- `IIngestionCandidateAppService.ReconcileAsync` já era e continua sendo a autoridade de reconciliação e validação do Vehicle canônico.

## Escopo entregue

- lookup server-side na Razor Page `/ingestao`, ainda restrita a `admin`;
- query textual opcional via GET;
- resolução por `IVehicleCatalogReader` usando apenas `Catalog.Contracts`;
- até 20 matches exibidos com Id, Brand, Model, Generation, Version e ModelYear;
- resultados também expostos em `datalist` para auxiliar o input de `VehicleId` já existente;
- query preservada durante tentativa/redirect de reconciliação;
- estado vazio explícito para busca sem resultado;
- smoke focal novo integrado ao Product API Gate já existente;
- nenhuma alteração em domínio, schema, migration, rota de reconciliação ou autoridade de Ingestion.

## Fora de escopo preservado

- matching automático;
- confidence threshold;
- sugestão automática baseada em `RawIdentity`;
- connector/source concreto;
- ranking/relevance avançado;
- autocomplete JavaScript;
- migration/schema/infra;
- novo workflow.

## Critérios de aceite

1. [x] admin consegue pesquisar Vehicle canônico por texto em `/ingestao`.
2. [x] busca encontra a fixture por identidade textual do Catalog, incluindo Model/Version/Generation.
3. [x] resultado expõe identidade canônica legível e o `VehicleId` real.
4. [x] ids encontrados ficam disponíveis no formulário de reconciliação sem substituir a validação backend.
5. [x] query sem match produz estado vazio explícito sem afetar candidates pendentes.
6. [x] anonymous/non-admin continuam bloqueados.
7. [x] reconcile inválido continua rejeitado e reconcile canônico continua removendo o candidate da fila.
8. [x] nenhuma regra de Ingestion, Catalog, schema ou infraestrutura foi adicionada.

## Evidência executada

No head funcional `b05ed9d8158f20cc2d0ec7f6e0db9aa7787e04da`, o `BPT2 Product API Gate` run `32869612377` concluiu com **success** em PostgreSQL fresco e host real.

Marcadores focais:

- `INGESTION_VEHICLE_LOOKUP_TEXT: PASS`
- `INGESTION_VEHICLE_LOOKUP_GENERATION: PASS`
- `INGESTION_VEHICLE_LOOKUP_EMPTY: PASS`
- `INGESTION VEHICLE LOOKUP HTTP: PASSED`

Regressões de Ingestion no mesmo gate permaneceram verdes, incluindo:

- `INGESTION_ANONYMOUS_BLOCKED: PASS`
- `INGESTION_PAGE_ANONYMOUS_BLOCKED: PASS`
- `INGESTION_NON_ADMIN_BLOCKED: PASS`
- `INGESTION_PAGE_NON_ADMIN_BLOCKED: PASS`
- `INGESTION_UNKNOWN_VEHICLE_REJECTED: PASS`
- `INGESTION_CANONICAL_VEHICLE_RECONCILED: PASS`
- `INGESTION_PAGE_UNKNOWN_VEHICLE_REJECTED: PASS`
- `INGESTION_PAGE_CANONICAL_VEHICLE_RECONCILED: PASS`
- `INGESTION ADMIN SURFACE HTTP: PASSED`
- `ADMIN OPERATIONS HUB HTTP: PASSED`

O build Release executado no gate concluiu com 0 warnings e 0 errors.

## Resultado

O operador de Ingestion não precisa mais descobrir/copiar um GUID canônico fora da superfície administrativa para reconciliar um candidate. Ele pode localizar a identidade automotiva existente por texto, inspecionar o Vehicle real e usar o mesmo `VehicleId` no fluxo de reconciliação já protegido e validado pelo backend.

O lookup é somente auxílio operacional: não interpreta `RawIdentity`, não decide match, não usa confidence para selecionar Vehicle e não altera a autoridade de `ReconcileAsync`.

## Decision log

- **DECIDIDO por evidência:** o gap tornou-se justificável depois que o Plan 0034 introduziu busca textual canônica reutilizável.
- **DECIDIDO:** o host usa `IVehicleCatalogReader` por `Catalog.Contracts`; não existe referência implementation-to-implementation.
- **DECIDIDO:** lookup somente auxilia escolha; `IIngestionCandidateAppService.ReconcileAsync` permanece autoridade final.
- **DECIDIDO:** limite visual de 20 matches evita lista operacional ilimitada e não representa política de ranking.
- **ADIADO:** matching automático, confidence threshold, connector concreto e autocomplete permanecem sem evidência suficiente para promoção.

## Progress log

- 2026-08-25: `main` remoto confirmado em `921312d6601bac0eb07b71ff2c05a79575f282ef`.
- 2026-08-25: ausência do lookup confirmada na Razor Page e no smoke atual de Ingestion.
- 2026-08-25: capacidade reutilizável confirmada em `IVehicleCatalogReader.FindIdsByTextAsync` + `GetManyAsync`.
- 2026-08-25: Razor Page, smoke focal e Product API Gate implementados sem alteração de domínio/schema.
- 2026-08-25: focal e regressões de Ingestion/Admin passaram no primeiro run funcional `32869612377`.

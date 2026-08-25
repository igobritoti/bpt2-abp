# Execution Plan 0041 — Ingestion Vehicle Lookup

Status: **ATIVO**

## Objetivo

Melhorar a superfície operacional de Ingestion sem criar nova autoridade: permitir que o admin encontre Vehicles canônicos por identidade textual antes de reconciliar um candidate, reutilizando o Catalog já existente.

Vertical proof:

`candidate pendente → admin /ingestao → busca Brand/Model/Generation/Version → Vehicle canônico visível → reconcile existente`

## Contexto

Base remota verificada: `921312d6601bac0eb07b71ff2c05a79575f282ef`, após o merge do Plan 0040.

Evidência atual:

- o Plan 0018 deixou explicitamente autocomplete/busca de Vehicle fora de escopo e a UI atual exige digitar `VehicleId` manualmente;
- `main/BomPraTi/Pages/Ingestao/Index.cshtml` renderiza somente um input textual `VehicleId canônico`;
- o Plan 0034 adicionou `IVehicleCatalogReader.FindIdsByTextAsync`, com busca por Brand/Model/Generation/Version;
- `IVehicleCatalogReader.GetManyAsync` e `VehicleRefDto` já permitem resolver os ids para identidade canônica legível;
- `IIngestionCandidateAppService.ReconcileAsync` continua sendo a única autoridade de reconciliação e valida a existência canônica.

## Escopo

- adicionar lookup server-side na Razor Page `/ingestao` restrita a admin;
- aceitar uma query textual opcional via GET;
- resolver um conjunto pequeno de Vehicles canônicos usando somente `Catalog.Contracts`;
- exibir Id + Brand + Model + Generation + Version + ModelYear dos matches;
- disponibilizar os ids encontrados como opções para o input de reconciliação existente;
- preservar validação e `ReconcileAsync` existentes;
- estender somente o smoke de Ingestion e o Product API Gate já existente.

## Fora de escopo

- matching automático;
- confidence threshold;
- sugestão automática baseada em `RawIdentity`;
- connector/source concreto;
- ranking/relevance avançado;
- autocomplete JavaScript;
- migration/schema/infra;
- novo workflow.

## Critérios de aceite

1. [ ] admin consegue pesquisar Vehicle canônico por texto em `/ingestao`.
2. [ ] busca encontra a fixture por Model/Version/Generation/Brand conforme o comportamento do Catalog existente.
3. [ ] resultado expõe identidade canônica legível e o `VehicleId` real.
4. [ ] ids encontrados ficam disponíveis no formulário de reconciliação sem substituir a validação backend.
5. [ ] query sem match produz estado vazio explícito sem afetar candidates pendentes.
6. [ ] anonymous/non-admin continuam bloqueados.
7. [ ] reconcile inválido continua rejeitado e reconcile canônico continua removendo o candidate da fila.
8. [ ] nenhuma regra de Ingestion, Catalog, schema ou infraestrutura é adicionada.

## Decision log

- **DECIDIDO por evidência:** este é um gap funcional operacional novo em relação ao Plan 0018, porque a busca textual canônica só passou a existir no Plan 0034.
- **DECIDIDO:** reutilizar `IVehicleCatalogReader` via `Catalog.Contracts`; o host não acessará implementação do módulo.
- **DECIDIDO:** lookup apenas auxilia escolha; `IIngestionCandidateAppService.ReconcileAsync` permanece autoridade final.
- **DECIDIDO:** limitar a apresentação a 20 matches para manter a superfície operacional pequena; não é decisão de ranking.

## Progress log

- 2026-08-25: `main` remoto confirmado em `921312d6601bac0eb07b71ff2c05a79575f282ef`.
- 2026-08-25: ausência do lookup confirmada na Razor Page e no smoke atual de Ingestion.
- 2026-08-25: capacidade reutilizável confirmada em `IVehicleCatalogReader.FindIdsByTextAsync` + `GetManyAsync`.

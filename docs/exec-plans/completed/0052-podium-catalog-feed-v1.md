# Plan 0052 — Podium catalog feed V1

Status: **CONCLUÍDO**

## Objetivo

Entregar o primeiro slice vertical de integração estrutural `Podium 7 -> BPT2 Catalog`, consumindo exclusivamente o contrato publicado Podium Catalog JSON `2.0`, preservando identidade externa estável e mantendo o marketplace independente da disponibilidade online do Podium.

## Evidência de entrada

- Podium 7 declarou o MVP técnico privado `PASS` e possui Catalog Identity V2 funcional.
- `CATALOG-JSON-CONTRACT-V2.md` congela a wire shape `2.0`, incluindo `entity.id` canônico e `redirectsFrom`.
- `CATALOG-CONSUMER-API-V2.md` define lookup/listagem transport-neutral e não emite IDs históricos como entidades canônicas separadas.
- `docs/PRODUCT.md` do BPT2 já congela a direção `Podium producer/feed -> contrato versionado publicado -> projeção BPT2 -> catálogo publicado BPT2` e proíbe shared database/matching por labels.
- O BPT2 já possui `IngestionRecord.Source + ExternalId + ReconciledVehicleId` e índice único `(Source, ExternalId)`.

## Escopo entregue

- adapter do payload Podium `contractVersion = "2.0"` com nomes JSON explicitamente congelados;
- validação fail-closed de versão e campos mínimos;
- projeção `make -> Brand`, `model -> VehicleModel`, `generation -> Generation`, `variant -> VehicleVersion` e model year somente quando semanticamente representável;
- vínculo `Source = "podium7"`, `ExternalId = entity.id` e `ReconciledVehicleId` no Ingestion boundary;
- `redirectsFrom` como aliases históricos do mesmo vínculo canônico, sem criar Vehicles adicionais;
- continuidade histórica: redirect previamente reconciliado faz o novo canonical ID herdar o mesmo `VehicleId`, sem rematching por labels;
- replay idempotente;
- fixture focado e workflow próprio do slice.

## Não escopo preservado

- chamada HTTP direta ao Podium ou dependência runtime do marketplace em Podium online;
- shared database;
- duplicar acquisition, evidence, normalization, entity resolution ou reconciliation do Podium;
- transportar powertrain, transmissão, body style ou enrichment técnico para Comparator;
- polling, scheduler ou background runner;
- resolver automaticamente `Podium entity.id == BPT2 VehicleId`.

## Mapeamento V1

- `entity.id` -> identidade externa persistida no Ingestion boundary;
- `entity.make` -> `Brand.Name`;
- `entity.model` -> `VehicleModel.Name`;
- `entity.generation` -> `Generation.Name` quando presente;
- `entity.variant` -> `VehicleVersion.Name`; `null` falha explicitamente porque o domínio atual exige `Vehicle.VersionId`;
- `model_year_from/model_year_to` -> `Vehicle.ModelYear` somente quando ambos são `null` ou quando `from == to`; ranges reais falham explicitamente;
- `manufacture_year_*` -> fora da projeção V1 enquanto o BPT2 não tiver dimensão equivalente explícita;
- `redirectsFrom` -> aliases históricos da identidade externa canônica, nunca Vehicles adicionais.

## Critérios de aceite — resultado

- contrato `2.0` válido: **PASSA**;
- versão diferente de `2.0`: **PASSA fail-closed**;
- replay/idempotência: **PASSA**;
- redirects e continuidade histórica: **PASSA**;
- `variant = null`: **PASSA fail-closed**;
- model-year range real: **PASSA fail-closed**;
- nenhuma dependência online do Podium no request path público: **PRESERVADO**;
- arquitetura modular: **PASSA**.

## Evidência executada

No head funcional/documental `1569e4060d52676bd5aff6fb0a4fe205316c863b`, os gates aplicáveis concluíram verdes:

- BPT2 Podium Catalog Feed Gate;
- BPT2 Fresh Migration Gate;
- BPT2 Gate 01;
- BPT2 Product API Gate;
- BPT2 Architecture Gate;
- BPT2 Host Gate;
- BPT2 Harness Gate.

Durante a validação, o primeiro head executável revelou `TypeLoadException` porque `PodiumCatalogFeedAppService` estava `sealed`; ABP/Autofac precisava gerar proxy da classe. A correção removeu somente `sealed`, após o que o bootstrap, migrations e gates funcionais passaram. Nenhum contrato foi relaxado.

## Progress log

- 2026-08-27 — branch `feat/podium-catalog-feed-v1` aberta e PR #90 criado em draft.
- 2026-08-27 — modelo BPT2 confirmou `Vehicle.VersionId` obrigatório, `ModelYear?` escalar e ownership do vínculo no Ingestion boundary.
- 2026-08-27 — wire DTO `2.0`, adapter, vínculo canônico/redirects e fixture focado implementados.
- 2026-08-27 — CI encontrou incompatibilidade ABP proxy x classe `sealed`; causa corrigida sem mudar semântica.
- 2026-08-27 — generated repository facts sincronizados.
- 2026-08-27 — todos os gates aplicáveis ficaram verdes no head `1569e4060d52676bd5aff6fb0a4fe205316c863b`.

## Decision log

- `entity.id` Podium é a identidade externa do vínculo; labels são dados projetados, não chave persistida.
- `redirectsFrom` converge para a mesma projeção BPT2 e preserva continuidade histórica.
- `variant = null` não recebe placeholder.
- model-year range real não é colapsado para um limite arbitrário.
- `IngestionRecord` permanece owner de provenance/reconciliation/import state.
- enrichment/Comparator permanece fora deste slice.

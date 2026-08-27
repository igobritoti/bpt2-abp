# Plan 0052 — Podium catalog feed V1

Status: **ATIVO**

## Objetivo

Entregar o primeiro slice vertical de integração estrutural `Podium 7 -> BPT2 Catalog`, consumindo exclusivamente o contrato publicado Podium Catalog JSON `2.0`, preservando identidade externa estável e mantendo o marketplace independente da disponibilidade online do Podium.

## Evidência de entrada

- Podium 7 declarou o MVP técnico privado `PASS` e possui Catalog Identity V2 funcional.
- `CATALOG-JSON-CONTRACT-V2.md` congela a wire shape `2.0`, incluindo `entity.id` canônico e `redirectsFrom`.
- `CATALOG-CONSUMER-API-V2.md` define lookup/listagem transport-neutral, paginação por cursor e sem emissão separada de IDs históricos.
- `docs/PRODUCT.md` do BPT2 já congela a direção `Podium producer/feed -> contrato versionado publicado -> projeção BPT2 -> catálogo publicado BPT2` e proíbe shared database/matching por labels.
- O BPT2 já possui `IngestionRecord.Source + ExternalId + ReconciledVehicleId`, permitindo preservar o vínculo com identidade externa sem transformar labels em chave de integração.

## Escopo

- aceitar payload estrutural Podium `contractVersion = "2.0"`;
- validar fail-closed versão e campos mínimos necessários;
- projetar `make -> Brand`, `model -> VehicleModel`, `generation -> Generation`, `variant -> VehicleVersion` e ano compatível com o modelo corrente;
- persistir vínculo `Source = "podium7"`, `ExternalId = entity.id` e `ReconciledVehicleId` após publicação no Catalog;
- tratar `redirectsFrom` como aliases históricos do mesmo vínculo canônico, sem criar Vehicles adicionais;
- garantir replay idempotente do mesmo payload;
- comprovar leitura do Vehicle criado/projetado pelo reader público do Catalog/Vehicle Hub boundary existente.

## Não escopo

- chamada HTTP direta ao Podium ou dependência runtime do marketplace em Podium online;
- shared database;
- duplicar acquisition, evidence, normalization, entity resolution ou reconciliation do Podium;
- inferir identidade por labels quando já existe `entity.id`;
- transportar powertrain, transmissão, body style ou enrichment técnico para Comparator;
- polling, scheduler ou background runner;
- resolver automaticamente relações `Podium entity.id == BPT2 VehicleId`.

## Mapeamento V1

- `entity.id` -> identidade externa Podium persistida no Ingestion boundary;
- `entity.make` -> `Brand.Name`;
- `entity.model` -> `VehicleModel.Name`;
- `entity.generation` -> `Generation.Name` quando presente;
- `entity.variant` -> `VehicleVersion.Name`; `null` falha explicitamente porque o domínio atual exige `Vehicle.VersionId`;
- `model_year_from/model_year_to` -> `Vehicle.ModelYear` somente quando ambos são `null` ou quando representam um único ano (`from == to`); ranges reais falham explicitamente;
- `manufacture_year_*` -> fora da projeção V1 enquanto o BPT2 não tiver dimensão equivalente explícita;
- `redirectsFrom` -> aliases históricos da identidade externa canônica, nunca Vehicles adicionais;
- nomes internos com underscore do contrato Podium (`body_style`, `model_year_from`, etc.) são congelados explicitamente no DTO de wire e não dependem do naming convention C#.

## Critérios de aceite

- payload `2.0` válido produz no máximo a projeção estrutural explicitamente suportada pelo modelo BPT2;
- versão diferente de `2.0` falha explicitamente;
- replay do mesmo `entity.id` não cria duplicata;
- ID histórico Podium em `redirectsFrom` converge para o mesmo Vehicle BPT2, inclusive quando o ID histórico já havia sido importado antes da canonicalização;
- labels não são usadas como chave persistida do vínculo Podium -> BPT2;
- nenhuma chamada ao Podium entra no request path público;
- testes estritamente necessários cobrem validação de contrato, idempotência, redirect e continuidade histórica;
- CI final fresco no head exato e review/base refresh limpos antes de merge.

## Checkpoints

1. **FEITO** — adapter/DTO de entrada `2.0` com nomes JSON congelados e regra fail-closed.
2. **FEITO** — `variant = null` e model-year range definidos como não projetáveis no V1.
3. **FEITO** — persistência do vínculo externo canônico e aliases históricos via Ingestion boundary existente.
4. **FEITO** — projeção Catalog usando `ICanonicalVehicleAdminAppService`/Contracts existentes.
5. **EM VALIDAÇÃO** — fixture focado + workflow cobrindo replay, redirects, continuidade histórica e casos fail-closed.
6. **PENDENTE** — CI final, self-review final, base refresh e merge somente verde.

## Decisões abertas necessárias

Nenhuma decisão semântica permanece aberta no V1. Falhas de CI podem revelar correções de implementação/teste, mas não autorizam relaxar os contratos acima.

## Progress log

- 2026-08-27 — nova evidência externa: Podium 7 MVP técnico privado `PASS` e contrato Catalog JSON `2.0` congelado.
- 2026-08-27 — branch `feat/podium-catalog-feed-v1` aberta sobre `main` `670da15f24a2b9c438b48d3b9a7fbfebe09a51d3`; PR #90 aberto em draft.
- 2026-08-27 — inspeção do BPT2 confirmou `Vehicle.VersionId` obrigatório, `ModelYear?` escalar e `IngestionRecord` com `Source/ExternalId/ReconciledVehicleId` + índice único `(Source, ExternalId)`.
- 2026-08-27 — wire DTO `2.0` adicionado com `JsonPropertyName` explícito para preservar exatamente o casing misto do Podium.
- 2026-08-27 — `PodiumCatalogFeedAppService` implementado no Ingestion boundary; canonical ID e redirects convergem para o mesmo `VehicleId`, e um redirect previamente reconciliado vence labels alterados em replay posterior.
- 2026-08-27 — fixture `BomPraTi.PodiumCatalogFeedFixture` adicionado cobrindo replay/idempotência, redirects, continuidade de ID histórico e fail-closed para contract version, variant nulo e model-year range.
- 2026-08-27 — workflow `BPT2 Podium Catalog Feed Gate` adicionado; no head `0b0376aed5a2b48c991316844bd528d5718d1fd6`, os gates aplicáveis foram disparados e permanecem em fila de GitHub Actions no último checkpoint desta sessão.

## Decision log

- 2026-08-27 — o primeiro slice será estrutural; enrichment/Comparator permanece fora.
- 2026-08-27 — `entity.id` Podium é a chave de integração externa; nomes são dados projetados, não identidade persistida do vínculo.
- 2026-08-27 — `redirectsFrom` preserva histórico e deve convergir para a mesma projeção BPT2; se um redirect já estiver ligado a Vehicle, o novo canonical ID herda esse vínculo sem rematching por labels.
- 2026-08-27 — `variant = null` não é projetável no V1 porque o domínio BPT2 exige Version; nenhum placeholder será inventado.
- 2026-08-27 — model-year range real não é projetável no V1 porque `Vehicle.ModelYear` é escalar; nenhum limite do range será escolhido arbitrariamente.
- 2026-08-27 — `IngestionRecord` permanece o ownership do vínculo/provenance no slice, coerente com `ARCHITECTURE.md`; nenhuma nova persistence paralela foi criada.
- 2026-08-27 — qualquer incompatibilidade semântica entre o contrato Podium e o domínio BPT2 deve falhar/adiar projeção, nunca ser preenchida por opinião.

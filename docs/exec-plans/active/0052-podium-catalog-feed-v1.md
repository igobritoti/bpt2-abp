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

## Mapeamento inicial

- `entity.id` -> identidade externa Podium persistida no Ingestion boundary;
- `entity.make` -> `Brand.Name`;
- `entity.model` -> `VehicleModel.Name`;
- `entity.generation` -> `Generation.Name` quando presente;
- `entity.variant` -> `VehicleVersion.Name`; quando ausente, o slice deve decidir por evidência se existe representação estrutural segura sem inventar label;
- `model_year_from/model_year_to` -> não colapsar automaticamente para um único `Vehicle.ModelYear` sem regra comprovada;
- `manufacture_year_*` -> fora da projeção V1 enquanto o BPT2 não tiver dimensão equivalente explícita;
- `redirectsFrom` -> aliases históricos da identidade externa canônica, nunca Vehicles adicionais.

## Critérios de aceite

- payload `2.0` válido produz no máximo a projeção estrutural explicitamente suportada pelo modelo BPT2;
- versão diferente de `2.0` falha explicitamente;
- replay do mesmo `entity.id` não cria duplicata;
- lookup por ID histórico Podium, quando representado por `redirectsFrom`, converge para o mesmo Vehicle BPT2;
- labels não são usadas como chave de vínculo Podium -> BPT2;
- nenhuma chamada ao Podium entra no request path público;
- testes estritamente necessários cobrem validação de contrato, idempotência, redirect e leitura do catálogo;
- CI final fresco no head exato e review/base refresh limpos antes de merge.

## Checkpoints

1. Congelar adapter/DTO de entrada `2.0` e regra fail-closed.
2. Resolver representação segura para `variant = null` e intervalo de model year sem inventar semântica.
3. Implementar persistência do vínculo externo canônico e aliases históricos.
4. Implementar projeção Catalog usando boundaries existentes.
5. Adicionar smoke/regressivos mínimos e documentação factual.
6. CI final, self-review, base refresh e merge somente verde.

## Decisões abertas necessárias

- **variant nulo:** o domínio atual exige `Vehicle.VersionId`; decidir por evidência se o payload pode ser publicado sem variant ou deve permanecer não projetável/reviewável.
- **intervalo de model year:** `Vehicle` possui apenas `ModelYear?`; não escolher um ano arbitrário de um range.
- **ownership do vínculo:** preferir Ingestion boundary existente se ele suportar unicidade/aliases sem acoplamento indevido; caso contrário documentar a menor extensão necessária.

## Progress log

- 2026-08-27 — nova evidência externa: Podium 7 MVP técnico privado `PASS` e contrato Catalog JSON `2.0` congelado.
- 2026-08-27 — branch `feat/podium-catalog-feed-v1` aberta sobre `main` `670da15f24a2b9c438b48d3b9a7fbfebe09a51d3`.
- 2026-08-27 — inspeção do BPT2 confirmou `Vehicle.VersionId` obrigatório, `ModelYear?` escalar e `IngestionRecord` com `Source/ExternalId/ReconciledVehicleId`; estes limites impedem mapping ingênuo de variant nulo e ranges de ano.

## Decision log

- 2026-08-27 — o primeiro slice será estrutural; enrichment/Comparator permanece fora.
- 2026-08-27 — `entity.id` Podium é a chave de integração externa; nomes são dados projetados, não identidade do vínculo.
- 2026-08-27 — `redirectsFrom` preserva histórico e deve convergir para a mesma projeção BPT2.
- 2026-08-27 — qualquer incompatibilidade semântica entre o contrato Podium e o domínio BPT2 deve falhar/adiar projeção, nunca ser preenchida por opinião.

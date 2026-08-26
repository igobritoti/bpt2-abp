# Plan 0048 — PBEV reconciliation and Podium 7 catalog boundary

Status: **CONCLUÍDO**

## Objetivo

Provar ou refutar uma integração segura entre o Podium 7 e o catálogo do BPT2, preservando a regra de produto de que o Bom Pra Ti é o dono do catálogo publicado, sem duplicar no BPT2 a aquisição/reconciliação/evidence pipeline que já existe no Podium 7 e sem autorizar ainda a implementação do Comparador.

## Base congelada

- partir do `main` após merge do PR #67 em `1471de8f69d0216f09d6c42c57a2ccbba900b2d7`;
- Plan 0047 concluído e arquivado;
- matriz do Plan 0046 define reconciliation/enrichment PBEV como boundary antes do Comparador;
- `Vehicle` BPT2 referencia `BrandId`, `ModelId`, `GenerationId?`, `VersionId` e `ModelYear?`;
- `VehicleVersion` referencia `ModelId`, `GenerationId?`, `Name` e `NormalizedName`;
- Podium 7 (`tihotm/podium7`) é um sistema Python separado de aquisição, integração, reconciliação, revisão e exportação de conhecimento automotivo;
- Podium 7 já possui Catalog Identity V2, persistence/redirects, consumer reads, batch ingestion, review durável e benchmarks de identidade;
- Podium 7 já possui contrato JSON congelado `2.0` e documento de consumer contract para Bom Pratiche/Bom Pra Ti;
- a regra declarada pelo owner em 25/08/2026 é: Bom Pra Ti é o dono do catálogo publicado; Podium 7 será o aplicativo que o alimenta.

## Problema

O problema original de reconciliar PBEV diretamente dentro do BPT2 mudou após a descoberta do papel real do Podium 7. O Podium já implementa exatamente as responsabilidades de aquisição, evidence/provenance, normalização, entity resolution, conflitos, revisão e exportação que o Plan 0048 estava prestes a reexperimentar no BPT2.

Reimplementar isso no BPT2 criaria dois motores concorrentes de identidade e duas noções de catálogo canônico. Por outro lado, simplesmente apontar ambos para o mesmo banco ou fundir os runtimes também criaria acoplamento entre Python/SQLite e .NET/PostgreSQL sem evidência de necessidade.

A decisão separa quatro conceitos:

1. **product ownership** — Bom Pra Ti decide o catálogo que publica e consome;
2. **knowledge acquisition/resolution** — Podium 7 coleta evidência, resolve identidade, preserva conflitos e produz conhecimento candidato/canônico do seu bounded context;
3. **published catalog persistence** — BPT2 persiste a representação usada pelo marketplace;
4. **integration contract** — transformação/versionamento entre a identidade Podium e a identidade BPT2.

## Hipóteses testadas

1. Podium 7 e BPT2 são bounded contexts diferentes: knowledge acquisition/resolution vs marketplace/published catalog. **PASS**.
2. Manter os repositórios separados e integrar inicialmente por export/import versionado oferece menor acoplamento total que unificar runtimes ou compartilhar banco. **PASS com evidência atual**.
3. A integração pode ser assíncrona/batch; nenhuma evidência atual exige Podium 7 no request path do marketplace. **PASS**.
4. O contrato Podium `2.0` é rico o bastante para um adapter BPT2 sem acessar SQLite interno nem reimplementar resolver. **PASS no experimento de projeção**.
5. O modelo BPT2 atual não é isomórfico ao Podium. **PASS**.
6. `Podium entity.id -> BPT2 VehicleId` não é relação geral 1:1. **PASS; caso 1:N demonstrado para model-year range**.
7. Compartilhar schema/database adicionaria acoplamento sem necessidade observada. **REPROVADO como opção inicial**.
8. HTTP/microservice wrapper não possui requisito online que justifique seu custo hoje. **ADIADO**.

## Opções arquiteturais testadas

### A — projetos/repositórios separados + contrato export/import

**SELECIONADA.**

Podium 7 mantém sua pipeline e exporta contrato versionado. BPT2 possui adapter/importer e persiste sua projeção publicada.

### B — monorepo, bounded contexts/runtimes separados

**NÃO SELECIONADA.**

Não resolve o mapping semântico e não houve ganho mensurável de coordenação/build que compense combinar Python/.NET no mesmo change surface.

### C — unificação de runtime/modelo

**REPROVADA COM A EVIDÊNCIA ATUAL.**

Exigiria reescrita/transplante de resolver/evidence/benchmarks do Podium sem requisito de transação compartilhada ou coupling de request.

### D — serviço distribuído síncrono (HTTP/RPC)

**ADIADA.**

Não existe consumidor online concreto que exija Podium no request path. O adapter Podium é transport-neutral e o marketplace deve continuar lendo seu catálogo publicado quando Podium estiver offline.

## Evidência executável

Foram adicionados:

- `scripts/podium7-contract-projection-experiment.py`;
- `scripts/fixtures/podium7-catalog-contract-v2-projection.json`.

O fixture adversarial cobre:

- replay do mesmo contrato;
- model-year range 2025–2026 projetado 1:N;
- correção mantendo o mesmo Podium ID;
- dois Podium IDs diferentes com labels iguais;
- merge explícito posterior via `redirectsFrom`;
- estado publicado local copiável/servível sem callback para Podium.

Execução observada:

```text
PODIUM7_CONTRACT_VERSION: PASS
PODIUM7_REPLAY_IDEMPOTENT: PASS
PODIUM7_MODEL_YEAR_1_TO_N: PASS
PODIUM7_STABLE_ID_CORRECTION: PASS
PODIUM7_NO_LABEL_RESOLUTION: PASS
PODIUM7_REDIRECT_MERGE: PASS
PODIUM7_OFFLINE_PUBLICATION_STATE: PASS
```

O experimento foi integrado ao `BPT2 Harness Gate` para regressão mecânica.

## Authority matrix decidida

| Concern | Authority |
|---|---|
| source acquisition | Podium 7 |
| raw evidence/provenance | Podium 7 |
| normalization/entity resolution | Podium 7 |
| unresolved identity review | Podium 7 |
| published marketplace catalog policy | BPT2 |
| marketplace availability/read path | BPT2 |
| Listing → published catalog reference | BPT2 |
| integration wire semantics | shared/versioned contract |

Não existem dois writers para a mesma decisão.

## Não escopo concluído

Este plano **não** implementou:

- Comparador;
- bulk import do catálogo;
- fuzzy/LLM matching no BPT2;
- shared database;
- HTTP/RPC/queue;
- unificação de repositórios/runtimes;
- production adapter/persistence final.

## Critérios de aceite

1. authority matrix explícita e sem dois writers: **PASS**;
2. contrato Podium consumido sem persistence interna: **PASS**;
3. fields extras, nulls, years e external IDs mantidos no contract fixture: **PASS**;
4. redirects e replay sem duplicata silenciosa: **PASS**;
5. cardinalidade 1:N medida em fixture adversarial: **PASS**;
6. BPT2 read state independente de Podium online no desenho/projeção: **PASS experimental**;
7. nenhuma opção promovida por preferência de linguagem/repo: **PASS**;
8. opção selecionada tem menor custo/risco para requisitos observados: **PASS C apoiado por A/B**;
9. HTTP/microservice adiado sem requisito online: **PASS**;
10. Comparador permanece bloqueado até catálogo/enrichment publicado suficiente: **PASS**.

## Checkpoints

- [x] CP1 — fonte PBEV/schema observado congelados;
- [x] CP2 — catálogo BPT2 atual e ausência de corpus real versionado registrados;
- [x] CP2b — papel do Podium 7 e seus contratos atuais auditados;
- [x] CP3 — authority matrix e contract fixture Podium→BPT2 congelados;
- [x] CP4 — adapter/replay/redirect/cardinality test executados;
- [x] CP5 — opções A/B/C/D comparadas com resultados locais e evidência externa;
- [x] CP6 — decisão final e próximo slice escolhido.

## Decision log

- Bom Pra Ti é o owner do catálogo publicado; Podium 7 é o alimentador/knowledge integration producer;
- o experimento PBEV direto no BPT2 foi superseded pela descoberta de que Podium já implementa essa responsabilidade;
- projetos permanecem separados;
- integração inicial será assíncrona por contrato versionado;
- não copiar resolver/evidence pipeline do Podium para BPT2;
- não usar labels para resolver novamente entidades já identificadas pelo Podium;
- Podium stable ID é identidade externa do mapping, não `VehicleId` BPT2;
- uma identidade Podium pode mapear para zero/um/muitos `VehicleId` BPT2;
- nenhum shared database;
- nenhum HTTP/microservice/queue até existir requisito concreto;
- Comparador permanece fora deste slice;
- decisão arquitetural registrada em `docs/adr/0011-podium7-catalog-integration-boundary.md`.

## Próximo slice funcional

Criar no BPT2 apenas o **contrato/persistência de publication mapping do Podium**, capaz de representar:

- Podium canonical external ID;
- historical Podium ID → canonical Podium ID;
- zero/um/muitos BPT2 `VehicleId` para uma identidade Podium;
- contract version importada;
- snapshot/revision identity suficiente para replay idempotente.

Aceite inicial: executar o fixture já congelado contra persistência real BPT2 e obter as mesmas invariantes do experimento puro. Não importar todo o catálogo nem criar transporte distribuído nesse slice.

## Progress log

- 2026-08-25 — PR #67 integrado; `main` BPT2 verificado em `1471de8f69d0216f09d6c42c57a2ccbba900b2d7`.
- 2026-08-25 — fonte oficial PBEV e ausência de `ModelYear` na linha registradas.
- 2026-08-25 — BPT2 Catalog verificado: `Vehicle` usa `ModelYear?`; `VehicleVersion` não possui ano.
- 2026-08-25 — repositório BPT2 não contém corpus automotivo real versionado; gates usam fixtures sintéticos.
- 2026-08-25 — owner informou que Podium 7 (`tihotm/podium7`) será o aplicativo responsável por alimentar o catálogo do Bom Pra Ti.
- 2026-08-25 — Podium 7 auditado: private MVP funcional, Python, Catalog Identity V2, evidence/provenance, conservative resolution, redirects, batch ingestion, consumer API e benchmarks.
- 2026-08-25 — localizado `BOM-PRATICHE-CONTRACT-V2.md`, contrato explícito já preparado para consumo pelo produto.
- 2026-08-25 — pesquisa arquitetural atual confirmou data ownership, independent deploy e shared-schema coupling como critérios materiais.
- 2026-08-25 — structural cardinality test provou que Podium identity pode exigir projeção 1:N em BPT2.
- 2026-08-25 — projection experiment executado com sete checks PASS, incluindo no-label-resolution e redirect merge.
- 2026-08-25 — opção A selecionada; ADR-0011 criada; próximo slice limitado ao publication mapping BPT2.

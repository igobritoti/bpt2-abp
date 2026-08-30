# Current work

Last verified: **2026-08-29**

Este arquivo é um snapshot curto do trabalho corrente. Não é histórico, changelog nem inventário de CI.

## Active outcome

Issue #116 / PR #134 executa o subproblema independente de autoridade municipal: mapear `City + StateCode` para identidade oficial IBGE sem implementar raio, coordenadas, geocoding ou PostGIS.

Issue #117 teve o benchmark PostgreSQL de claim/recovery integrado no `main` pelo PR #133. A issue permanece aberta porque deployment topology, cadence, retry/backoff e full-detection transaction boundary ainda não estão estabelecidos.

Issue #122 foi concluída e integrada pelo PR #131; o consumer quantitativo lossless/comparability boundary foi provado no fixture delimitado, enquanto Comparator continua bloqueado por cobertura Brasil/produção.

Issue #112 foi concluída e integrada pelo PR #129; o benchmark reproduzível de Discovery mede baseline exata, gaps de presentation/typo, facets e custo no corpus fixo sem escolher tecnologia avançada.

Issue #111 foi concluída pelo PR #127 e reconciliada como `completed`: `powertrain`, `transmission` e `body_style` são projetados do Podium Catalog JSON `2.0` para Vehicle/Vehicle Hub como strings opacas nullable, sem filtros públicos.

## Active plan

Fechar o benchmark IBGE de #116 com source-bound artifact, documentação, Harness/CI fresco, review e merge. A issue #116 permanece aberta após esse slice porque true physical radius continua sem autoridade para o ponto da Listing e sem privacy semantics.

## Evidência município #116

Green benchmark run: `33283814034`, artifact `9723774369`, artifact ZIP SHA-256 `37ef0a846369a376c27e56d5abfecc57f3110499744ec9a76398eeddcc1922e0`.

Fonte presa:

- IBGE DTB 2025, data-base `31/12/2025`;
- `DTB_2025.zip`: `1,635,600` bytes, SHA-256 `d077a0e48c36cf18bcc96268b4a436200c014c6b8522c1a62d894acaf39dad27`;
- `RELATORIO_DTB_BRASIL_2025_MUNICIPIOS.ods`: SHA-256 `a0606b9706c248138131511287e582a9293ba786096e0395192be36108d029fa`.

Medições:

- `5,571` linhas city-level codificadas;
- `5,569` municípios ordinários;
- `2` unidades city-level especiais preservadas explicitamente: Brasília/DF e Fernando de Noronha/PE;
- `5,571` códigos completos únicos;
- `0` colisões por `City + UF` exato;
- `232` nomes de cidade reutilizados entre UFs, portanto `City` isolado não é identidade suficiente;
- fixture BPT2: `6` exact, `4` unmatched fail-closed, `0` ambiguous;
- sem accent/case folding, fuzzy match, synonyms ou centroid fallback.

Auditoria: [`../audits/2026-08-29-ibge-municipality-identity-baseline.md`](../audits/2026-08-29-ibge-municipality-identity-baseline.md).

## Decisões atuais

- `MUNICIPALITY_IDENTITY_AUTHORITY = IBGE_DTB_2025_PINNED`;
- `EXACT_CITY_UF_PROJECTION = PROVED_BOUNDED`;
- `CITY_ALONE_AS_STABLE_IDENTITY = REJECTED`;
- `SPECIAL_CITY_LEVEL_UNITS = PRESERVE_EXPLICITLY`;
- `HEURISTIC_LOCATION_NORMALIZATION = NOT_AUTHORIZED`;
- `TRUE_LISTING_RADIUS = STILL_BLOCKED_ON_LOCATION_POINT_AUTHORITY_AND_PRIVACY`;
- `CENTROID_RADIUS = NOT_PROVED`;
- `POSTGIS = NOT_SELECTED`;
- `POSTGRES_TRANSACTIONAL_CLAIM_PRIMITIVE = PROVED_BOUNDED` (#117);
- `AUTOMATIC_RUNNER = NOT_YET_AUTHORIZED` (#117).

## Próximos gatilhos independentes

- #116: após integrar esta baseline, persistência de código IBGE exige contrato explícito de storage/update/rename; true radius continua separado e bloqueado em point authority/privacy;
- #117: obter fatos concretos de deployment/process lifetime antes de autorizar runner automático;
- #118: delivery externo somente após canal, consentimento, destinatário verificável e durable side-effect/recovery contract;
- #113: recomendações dependem de ground truth/exposure protocol válido;
- #114: inteligência de mercado depende de provider/licença/metodologia/provenance concretos;
- #115: trust/histórico depende de autorização/contrato/purpose/privacy específicos;
- Comparator continua bloqueado por cobertura Brasil/produção, apesar do consumer boundary de #122 estar provado.

## Source of runtime truth

- Estado de branch/PR/checks: Git e GitHub Actions do commit corrente.
- Produto: [`../PRODUCT.md`](../PRODUCT.md).
- Fatos derivados: [`../generated/repository-facts.md`](../generated/repository-facts.md).
- Decisões: [`../MDV.md`](../MDV.md) e [`../adr/`](../adr/).
- Cobertura funcional: [`../audits/2026-08-27-unified-functional-coverage-matrix.md`](../audits/2026-08-27-unified-functional-coverage-matrix.md).
- Baseline Discovery: [`../audits/2026-08-29-advanced-discovery-baseline.md`](../audits/2026-08-29-advanced-discovery-baseline.md).
- Benchmark quantitative consumer: [`../audits/2026-08-29-podium-quantitative-consumer-benchmark.md`](../audits/2026-08-29-podium-quantitative-consumer-benchmark.md).
- Saved Search claim baseline: [`../audits/2026-08-29-saved-search-postgres-claim-baseline.md`](../audits/2026-08-29-saved-search-postgres-claim-baseline.md).
- Município IBGE: [`../audits/2026-08-29-ibge-municipality-identity-baseline.md`](../audits/2026-08-29-ibge-municipality-identity-baseline.md).

## Open blockers

- True radius: falta autoridade para ponto físico da Listing + privacy/minimization; município/centroide não é veículo (#116).
- Saved Search runner: deployment topology/cadence/retry/full-detection transaction boundary ainda não fixados (#117).
- Saved Search external delivery: canal/consentimento/destinatário/cadence/provider e durable delivery/recovery continuam pendentes (#118).
- Comparator/ficha técnica ampla: cobertura Brasil/produção insuficiente; PBEV/coverage continuam upstream-gated.
- Discovery avançado: baseline mede gaps reais, mas nenhuma implementação candidata foi comparada sob o mesmo corpus.
- Recomendações, market intelligence e trust permanecem bloqueados pelos respectivos contracts/evidence gates.

## Update rule

Atualize este snapshot somente quando mudar outcome, plano, acceptance target ou blocker real.

# Discovery typo scoring comparison — 2026-08-30

Issue: #150

Status: benchmark evidence only. This document does **not** authorize fuzzy search in production, a score cutoff, a ranking policy, an index, a fallback order, synonyms, aliases or an external search engine.

## Frozen evidence boundary

- BPT2 benchmark schema: `bpt2.discovery-typo-scoring.v1`
- Discovery fixture: `benchmarks/discovery_br_v1.json`
- Fixture schema: `bpt2.discovery-benchmark.v1`
- Fixture dataset version: `br-golden-derived-1.0`
- Fixture SHA-256: `54028f4c7925ad2f2d9a8b1637d00ab7e013f43b4e10fea0ff88a9b87474bd20`
- Candidate universe in this bounded fixture: 8 canonical Vehicles
- PostgreSQL image: `postgres:17-alpine` (run resolved PostgreSQL 17.11)
- Extensions observed: `fuzzystrmatch:1.2`, `pg_trgm:1.6`
- Final-base run before this audit commit: `33331449281`
- Artifact: `9737773937`, `discovery-typo-scoring-benchmark`
- Artifact ZIP SHA-256: `f904d01408099f48d103c14170eee6cebec2e3b636cc1bd1ead2c6468870a2c4`

The same workflow first executes the unchanged Advanced Discovery baseline against the real Catalog/Marketplace code and freshly migrated PostgreSQL database, then runs the scoring-only comparison. The scoring fixture does not change public search behavior.

## Predeclared scoring/evaluation math

The exact evaluation math was frozen in issue #150 before candidate scores were observed:

1. normalize only with trim + lowercase + ASCII hyphen-to-space, matching the already-approved presentation rule from #147;
2. score exactly the current Catalog-visible identity fields: Brand, Model, optional Generation and Version;
3. no concatenated synthetic identity string;
4. for each Vehicle, `similarity`, `word_similarity` and `strict_word_similarity` use the maximum field score;
5. Levenshtein uses the minimum unit-cost field distance;
6. rank the complete frozen Vehicle candidate set for each method; ties use VehicleId;
7. MRR uses the first intended qrel target;
8. Recall uses `Recall@K`, where `K` equals the frozen qrel target count for that query only as an evaluation measure;
9. count non-target candidates before the first intended target;
10. similarity separation margin = best target score − best non-target score;
11. Levenshtein separation margin = best non-target distance − best target distance, so a positive margin always means target separation;
12. no PostgreSQL extension default threshold becomes a BPT2 product threshold.

## Current production baseline on the same final base

The pre-scoring run on current production semantics reported:

| Family | Catalog MRR | Catalog Recall | Public MRR | Public Recall | Catalog FP | Public FP |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| exact | 1.0000 | 1.0000 | 1.0000 | 1.0000 | 0 | 0 |
| confusable | 1.0000 | 1.0000 | 1.0000 | 1.0000 | 0 | 0 |
| autocomplete/prefix | 1.0000 | 1.0000 | 1.0000 | 1.0000 | 0 | 0 |
| presentation | 1.0000 | 1.0000 | 1.0000 | 1.0000 | 0 | 0 |
| typo | 0.0000 | 0.0000 | 0.0000 | 0.0000 | 0 | 0 |

Facet/filter oracle: **10/10**.

This confirms that #147 remains effective while typo tolerance is still absent from production behavior.

## Scoring-only aggregate result

All four compared methods ranked the intended target set first for all three frozen typo queries in this eight-Vehicle corpus:

| Method | Mean MRR | Mean Recall@target-count | Non-targets before first target | Minimum target separation margin |
| --- | ---: | ---: | ---: | ---: |
| Levenshtein | 1.0000 | 1.0000 | 0 | 5.0000 |
| `similarity` | 1.0000 | 1.0000 | 0 | 0.3571 |
| `strict_word_similarity` | 1.0000 | 1.0000 | 0 | 0.2857 |
| `word_similarity` | 1.0000 | 1.0000 | 0 | 0.2857 |

The numeric margins are not comparable across distance and similarity scales and are not product thresholds.

## Per-query characterization

### `Corola Cross`

Frozen qrels: `toyota-hybrid`, `toyota-xrx`.

- all four methods ranked the two targets at positions 1 and 2;
- `similarity`: target score `0.785714`, best non-target `0.428571`, margin `0.357143`;
- `word_similarity`: target `0.785714`, best non-target `0.500000`, margin `0.285714`;
- `strict_word_similarity`: target `0.785714`, best non-target `0.500000`, margin `0.285714`;
- Levenshtein: target distance `1`, best non-target distance `6`, margin `5`;
- score-query latency over 7 bounded executions: min `1.3825 ms`, p50 `1.4455 ms`, p95 `9.3952 ms`, max `12.7492 ms`.

### `Higline 250 TSI`

Frozen qrel: `tcross-highline`.

- all four methods ranked the target first;
- `similarity`: target `0.736842`, best non-target `0.285714`, margin `0.451128`;
- `word_similarity`: target `0.736842`, best non-target `0.421053`, margin `0.315789`;
- `strict_word_similarity`: target `0.736842`, best non-target `0.285714`, margin `0.451128`;
- Levenshtein: target distance `1`, best non-target distance `8`, margin `7`;
- latency: min `1.4274 ms`, p50 `1.4462 ms`, p95 `13.8145 ms`, max `19.0811 ms`.

### `Premire Turbo 116cv`

Frozen qrel: `onix-premier`.

- all four methods ranked the target first;
- `similarity`: target `0.739130`, best non-target `0.038462`, margin `0.700669`;
- `word_similarity`: target `0.739130`, best non-target `0.050000`, margin `0.689130`;
- `strict_word_similarity`: target `0.739130`, best non-target `0.047619`, margin `0.691511`;
- Levenshtein: target distance `2`, best non-target distance `16`, margin `14`;
- latency: min `1.3951 ms`, p50 `1.4318 ms`, p95 `1.4521 ms`, max `1.4551 ms`.

Latency here characterizes an eight-Vehicle CI fixture only. It is not production-scale evidence and no SLO is inferred.

## Representative PostgreSQL plan

The representative `word_similarity` ordering for `corola cross` returned all 8 Vehicles and reported approximately:

- Planning Time: `0.365 ms`;
- Execution Time: `0.238 ms`;
- sequential scans of the tiny Vehicle/Version/Brand/Model tables plus the Generation PK lookup;
- quicksort memory: `25 kB`.

A sequential scan over eight Vehicles cannot select or reject a production index strategy.

## Decision boundary

Evidence supports only these statements:

1. the three frozen typo probes remain reproducible gaps under current production substring semantics;
2. all four compared scoring functions can rank the intended targets first in the current eight-Vehicle corpus;
3. this bounded corpus does not distinguish a winner among the four methods;
4. PostgreSQL extension defaults are library configuration, not BPT2 product acceptance criteria;
5. choosing a production cutoff after observing these scores would be post-hoc thresholding and is rejected;
6. production-scale planner/index conclusions cannot be made from this corpus;
7. no fuzzy method is promoted to production by #150.

A later experiment may enlarge robustness evidence only with independently defined relevance semantics. Podium entity-resolution `MATCH`/`NO_MATCH` labels must not be reused automatically as public-search relevance. A defensible next candidate is a metamorphic benchmark derived from the existing exact-search result sets: freeze exact positive sets first, apply deterministic one-edit query perturbations, and measure preservation of those sets without inventing new relevance labels after candidate scores are known.

## Disposition

- `TYPO_SCORING_COMPARISON = PROVED_BOUNDED`
- `CURRENT_PRODUCTION_TYPO_TOLERANCE = NONE`
- `ALL_FOUR_METHODS_TOP_RANK_FROZEN_TARGETS = YES`
- `METHOD_WINNER = NONE`
- `PRODUCT_SCORE_THRESHOLD = UNSET`
- `PG_TRGM_DEFAULT_THRESHOLD_AS_PRODUCT_POLICY = REJECTED`
- `PRODUCTION_FUZZY_SEARCH = NOT_AUTHORIZED`
- `PRODUCTION_INDEX_SELECTION = NOT_AUTHORIZED`

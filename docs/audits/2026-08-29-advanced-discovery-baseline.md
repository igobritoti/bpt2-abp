# Advanced Discovery Baseline — 2026-08-29

Issue: #112

This document records the first executed BPT2-owned advanced-discovery baseline. It is evidence, not a product acceptance threshold and not an authorization to introduce fuzzy search, ranking, synonyms, taxonomy, `pg_trgm`, PostgreSQL FTS, or a separate search engine.

## Reproducibility boundary

- BPT2 benchmark schema: `bpt2.discovery-benchmark.v1`
- Dataset version: `br-golden-derived-1.0`
- Fixture file: `benchmarks/discovery_br_v1.json`
- Fixture SHA-256: `54028f4c7925ad2f2d9a8b1637d00ab7e013f43b4e10fea0ff88a9b87474bd20`
- Upstream evidence repository: `gestbrito/podium7`
- Upstream pinned commit: `a6af193b47110ef0df5353da4db3f53d0bd03b8d`
- Upstream file: `benchmarks/catalog_identity_golden_br_v1.json`
- Upstream dataset: `podium7.catalog-identity-golden.v1`, `br-1.0`
- PostgreSQL image: `postgres:17-alpine` (run resolved PostgreSQL 17.11)
- GitHub Actions run: `33281478439`
- Artifact: `9723127679`, `advanced-discovery-baseline`
- Artifact ZIP digest: `sha256:390ebf97bc1e58a84168ffb977fb87bc70cb0dedb0d6f0c544241dadbc2b4c36`
- Result schema: `bpt2.discovery-baseline-result.v1`

The workflow runs the real `VehicleCatalogReader` and `PublicListingQuery` against a freshly migrated PostgreSQL database. Media and Seller projections are irrelevant to retrieval metrics and are stubbed only at those boundaries. Technical-field-only distinctions from Podium are not used as discovery relevance labels when the current BPT2 public identity cannot express them.

## Corpus

The bounded fixture contains 8 canonical Vehicles and 8 public Listings plus 1 Draft visibility control. It includes Corolla Cross, Onix, T-Cross, Strada and Corsa cases derived from the pinned Podium Brazil identity evidence.

This corpus is intentionally small. It is suitable for semantic/regression characterization, not production-scale latency or planner conclusions.

## Executed retrieval baseline

| Family | Queries | Catalog MRR | Catalog Recall | Public MRR | Public Recall | Catalog FP | Public FP |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| exact | 6 | 1.0000 | 1.0000 | 1.0000 | 1.0000 | 0 | 0 |
| confusable | 2 | 1.0000 | 1.0000 | 1.0000 | 1.0000 | 0 | 0 |
| autocomplete/prefix | 4 | 1.0000 | 1.0000 | 1.0000 | 1.0000 | 0 | 0 |
| presentation | 1 | 0.0000 | 0.0000 | 0.0000 | 0.0000 | 0 | 0 |
| typo | 3 | 0.0000 | 0.0000 | 0.0000 | 0.0000 | 0 | 0 |

Important interpretation:

- Current substring semantics already satisfy the bounded prefix probes; this does **not** mean an autocomplete product/UX has been implemented.
- `T-Cross` succeeds while `T Cross` returns no result. Presentation normalization is therefore a measured gap.
- deterministic deletion/transposition typo probes return no result. Typo tolerance is therefore a measured gap.
- no false positives occurred in this bounded corpus.
- the benchmark intentionally does not invent a pass/fail threshold for these quality metrics.

## Facet/filter oracle

All 10 independent fixed-count cases matched exactly: `10/10`.

Covered combinations include state, city, color case normalization, brand, model, model-year interval, price interval, mileage ceiling, state+color composition, and query filtering. These are regression oracles for current semantics; they do not establish a faceted-navigation UX or arbitrary new facet taxonomy.

## Latency characterization

Across the query cases, the median of per-query p50 values was approximately:

- Catalog retrieval: **2.55 ms**
- Public Listing retrieval: **6.45 ms**

The slowest observed per-query p50 values in this run were approximately 2.65 ms for Catalog and 9.26 ms for Public Listing retrieval. One first-query warm-up/outlier produced materially larger p95/max values; no product latency SLO is inferred from this single CI run.

Because the corpus has only 8 Vehicles/8 public Listings, these values are descriptive smoke/benchmark evidence only. They are not production-scale performance evidence.

## Representative PostgreSQL plan

The representative `EXPLAIN (ANALYZE, BUFFERS)` for a `%corolla%` text lookup reported:

- `Execution Time: 0.234 ms`
- `Planning Time: 0.791 ms`
- sequential scans of the tiny Vehicle/Version/Brand/Model tables, plus the existing Generation PK index lookup
- 8 Vehicle rows scanned, 6 removed by the text filter

A sequential scan on this eight-row fixture is expected and cannot be used to select or reject an index/search technology. Candidate technologies such as `pg_trgm` or FTS require a larger fixed corpus and comparative execution under the same qrels before adoption.

## Decision boundary

Evidence now supports the following statements:

1. The current exact/case-insensitive substring baseline is reproducibly measured.
2. Presentation variation (`T Cross` vs `T-Cross`) and deterministic typos are reproducible quality gaps.
3. Existing filter composition matches the fixed oracle in this corpus.
4. Prefix probes happen to work through substring semantics; no separate autocomplete implementation is justified by this fact alone.
5. No advanced-search technology has yet demonstrated superiority under a controlled A/B benchmark.

Therefore #112 establishes the benchmark substrate and current baseline. Any subsequent search-quality slice must change one variable at a time, rerun the unchanged corpus/qrels first, compare quality and planner/latency evidence, and preserve false-positive visibility. No product threshold should be retrofitted after seeing candidate results.

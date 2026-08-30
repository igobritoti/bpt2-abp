# Discovery metamorphic typo robustness — 2026-08-30

Issue: #154

Status: benchmark evidence only. This document does **not** authorize fuzzy search in production, a score cutoff, a ranking/fallback policy, an index, PostgreSQL extensions in production, aliases, synonyms or Saved Search changes.

## Frozen evidence boundary

- benchmark schema: `bpt2.discovery-metamorphic-typo.v1`
- source fixture: `benchmarks/discovery_br_v1.json`
- fixture SHA-256: `54028f4c7925ad2f2d9a8b1637d00ab7e013f43b4e10fea0ff88a9b87474bd20`
- final-base PR head before this audit commit: `70d932e186e908056d4f34c83e46b8c8220101d3`
- final-base workflow run: `33333069839`
- workflow checkout/merge SHA recorded by artifact: `7a7105f222aa061e517d511c694499c118025115`
- PostgreSQL image: `postgres:17-alpine` (PostgreSQL 17)
- benchmark-only extensions: `fuzzystrmatch:1.2`, `pg_trgm:1.6`
- final artifact ID: `9738224970`
- artifact ZIP SHA-256: `24c2ddb747dc0c8cad4efb35865846de03cb4d859c041e9e5a4db7bf7df9428f`

The methodology, transformations, exclusions and decision rule were frozen in #154 before any scorer result was observed. The first experimental attempt failed while decoding the baseline JSON BOM, before scorer execution. The only correction was an encoding-normalization step; no query, target, transformation or scorer formula changed before the first successful scoring run.

## Metamorphic oracle

Only frozen source queries whose executed unperturbed production baseline has Catalog and Public MRR=1, Recall=1 and FP=0 are eligible. A deterministic one-character mutation inherits that source query's already-frozen target set, subject to the predeclared collision checks.

Three transformations are generated over the longest alphanumeric token (left-most tie, minimum length 4):

1. `DELETE_INTERIOR` — delete index `floor(length / 2)`;
2. `TRANSPOSE_INTERIOR` — swap indexes `floor(length / 2)-1` and `floor(length / 2)`; skip equal characters;
3. `DUPLICATE_INTERIOR` — duplicate index `floor(length / 2)`.

No keyboard-neighbor map, phonetics, synonym, diacritic expansion or post-hoc replacement is used.

## Unchanged production baseline

The same final-base workflow first reproduced the #112 production baseline:

| Family | Catalog MRR | Catalog Recall | Public MRR | Public Recall | Catalog FP | Public FP |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| exact | 1.0000 | 1.0000 | 1.0000 | 1.0000 | 0 | 0 |
| confusable | 1.0000 | 1.0000 | 1.0000 | 1.0000 | 0 | 0 |
| autocomplete/prefix | 1.0000 | 1.0000 | 1.0000 | 1.0000 | 0 | 0 |
| presentation | 1.0000 | 1.0000 | 1.0000 | 1.0000 | 0 | 0 |
| typo | 0.0000 | 0.0000 | 0.0000 | 0.0000 | 0 | 0 |

Facet/filter oracle: **10/10**.

Therefore #154 changes no production typo behavior. It only measures candidate scorers outside the public/Catalog API path.

## Generated corpus

- raw mutations: **39**;
- included scoring cases: **33**;
- recorded exclusions: **9**.

The nine exclusions are fully explained by the frozen rules:

- 3 source exclusions: the original typo probes `Corola Cross`, `Higline 250 TSI` and `Premire Turbo 116cv` are not green in the unperturbed production baseline, so they cannot seed metamorphic descendants;
- 6 generated exclusions: the three mutations from `t-cross` and the corresponding three from `T Cross` collide after the already-delivered hyphen/space presentation normalization, so both sides of each duplicate generated term are excluded rather than selecting one post hoc.

No excluded case was replaced.

## Aggregate result

All four methods score exactly the same 33 generated cases using the #150 field semantics.

| Method | Mean MRR | Mean Recall@target-count | Total non-targets ahead | Minimum within-method margin |
| --- | ---: | ---: | ---: | ---: |
| Levenshtein | 0.7281 | 0.6212 | 48 | -4.0000 |
| `similarity` | 0.9066 | 0.8485 | 9 | -0.0852 |
| `strict_word_similarity` | 0.9177 | 0.8788 | 10 | -0.1071 |
| `word_similarity` | **0.9404** | **0.9091** | **7** | 0.0000 |

Raw margin magnitudes are not compared across Levenshtein and trigram scales. Cross-method dominance uses only common per-case MRR, Recall@target-count and non-targets-ahead metrics, as clarified in #154 before execution.

Under that predeclared rule, the only dominance relationship observed is:

`word_similarity` **dominates Levenshtein** on this corpus.

There is no dominance claim among `word_similarity`, `similarity` and `strict_word_similarity`.

## By transformation

Each transformation has 11 valid cases.

### `DELETE_INTERIOR`

| Method | MRR | Recall | Non-targets ahead |
| --- | ---: | ---: | ---: |
| Levenshtein | 0.7281 | 0.6364 | 16 |
| `similarity` | 0.9318 | 0.9091 | 3 |
| `strict_word_similarity` | 0.8667 | 0.8182 | 6 |
| `word_similarity` | **0.9394** | **0.9091** | **2** |

### `DUPLICATE_INTERIOR`

| Method | MRR | Recall | Non-targets ahead |
| --- | ---: | ---: | ---: |
| Levenshtein | 0.7281 | 0.6364 | 16 |
| `similarity` | 1.0000 | 1.0000 | 0 |
| `strict_word_similarity` | 1.0000 | 1.0000 | 0 |
| `word_similarity` | 1.0000 | 1.0000 | 0 |

All three trigram methods are perfect on the 11 duplicate-character mutations. This does not make them equivalent on delete/transposition mutations.

### `TRANSPOSE_INTERIOR`

| Method | MRR | Recall | Non-targets ahead |
| --- | ---: | ---: | ---: |
| Levenshtein | 0.7281 | 0.5909 | 16 |
| `similarity` | 0.7879 | 0.6364 | 6 |
| `strict_word_similarity` | **0.8864** | **0.8182** | **4** |
| `word_similarity` | 0.8818 | 0.8182 | 5 |

This transformation is an important counterexample to choosing a winner from aggregate mean alone: `strict_word_similarity` is slightly stronger than `word_similarity` on MRR/non-targets-ahead here, while the overall corpus favors `word_similarity`.

## Remaining non-perfect `word_similarity` cases

`word_similarity` is not production-ready evidence. It remains non-perfect on three generated cases:

- `Cof` from `prefix-comf` + DELETE: MRR 0.3333, Recall 0, 2 non-targets ahead;
- `Cmof` from `prefix-comf` + TRANSPOSE: MRR 0.2000, Recall 0, 4 non-targets ahead;
- `Hgih` from `prefix-high` + TRANSPOSE: MRR 0.5000, Recall 0, 1 non-target ahead.

The benchmark therefore rejects the statement that typo scoring is solved by choosing `word_similarity`.

## Descriptive latency

Latency measures the full eight-Vehicle scoring query in CI and is not a production SLO or cardinality proof. Across the 11 queries of each transformation, median of per-query p50 latency was approximately:

- DELETE: `1.76 ms`;
- DUPLICATE: `1.78 ms`;
- TRANSPOSE: `1.75 ms`.

The tiny corpus cannot select a production index or establish scale behavior.

## Decision boundary

Evidence supports these statements:

1. deterministic metamorphic expansion increases the typo robustness evaluation from three hand-curated typo probes to 33 independently generated valid cases without post-score qrel editing;
2. all four methods are materially better than current production substring behavior on some typo-like perturbations, but none is perfect across the generated corpus;
3. `word_similarity` empirically dominates Levenshtein under the predeclared common per-case retrieval metrics on this bounded corpus;
4. the evidence does **not** establish dominance of `word_similarity` over the other two trigram scorers;
5. aggregate averages alone are insufficient because transformation-specific behavior differs;
6. production cutoff/eligibility, fallback order, extension/index adoption and scale behavior remain unmeasured boundaries;
7. no fuzzy method is enabled in production by #154.

## Next defensible boundary

A later experiment may reduce the candidate set and evaluate production eligibility only if it freezes, before scores are observed:

- which trigram candidate(s) remain under test;
- a substantially larger negative/candidate cardinality independent of the current eight-Vehicle fixture;
- explicit eligibility/cutoff evaluation metrics and false-positive costs;
- planner/index evidence under that cardinality;
- unchanged exact/presentation regression requirements.

The current result is not sufficient to choose a product threshold after observing the score distributions.

## Disposition

- `METAMORPHIC_TYPO_ROBUSTNESS = PROVED_BOUNDED`
- `RAW_CASES = 39`
- `VALID_CASES = 33`
- `RECORDED_EXCLUSIONS = 9`
- `WORD_SIMILARITY_DOMINATES_LEVENSHTEIN = YES_ON_THIS_CORPUS`
- `TRIGRAM_METHOD_WINNER = NONE`
- `CURRENT_PRODUCTION_TYPO_TOLERANCE = NONE`
- `PRODUCT_SCORE_THRESHOLD = UNSET`
- `PRODUCTION_FUZZY_SEARCH = NOT_AUTHORIZED`
- `PRODUCTION_INDEX_SELECTION = NOT_AUTHORIZED`

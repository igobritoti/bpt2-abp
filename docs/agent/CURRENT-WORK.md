# Current work

Last verified: **2026-08-30**

Este arquivo é um snapshot curto do trabalho corrente. Não é histórico, changelog nem inventário de CI.

## Active outcome

Issue #147 foi concluída pelo PR #149 (squash `004cbd44dbd864af28c94c173ed1d106e1d2bf8c`). Discovery de identidade canônica agora trata hífen ASCII e espaço como equivalentes de apresentação, sem adicionar fuzzy/edit distance, aliases ou nova engine.

Issue #150 é o próximo experimento executável: benchmark-only de typo scoring no corpus/qrels congelado #112, comparando `pg_trgm` (`similarity`, `word_similarity`, `strict_word_similarity`) e `fuzzystrmatch` Levenshtein. Não existe autorização para fuzzy em produção, cutoff ou ranking policy neste estágio.

Issues #113–#116 continuam explicitamente puladas para execução autônoma enquanto faltarem as autoridades externas/humanas documentadas.

## Evidence — #147 final

Head final PR #149: `401148b3dbde5ef45a3affd61c755a2fe479b280` sobre base `bdeffbd9b41d0434c484c414eedd842726bc9f08`.

- **14/14 workflows verdes**;
- Advanced Discovery Benchmark run `33330882197`;
- fixture SHA-256 `54028f4c7925ad2f2d9a8b1637d00ab7e013f43b4e10fea0ff88a9b87474bd20` inalterado;
- exact: Catalog/Public MRR=1.0000, Recall=1.0000, FP=0;
- confusable: 1.0000 / 1.0000, FP=0;
- autocomplete/prefix: 1.0000 / 1.0000, FP=0;
- presentation: **1.0000 / 1.0000, FP=0** (baseline anterior 0/0);
- typo: permanece 0.0000 / 0.0000, FP=0;
- facet/filter oracle: 10/10;
- Fresh Migration: verde;
- build do benchmark: 0 warnings / 0 errors;
- artifact final ID `9737623354`, ZIP SHA-256 `5227799a4590a238d11a5e8bdbdf85c23046e44e8e13283b9cc190a934bdf3de`;
- nenhuma review thread pendente.

## Active plan — #150

1. Preservar o fixture/qrels #112 sem adicionar exemplos depois de observar scores.
2. Reutilizar o Advanced Discovery fixture para semear o banco real do benchmark.
3. Medir por Vehicle os quatro métodos pré-declarados sobre Brand/Model/Generation/Version normalizados apenas por trim + lowercase + hífen→espaço.
4. Registrar ranking completo, MRR, Recall@target-count, non-targets ahead, target/non-target margin, latency e EXPLAIN.
5. Não usar defaults de `pg_trgm` como thresholds de produto.
6. O primeiro draft de harness pode validar apenas a mecânica; qualquer merge precisa ser reproduzido sobre o `main` pós-#147.
7. Depois do benchmark, só promover novo experimento se houver ganho nos typos congelados sem mudar qrels/aliases; cutoff/eligibility/index/produção permanecem um boundary posterior.

## Remaining blockers / skip rules

- #113 Recommendations: `SKIP` até qrel humano versionado ou exposure-aware behavioral data.
- #114 Market intelligence: `SKIP` até quantidade de produto + provider/dataset autorizado/licenciado.
- #115 Trust/history/inspection: `SKIP` até provider + Listing-instance identity + purpose/privacy/retention/assertion contract.
- #116 True radius: `SKIP` até autoridade do ponto físico da Listing + provenance/precision/lifecycle/privacy.
- Resend produção: deployment externo; não reabre #118.
- Comparator/ficha técnica ampla: consumer boundary #122 provado, mas cobertura Brasil/produção e produto concreto ainda são gatilhos.

## Decisões consolidadas recentes

- #117: Saved Search detection runner PostgreSQL = implementado e verde.
- #118: `EMAIL_EACH_NEW_MATCH` por Saved Search = implementado e verde; Resend real permanece probe configurável, com `SKIP` correto sem credenciais.
- #122: quantitative consumer/comparability boundary = provado bounded; não autoriza promoção automática de campos/Comparator.
- #139/#114: external provider identifier projection = entregue; market-price source semantics/license continuam externos.
- #135/#116: município IBGE = provado; município/centroide não é ponto físico do veículo.
- #147: apresentação hífen/espaço = entregue após comparação controlada; typo permanece gap medido separado.

## Source of runtime truth

- Git/PR/checks do commit corrente;
- produto: [`../PRODUCT.md`](../PRODUCT.md);
- fatos derivados: [`../generated/repository-facts.md`](../generated/repository-facts.md);
- decisões: [`../MDV.md`](../MDV.md) e [`../adr/`](../adr/);
- cobertura funcional: [`../audits/2026-08-27-unified-functional-coverage-matrix.md`](../audits/2026-08-27-unified-functional-coverage-matrix.md);
- Advanced Discovery baseline: [`../audits/2026-08-29-advanced-discovery-baseline.md`](../audits/2026-08-29-advanced-discovery-baseline.md);
- quantitative consumer: [`../audits/2026-08-29-podium-quantitative-consumer-benchmark.md`](../audits/2026-08-29-podium-quantitative-consumer-benchmark.md);
- Saved Search claim: [`../audits/2026-08-29-saved-search-postgres-claim-baseline.md`](../audits/2026-08-29-saved-search-postgres-claim-baseline.md);
- município IBGE: [`../audits/2026-08-29-ibge-municipality-identity-baseline.md`](../audits/2026-08-29-ibge-municipality-identity-baseline.md);
- Saved Search email: [`../audits/2026-08-29-saved-search-email-delivery-contract-baseline.md`](../audits/2026-08-29-saved-search-email-delivery-contract-baseline.md).

## Update rule

Atualize este snapshot somente quando mudar outcome, plano, acceptance target ou blocker real.

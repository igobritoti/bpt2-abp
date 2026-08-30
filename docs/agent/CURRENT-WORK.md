# Current work

Last verified: **2026-08-30**

Este arquivo é um snapshot curto do trabalho corrente. Não é histórico, changelog nem inventário de CI.

## Active outcome

Issue #150 foi concluída pelo PR #153 (squash `3d76e0075795d558e554ecd07fb208e9634d432f`). O benchmark inicial de três typos não separou os quatro scorers e não autorizou fuzzy em produção.

Issue #154 chegou à reprodução final-base no PR #156. O benchmark metamórfico amplia a avaliação para perturbações determinísticas pré-declaradas sem editar qrels depois dos scores. Ele separa `word_similarity` de Levenshtein neste corpus, mas não identifica vencedor entre os três métodos trigram nem autoriza cutoff/index/fuzzy em produção.

Issues #113–#116 continuam explicitamente puladas para execução autônoma enquanto faltarem as autoridades externas/humanas documentadas.

## Evidence — #154 final-base reproduction

Run `33333069839` no head funcional `70d932e186e908056d4f34c83e46b8c8220101d3`, base `3d76e0075795d558e554ecd07fb208e9634d432f`:

- fixture SHA-256 `54028f4c7925ad2f2d9a8b1637d00ab7e013f43b4e10fea0ff88a9b87474bd20` inalterado;
- fresh migration: PASS;
- baseline exact/confusable/autocomplete/presentation: Catalog/Public MRR=1.0000, Recall=1.0000, FP=0;
- baseline typo de produção: Catalog/Public MRR=0.0000, Recall=0.0000, FP=0;
- facet/filter oracle: 10/10;
- mutações brutas: 39;
- casos válidos: 33;
- exclusões registradas: 9, sem reposição manual;
- Levenshtein: MRR=0.7281, Recall@target-count=0.6212, non-targets ahead=48;
- `similarity`: MRR=0.9066, Recall=0.8485, non-targets ahead=9;
- `strict_word_similarity`: MRR=0.9177, Recall=0.8788, non-targets ahead=10;
- `word_similarity`: MRR=0.9404, Recall=0.9091, non-targets ahead=7;
- relação de dominância pré-declarada observada: `word_similarity` domina Levenshtein;
- nenhum domínio estabelecido entre os três scorers trigram;
- artifact ID `9738224970`, ZIP SHA-256 `24c2ddb747dc0c8cad4efb35865846de03cb4d859c041e9e5a4db7bf7df9428f`.

Por transformação, os três trigram scorers foram 1.0/1.0 nos 11 casos `DUPLICATE_INTERIOR`; delete/transposição os separam. `strict_word_similarity` supera levemente `word_similarity` na transposição agregada, reforçando que média global isolada não escolhe política de produto.

`word_similarity` ainda falha em três casos gerados (`Cof`, `Cmof`, `Hgih`), portanto o resultado não prova typo tolerance resolvida.

Audit: [`../audits/2026-08-30-discovery-metamorphic-typo-robustness.md`](../audits/2026-08-30-discovery-metamorphic-typo-robustness.md).

## Merge condition — #154

O PR #156 só fecha #154 após CI fresca do head que contém benchmark, workflow, audit e este snapshot, com checks aplicáveis verdes e sem review threads pendentes. O run acima é a reprodução final-base funcional; não substitui a prova fresca do head documental final.

## Next valid experiment after #154

A próxima fronteira autônoma defensável é **eligibility/scale para os scorers trigram**, ainda benchmark-only:

1. reduzir candidatos técnicos apenas por evidência já observada, sem promover scorer a produto;
2. congelar uma cardinalidade negativa substancialmente maior que os 8 Vehicles atuais, derivada independentemente dos scores atuais;
3. pré-declarar métricas de false-positive/eligibility antes de observar thresholds;
4. medir planner/index behavior no PostgreSQL nessa cardinalidade;
5. preservar o baseline exato/apresentação e os 33 metamorphic cases como regressão;
6. não escolher cutoff depois de observar a distribuição sem regra prévia.

Se não houver dataset/cardinalidade independente defensável, esse próximo experimento deve ser marcado `SKIP` em vez de sintetizar negativos ad hoc para favorecer uma tecnologia.

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
- #150: quatro scorers caracterizados nos três qrels typo; nenhum vencedor/cutoff selecionado.
- #154: robustez metamórfica separa `word_similarity` de Levenshtein, mas `TRIGRAM_METHOD_WINNER = NONE`.

## Source of runtime truth

- Git/PR/checks do commit corrente;
- produto: [`../PRODUCT.md`](../PRODUCT.md);
- fatos derivados: [`../generated/repository-facts.md`](../generated/repository-facts.md);
- decisões: [`../MDV.md`](../MDV.md) e [`../adr/`](../adr/);
- cobertura funcional: [`../audits/2026-08-27-unified-functional-coverage-matrix.md`](../audits/2026-08-27-unified-functional-coverage-matrix.md);
- Advanced Discovery baseline: [`../audits/2026-08-29-advanced-discovery-baseline.md`](../audits/2026-08-29-advanced-discovery-baseline.md);
- typo scoring: [`../audits/2026-08-30-discovery-typo-scoring-comparison.md`](../audits/2026-08-30-discovery-typo-scoring-comparison.md);
- metamorphic typo robustness: [`../audits/2026-08-30-discovery-metamorphic-typo-robustness.md`](../audits/2026-08-30-discovery-metamorphic-typo-robustness.md);
- quantitative consumer: [`../audits/2026-08-29-podium-quantitative-consumer-benchmark.md`](../audits/2026-08-29-podium-quantitative-consumer-benchmark.md);
- Saved Search claim: [`../audits/2026-08-29-saved-search-postgres-claim-baseline.md`](../audits/2026-08-29-saved-search-postgres-claim-baseline.md);
- município IBGE: [`../audits/2026-08-29-ibge-municipality-identity-baseline.md`](../audits/2026-08-29-ibge-municipality-identity-baseline.md);
- Saved Search email: [`../audits/2026-08-29-saved-search-email-delivery-contract-baseline.md`](../audits/2026-08-29-saved-search-email-delivery-contract-baseline.md).

## Update rule

Atualize este snapshot somente quando mudar outcome, plano, acceptance target ou blocker real.

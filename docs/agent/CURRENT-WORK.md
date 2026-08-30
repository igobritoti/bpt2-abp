# Current work

Last verified: **2026-08-30**

Este arquivo é um snapshot curto do trabalho corrente. Não é histórico, changelog nem inventário de CI.

## Active outcome

Issue #147 foi concluída pelo PR #149 (squash `004cbd44dbd864af28c94c173ed1d106e1d2bf8c`). Discovery de identidade canônica trata hífen ASCII e espaço como equivalentes de apresentação, sem fuzzy/edit distance, aliases ou nova engine.

Issue #150 chegou à reprodução final-base no PR #153. O benchmark é somente observacional: compara `pg_trgm` (`similarity`, `word_similarity`, `strict_word_similarity`) e `fuzzystrmatch` Levenshtein sobre os três qrels de typo congelados em #112. Nenhum método, cutoff, índice, fallback ou comportamento fuzzy foi autorizado para produção.

Issues #113–#116 continuam explicitamente puladas para execução autônoma enquanto faltarem as autoridades externas/humanas documentadas.

## Evidence — #150 final-base reproduction

Run `33331449281` no head `0f7fbf1906f08e6939906f3b83969375677c9ae4`, base `c765485a79a88c76aa61ae82bf096e4b023c4953`:

- fixture SHA-256 `54028f4c7925ad2f2d9a8b1637d00ab7e013f43b4e10fea0ff88a9b87474bd20` inalterado;
- fresh migration: PASS;
- exact: Catalog/Public MRR=1.0000, Recall=1.0000, FP=0;
- confusable: Catalog/Public MRR=1.0000, Recall=1.0000, FP=0;
- autocomplete/prefix: Catalog/Public MRR=1.0000, Recall=1.0000, FP=0;
- presentation: Catalog/Public MRR=1.0000, Recall=1.0000, FP=0;
- typo no comportamento de produção: Catalog/Public MRR=0.0000, Recall=0.0000, FP=0;
- facet/filter oracle: 10/10;
- extensões somente no ambiente de benchmark: `pg_trgm:1.6`, `fuzzystrmatch:1.2`;
- `levenshtein`: MRR=1.0000, Recall@target-count=1.0000, non-target ahead=0, margem mínima=5.0000;
- `similarity`: MRR=1.0000, Recall@target-count=1.0000, non-target ahead=0, margem mínima=0.3571;
- `strict_word_similarity`: MRR=1.0000, Recall@target-count=1.0000, non-target ahead=0, margem mínima=0.2857;
- `word_similarity`: MRR=1.0000, Recall@target-count=1.0000, non-target ahead=0, margem mínima=0.2857;
- artifact ID `9737773937`, ZIP SHA-256 `f904d01408099f48d103c14170eee6cebec2e3b636cc1bd1ead2c6468870a2c4`.

Os quatro métodos empatam na qualidade observada neste corpus pequeno. As escalas de margem são diferentes e não comparáveis diretamente entre Levenshtein e trigram. O resultado não identifica threshold de aceitação, custo em catálogo de produção, índice ideal nem política de fallback.

Audit: [`../audits/2026-08-30-discovery-typo-scoring-comparison.md`](../audits/2026-08-30-discovery-typo-scoring-comparison.md).

## Merge condition — #150

O PR #153 só fecha #150 após CI fresca do head que contém simultaneamente benchmark, workflow, audit e este snapshot, com Harness/relevantes verdes e sem review threads pendentes. A execução anterior acima é evidência da reprodução final-base, não substitui a prova fresca do head documental final.

## Next valid experiment after #150

O próximo candidato autônomo é um benchmark metamórfico de robustez, ainda sem mudança de produção:

1. derivar positivos de labels/consultas exatas cuja relevância é determinada pelo próprio catálogo congelado, sem importar `MATCH/NO_MATCH` de entity resolution como qrel de busca;
2. aplicar perturbações determinísticas de um caractere pré-declaradas antes de observar scores;
3. medir preservação do alvo, non-targets ahead, separação e custo dos mesmos scorers;
4. manter dataset, transformações e métricas versionados;
5. não promover método/cutoff enquanto o experimento não separar candidatos de forma reproduzível.

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
- #150: quatro scorers caracterizados no corpus #112; seleção de scorer/cutoff = NÃO DECIDIDA.

## Source of runtime truth

- Git/PR/checks do commit corrente;
- produto: [`../PRODUCT.md`](../PRODUCT.md);
- fatos derivados: [`../generated/repository-facts.md`](../generated/repository-facts.md);
- decisões: [`../MDV.md`](../MDV.md) e [`../adr/`](../adr/);
- cobertura funcional: [`../audits/2026-08-27-unified-functional-coverage-matrix.md`](../audits/2026-08-27-unified-functional-coverage-matrix.md);
- Advanced Discovery baseline: [`../audits/2026-08-29-advanced-discovery-baseline.md`](../audits/2026-08-29-advanced-discovery-baseline.md);
- typo scoring: [`../audits/2026-08-30-discovery-typo-scoring-comparison.md`](../audits/2026-08-30-discovery-typo-scoring-comparison.md);
- quantitative consumer: [`../audits/2026-08-29-podium-quantitative-consumer-benchmark.md`](../audits/2026-08-29-podium-quantitative-consumer-benchmark.md);
- Saved Search claim: [`../audits/2026-08-29-saved-search-postgres-claim-baseline.md`](../audits/2026-08-29-saved-search-postgres-claim-baseline.md);
- município IBGE: [`../audits/2026-08-29-ibge-municipality-identity-baseline.md`](../audits/2026-08-29-ibge-municipality-identity-baseline.md);
- Saved Search email: [`../audits/2026-08-29-saved-search-email-delivery-contract-baseline.md`](../audits/2026-08-29-saved-search-email-delivery-contract-baseline.md).

## Update rule

Atualize este snapshot somente quando mudar outcome, plano, acceptance target ou blocker real.

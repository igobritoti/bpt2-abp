# Current work

Last verified: **2026-08-30**

Este arquivo é um snapshot curto do trabalho corrente. Não é histórico, changelog nem inventário de CI.

## Active outcome

Não há atualmente feature grande automaticamente autorizada para execução autônoma.

A sequência de Advanced Discovery chegou até a fronteira válida sem promover fuzzy em produção:

- #150 concluída via PR #153 (squash `3d76e0075795d558e554ecd07fb208e9634d432f`): comparação inicial dos quatro scorers nos três typos congelados; nenhum scorer/cutoff selecionado;
- #154 concluída via PR #156 (squash `57c7f59f549ef0c9b96e87577c488cce43bafce6`): benchmark metamórfico com transformações pré-declaradas; `word_similarity` domina Levenshtein neste corpus, sem vencedor entre os três métodos trigram e sem autorização de cutoff/index/fuzzy;
- #157 concluída como audit de precondição: os corpus retidos de BPT2/Podium não fornecem cardinalidade independente ampla o bastante para um claim de scale/index sem reinterpretar aliases, registros parciais, model-years repetidos, códigos regulatórios ou fixtures sintéticas. O experimento foi corretamente marcado `SKIP` em vez de fabricar negativos.

Issues #113–#116 continuam explicitamente puladas para execução autônoma enquanto faltarem as autoridades externas/humanas documentadas.

## Evidence — #154 merged result

Reprodução funcional final-base no run `33333069839`, seguida por CI fresca no head documental final `bc4dea6ee3db0a158c65eed6048aea88696b0300`.

Resultado congelado:

- fixture SHA-256 `54028f4c7925ad2f2d9a8b1637d00ab7e013f43b4e10fea0ff88a9b87474bd20`;
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
- `word_similarity` ainda falha em três casos gerados (`Cof`, `Cmof`, `Hgih`).

CI fresca do head documental final fechou 7/7 verde:

- Harness `33333252908`;
- IBGE Municipality Identity `33333253061`;
- Podium Quantitative Consumer `33333252877`;
- Saved Search PostgreSQL Claim `33333253001`;
- Discovery Typo Scoring `33333252912`;
- Discovery Metamorphic Typo `33333252979`;
- Saved Search Email Delivery `33333252923`.

PR #156 foi squash-mergeado e #154 fechou como `completed`.

Audit: [`../audits/2026-08-30-discovery-metamorphic-typo-robustness.md`](../audits/2026-08-30-discovery-metamorphic-typo-robustness.md).

## #157 — scale/index precondition

Audit concluído sem executar scorer/cutoff novo.

Inspeção incluiu os corpus Podium de identidade BR/global, year semantics, adjacent/incomplete, operational E2E, EEA, Autoevolution/source-family, `official_source_discovery` e os snapshots `vehicle-makes-models` no pin histórico e no `main` atual do Podium.

Finding:

`INDEPENDENT_SCALE_CANDIDATE_POOL = INSUFFICIENT`

`SYNTHETIC_NEGATIVE_EXPANSION = REJECTED_FOR_SCALE_CLAIM`

`PODIUM_IDENTITY_OUTCOMES_AS_SEARCH_QRELS = REJECTED`

`REGULATORY_VARIANT_CODES_AS_PUBLIC_VERSION = REJECTED`

`DISCOVERY_CUTOFF_INDEX_SCALE_EXPERIMENT = SKIP_PENDING_INDEPENDENT_CATALOG_CARDINALITY`

O gatilho para reabrir scale/index é um catálogo versionado e materialmente mais amplo com identidade pública Brand/Model/Generation/Version adequada ao BPT2, ou snapshot BPT2 production-like sob política de teste autorizada. O dataset deve ser congelado antes de observar cutoff/index.

## Remaining blockers / skip rules

- #113 Recommendations: `SKIP` até qrel humano versionado ou exposure-aware behavioral data; Favorite/Lead positivos sem exposição não criam negativos válidos.
- #114 Market intelligence: external provider identifier projection já está entregue via #139; `SKIP` até quantidade de produto + provider/dataset autorizado/licenciado.
- #115 Trust/history/inspection: `SKIP` até provider + Listing-instance identity + purpose/privacy/retention/assertion contract.
- #116 True radius: município IBGE já está entregue via #135; `SKIP` até autoridade do ponto físico da Listing + provenance/precision/lifecycle/privacy.
- Discovery scale/index: `SKIP` conforme #157 até cardinalidade independente adequada.
- Resend produção: deployment externo; não reabre #118.
- Comparator/ficha técnica ampla: consumer boundary #122 provado, mas cobertura Brasil/produção e produto concreto ainda são gatilhos.
- Favorite price-drop externo: ainda exige authorization/delivery/recovery contract próprio; não herda consentimento de Favorite nem de Saved Search.

## Decisões consolidadas recentes

- #117: Saved Search detection runner PostgreSQL = implementado e verde.
- #118: `EMAIL_EACH_NEW_MATCH` por Saved Search = implementado e verde; Resend real permanece probe configurável, com `SKIP` correto sem credenciais/sender seguro.
- #122: quantitative consumer/comparability boundary = provado bounded; não autoriza promoção automática de campos/Comparator.
- #127/#111: `powertrain`, `transmission`, `body_style` = projetados como strings opacas nullable do Podium.
- #139/#114: external provider identifier projection = entregue; market-price source semantics/license continuam externos.
- #135/#116: município IBGE = provado; município/centroide não é ponto físico do veículo.
- #147: apresentação hífen/espaço = entregue após comparação controlada; typo permanece gap medido separado.
- #150: quatro scorers caracterizados nos três qrels typo; nenhum vencedor/cutoff selecionado.
- #154: robustez metamórfica separa `word_similarity` de Levenshtein, mas `TRIGRAM_METHOD_WINNER = NONE`.
- #157: scale/index = `SKIP` por falta de candidate pool independente suficientemente amplo.

## Next valid work

Não abrir implementação para preencher a fila artificialmente.

Próximo slice técnico só é válido quando ocorrer pelo menos um destes eventos:

1. surgir novo gap reproduzível em produto/código/teste;
2. um blocker #113–#116 receber a autoridade/dataset/contrato que sua própria issue exige;
3. aparecer um catálogo independente production-like suficiente para reabrir #157;
4. um item atualmente ADIADO ganhar pergunta operacional/comercial concreta e contrato mínimo correspondente.

Até lá, trabalho documental pode reconciliar índices stale com `PRODUCT.md`/evidência recente, mas não deve converter ausência de trabalho autorizado em requisito novo.

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
- Saved Search email: [`../audits/2026-08-29-saved-search-email-delivery-contract-baseline.md`](../audits/2026-08-29-saved-search-email-delivery-contract-baseline.md);
- issue #157 — audit de candidate cardinality para scale/index.

## Update rule

Atualize este snapshot somente quando mudar outcome, plano, acceptance target ou blocker real.

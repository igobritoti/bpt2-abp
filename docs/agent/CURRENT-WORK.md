# Current work

Last verified: **2026-08-30**

Snapshot curto do estado corrente. Evidência detalhada fica em `docs/audits/` e nos PRs/runs correspondentes.

## Active outcome

Não há feature grande automaticamente autorizada para execução autônoma.

Advanced Discovery chegou até a fronteira válida sem promover fuzzy em produção:

- #150 / PR #153, squash `3d76e0075795d558e554ecd07fb208e9634d432f`: quatro scorers caracterizados nos três typos congelados; nenhum scorer/cutoff selecionado.
- #154 / PR #156, squash `57c7f59f549ef0c9b96e87577c488cce43bafce6`: benchmark metamórfico com 33 casos válidos; `word_similarity` domina Levenshtein neste corpus, sem vencedor entre os três métodos trigram e sem autorização de cutoff/index/fuzzy.
- #157: audit de precondição concluiu `DISCOVERY_CUTOFF_INDEX_SCALE_EXPERIMENT = SKIP_PENDING_INDEPENDENT_CATALOG_CARDINALITY`; nenhum negativo sintético foi criado.

Issues #113–#116 continuam `SKIP` para execução autônoma enquanto faltarem as autoridades externas/humanas documentadas.

Repo governance encontrou um blocker separado em #160: `main` está `protected=false` e não há repository rulesets. O conector atual permite apenas leitura dessas configurações. TD-001 registra a dívida; não transformar workflows path-filtered em required contexts cegamente.

## #154 merged evidence

Resultado congelado:

- baseline exact/confusable/autocomplete/presentation: MRR=1.0000, Recall=1.0000, FP=0;
- typo de produção: MRR=0.0000, Recall=0.0000, FP=0;
- facet/filter oracle: 10/10;
- 39 mutações brutas, 33 válidas, 9 exclusões machine-recorded;
- Levenshtein: MRR=0.7281, Recall=0.6212, non-targets ahead=48;
- `similarity`: MRR=0.9066, Recall=0.8485, non-targets ahead=9;
- `strict_word_similarity`: MRR=0.9177, Recall=0.8788, non-targets ahead=10;
- `word_similarity`: MRR=0.9404, Recall=0.9091, non-targets ahead=7;
- `TRIGRAM_METHOD_WINNER = NONE`.

CI fresca do head documental final `bc4dea6ee3db0a158c65eed6048aea88696b0300` fechou 7/7 verde: Harness `33333252908`, IBGE `33333253061`, quantitative consumer `33333252877`, Saved Search claim `33333253001`, typo scoring `33333252912`, metamorphic `33333252979`, Saved Search email `33333252923`.

Audit: [`../audits/2026-08-30-discovery-metamorphic-typo-robustness.md`](../audits/2026-08-30-discovery-metamorphic-typo-robustness.md).

## #157 scale/index precondition

Foram inspecionados corpus Podium de identidade BR/global, year semantics, adjacent/incomplete, operational E2E, EEA, source-family/Autoevolution, `official_source_discovery` e snapshots `vehicle-makes-models`.

Finding:

- `INDEPENDENT_SCALE_CANDIDATE_POOL = INSUFFICIENT`;
- `SYNTHETIC_NEGATIVE_EXPANSION = REJECTED_FOR_SCALE_CLAIM`;
- `PODIUM_IDENTITY_OUTCOMES_AS_SEARCH_QRELS = REJECTED`;
- `REGULATORY_VARIANT_CODES_AS_PUBLIC_VERSION = REJECTED`.

Reabrir scale/index somente com catálogo versionado materialmente mais amplo e identidade pública Brand/Model/Generation/Version adequada ao BPT2, ou snapshot BPT2 production-like sob política de teste autorizada. Congelar o dataset antes de observar cutoff/index.

## Remaining blockers / skip rules

- #113 Recommendations: qrel humano versionado ou exposure-aware behavioral data.
- #114 Market intelligence: external IDs já entregues via #139; falta quantidade de produto + provider/dataset autorizado.
- #115 Trust/history/inspection: provider + Listing-instance identity + purpose/privacy/retention/assertion contract.
- #116 True radius: município IBGE já entregue via #135; falta ponto físico autorizado + provenance/precision/lifecycle/privacy.
- #160 Main integration enforcement: falta ruleset/branch-protection write administrativo; required status precisa desenho compatível com workflows path-filtered.
- Resend produção: deployment externo; não reabre #118.
- Comparator/ficha técnica ampla: #122 provou consumer boundary, não cobertura Brasil/produção nem produto concreto.
- Favorite price-drop externo: exige authorization/delivery/recovery contract próprio.

## Decisões recentes

- #117 Saved Search runner PostgreSQL = entregue e verde.
- #118 Saved Search email engineering boundary = entregue e verde.
- #122 quantitative consumer/comparability = provado bounded.
- #127 structural fields `powertrain`/`transmission`/`body_style` = entregues.
- #139 external provider identifiers = entregues.
- #135 município IBGE = entregue; município/centroide não é ponto físico.
- #147 hífen/espaço = entregue; typo continua gap separado.
- #150 scorer characterization = concluída sem cutoff.
- #154 metamorphic robustness = concluída sem vencedor trigram.
- #157 scale/index = `SKIP` por cardinalidade independente insuficiente.
- #160 main protection = gap confirmado; TD-001 registra a dívida administrativa.

## Next valid work

Não criar requisito para preencher a fila. Próximo slice técnico só é válido quando surgir novo gap reproduzível, um blocker #113–#116 receber sua autoridade/dataset/contrato, aparecer cardinalidade adequada para #157, #160 receber acesso administrativo/desenho de status enforcement, ou um item ADIADO ganhar pergunta concreta e contrato mínimo.

## Source of runtime truth

- produto: [`../PRODUCT.md`](../PRODUCT.md);
- cobertura: [`../audits/2026-08-27-unified-functional-coverage-matrix.md`](../audits/2026-08-27-unified-functional-coverage-matrix.md);
- discovery baseline: [`../audits/2026-08-29-advanced-discovery-baseline.md`](../audits/2026-08-29-advanced-discovery-baseline.md);
- typo scoring: [`../audits/2026-08-30-discovery-typo-scoring-comparison.md`](../audits/2026-08-30-discovery-typo-scoring-comparison.md);
- metamorphic: [`../audits/2026-08-30-discovery-metamorphic-typo-robustness.md`](../audits/2026-08-30-discovery-metamorphic-typo-robustness.md);
- generated facts: [`../generated/repository-facts.md`](../generated/repository-facts.md).

## Update rule

Atualize somente quando mudar outcome, plano, acceptance target ou blocker real.

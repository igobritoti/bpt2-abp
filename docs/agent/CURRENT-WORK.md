# Current work

Last verified: **2026-08-29**

Este arquivo é um snapshot curto do trabalho corrente. Não é histórico, changelog nem inventário de CI.

## Active outcome

Issue #122 / PR #130 executa o benchmark consumidor de `podium7.quantitative-enrichment.v1` antes de qualquer schema/UI de Comparator.

Issue #112 foi concluída e integrada no `main` pelo PR #129: o benchmark reproduzível de Discovery agora mede baseline exata, presentation/typo gaps, filtros/facets e custo no corpus fixo sem escolher tecnologia de busca avançada.

Issue #111 foi integrada no `main` pelo PR #127: `powertrain`, `transmission` e `body_style` já são projetados do Podium Catalog JSON `2.0` para o Vehicle canônico e Vehicle Hub como strings opacas nullable, com replay/null clearing e sem filtros públicos.

## Active plan

Nenhum execution plan separado foi aberto; o boundary executável atual é a issue #122 / PR #130.

Último plano concluído antes destes slices: [`../exec-plans/completed/0061-enforce-ephemeral-migration-authority.md`](../exec-plans/completed/0061-enforce-ephemeral-migration-authority.md).

## Evidência quantitative consumer #122

Primeira execução verde: run `33282078314`, artifact `9723278865`.

- producer pin: `gestbrito/podium7@fad13769cbdc79fea7d87b9a9bebca3a41240557`;
- schema producer: `podium7.quantitative-enrichment.v1`;
- fixture BPT2 SHA-256: `a7a0012a83488a73d7d73989348c3ba3fe4a34751276a56c490da4d4691167f8`;
- payloads aceitos: `15/15`;
- negative controls rejeitados: `2/2`;
- raw envelope lossless: `15/15`;
- strict typed projection lossless: `15/15`;
- comparison oracle: `12/12`;
- canonical + historical Podium redirect convergem para o mesmo BPT2 `VehicleId` antes do consumo quantitativo;
- replay idêntico não muda estado; correction muda revision no mesmo VehicleId; unresolved conflict substitui o canonical fact e falha fechado;
- `unknown`, `not_applicable`, conflict, context mismatch, limit/multiple e unit mismatch não geram vencedor arbitrário;
- conversão `kW ↔ hp` não é inferida;
- nenhum campo quantitativo foi promovido como product-ready porque cobertura Brasil/produção continua insuficiente.

Auditoria: [`../audits/2026-08-29-podium-quantitative-consumer-benchmark.md`](../audits/2026-08-29-podium-quantitative-consumer-benchmark.md).

## Evidência Discovery #112

- corpus: `benchmarks/discovery_br_v1.json`, schema `bpt2.discovery-benchmark.v1`;
- fixture SHA-256: `54028f4c7925ad2f2d9a8b1637d00ab7e013f43b4e10fea0ff88a9b87474bd20`;
- exact/confusable/prefix: MRR/Recall `1.0000` no Catalog e public path, zero false positives no corpus delimitado;
- presentation (`T Cross` vs `T-Cross`): MRR/Recall `0`;
- typos determinísticos: MRR/Recall `0`;
- facet/filter oracle: `10/10`;
- mediana dos p50 por query: ~`2.55 ms` Catalog e ~`6.45 ms` public path no corpus de 8 Vehicles/8 Listings públicas;
- nenhuma tecnologia de busca avançada está autorizada por consequência.

Auditoria: [`../audits/2026-08-29-advanced-discovery-baseline.md`](../audits/2026-08-29-advanced-discovery-baseline.md).

## Próximos gatilhos independentes

- fechar #122 somente após documentação, Harness/benchmark frescos e review/merge;
- recomendações permanecem dependentes de ground truth válido (#113);
- delivery externo de Saved Search somente após consentimento por canal, destinatário verificável e estado durável/recovery do side effect;
- delivery externo de Favorite price-drop somente após canal/consentimento/destinatário verificável e durable delivery contract;
- deployment/locking reproduzível para claim/retry/restart do runner de Saved Search;
- filtros públicos ou Saved Search por `powertrain`/`transmission`/`body_style` continuam não autorizados até hipótese e benchmark próprios;
- dataset/licença/metodologia/provenance para inteligência de mercado;
- evidência operacional suficiente para trust/moderação avançada;
- tese comercial/parceria concreta para complementares.

## Source of runtime truth

- Estado de branch/PR/checks: Git e GitHub Actions do commit corrente.
- Produto: [`../PRODUCT.md`](../PRODUCT.md).
- Fatos derivados: [`../generated/repository-facts.md`](../generated/repository-facts.md).
- Decisões: [`../MDV.md`](../MDV.md) e [`../adr/`](../adr/).
- Cobertura funcional: [`../audits/2026-08-27-unified-functional-coverage-matrix.md`](../audits/2026-08-27-unified-functional-coverage-matrix.md).
- Baseline Discovery: [`../audits/2026-08-29-advanced-discovery-baseline.md`](../audits/2026-08-29-advanced-discovery-baseline.md).
- Benchmark quantitative consumer: [`../audits/2026-08-29-podium-quantitative-consumer-benchmark.md`](../audits/2026-08-29-podium-quantitative-consumer-benchmark.md).
- Consumer contract técnico: [`../audits/2026-08-27-vehicle-technical-sheet-consumer-contract.md`](../audits/2026-08-27-vehicle-technical-sheet-consumer-contract.md).
- CI/migration authority: [`../audits/2026-08-28-ci-smoke-and-migration-authority.md`](../audits/2026-08-28-ci-smoke-and-migration-authority.md).

## Open blockers

- Saved Search runner: deployment contract cross-instance ainda não fechado; PostgreSQL-coordinated claim é o primeiro baseline experimental definido em #117.
- Saved Search external delivery: primeiro experimento definido como e-mail/fake provider, mas produção continua dependente de canal, destinatário verificável, cadence e provider contract (#118).
- Favorite price-drop external delivery: sem opt-in externo específico + provider/canal + durable delivery/recovery contract.
- Comparator/ficha técnica ampla: o consumer shape/state/comparability boundary de #122 está provado no fixture delimitado, mas cobertura Brasil/produção continua insuficiente; PBEV/coverage permanecem upstream-gated. Isso é separado da projeção categórica #111.
- Discovery avançado: baseline #112 mede gaps reais de presentation/typo; nenhuma implementação candidata foi comparada ainda sob o mesmo corpus.
- Recomendações: ground truth/exposure protocol ainda não existe (#113).
- Inteligência de mercado: sem quantidade/provider/licença/metodologia/provenance concretos (#114).
- Trust/histórico: depende de autorização/contrato/purpose/privacy específicos (#115).
- True radius: depende de autoridade para o ponto físico da Listing e privacy; municipality-code baseline é separado (#116).
- Carros na Web: inventário público atual ainda não reproduzível; acesso direto continua falhando.

## Update rule

Atualize este snapshot somente quando mudar outcome, plano, acceptance target ou blocker real.

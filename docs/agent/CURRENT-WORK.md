# Current work

Last verified: **2026-08-29**

Este arquivo é um snapshot curto do trabalho corrente. Não é histórico, changelog nem inventário de CI.

## Active outcome

Issue #112 / PR #128 executa e versiona o primeiro benchmark reproduzível de Discovery avançado sem alterar o comportamento de busca.

Issue #111 foi integrada no `main` pelo PR #127: `powertrain`, `transmission` e `body_style` já são projetados do Podium Catalog JSON `2.0` para o Vehicle canônico e Vehicle Hub como strings opacas nullable, com replay/null clearing e sem filtros públicos.

## Active plan

Nenhum execution plan separado foi aberto; o boundary executável atual é a issue #112 / PR #128.

Último plano concluído antes destes slices: [`../exec-plans/completed/0061-enforce-ephemeral-migration-authority.md`](../exec-plans/completed/0061-enforce-ephemeral-migration-authority.md).

## Evidência Discovery #112

A primeira execução em PostgreSQL 17 passou build, Fresh Migration, corpus, oracle e artifact upload.

- corpus: `benchmarks/discovery_br_v1.json`, schema `bpt2.discovery-benchmark.v1`;
- fixture SHA-256: `54028f4c7925ad2f2d9a8b1637d00ab7e013f43b4e10fea0ff88a9b87474bd20`;
- run: `33281478439`;
- artifact: `9723127679`;
- exact/confusable/prefix: MRR/Recall `1.0000` no Catalog e public path, zero false positives no corpus delimitado;
- presentation (`T Cross` vs `T-Cross`): MRR/Recall `0`;
- typos determinísticos: MRR/Recall `0`;
- facet/filter oracle: `10/10`;
- mediana dos p50 por query: ~`2.55 ms` Catalog e ~`6.45 ms` public path no corpus de 8 Vehicles/8 Listings públicas;
- nenhuma tecnologia de busca avançada está autorizada por consequência.

Auditoria detalhada: [`../audits/2026-08-29-advanced-discovery-baseline.md`](../audits/2026-08-29-advanced-discovery-baseline.md).

## Próximos gatilhos independentes

- fechar #112 somente após CI fresco do head documental e gate de review/merge;
- executar o consumer/comparability benchmark #122 antes de Comparator, mesmo com o contrato separado `podium7.quantitative-enrichment.v1` já existente;
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
- Consumer contract técnico: [`../audits/2026-08-27-vehicle-technical-sheet-consumer-contract.md`](../audits/2026-08-27-vehicle-technical-sheet-consumer-contract.md).
- CI/migration authority: [`../audits/2026-08-28-ci-smoke-and-migration-authority.md`](../audits/2026-08-28-ci-smoke-and-migration-authority.md).

## Open blockers

- Saved Search runner: deployment contract cross-instance ainda não fechado; PostgreSQL-coordinated claim é o primeiro baseline experimental definido em #117.
- Saved Search external delivery: primeiro experimento definido como e-mail/fake provider, mas produção continua dependente de canal, destinatário verificável, cadence e provider contract (#118).
- Favorite price-drop external delivery: sem opt-in externo específico + provider/canal + durable delivery/recovery contract.
- Comparator/ficha técnica ampla: o contrato quantitativo Podium existe, mas o consumer/comparability benchmark BPT2 #122 ainda precisa ser executado; isso é separado da projeção categórica #111.
- Discovery avançado: baseline #112 agora mede gaps reais de presentation/typo; nenhuma implementação candidata foi comparada ainda sob o mesmo corpus.
- Recomendações: ground truth/exposure protocol ainda não existe (#113).
- Inteligência de mercado: sem quantidade/provider/licença/metodologia/provenance concretos (#114).
- Trust/histórico: depende de autorização/contrato/purpose/privacy específicos (#115).
- True radius: depende de autoridade para o ponto físico da Listing e privacy; municipality-code baseline é separado (#116).
- Carros na Web: inventário público atual ainda não reproduzível; acesso direto continua falhando.

## Update rule

Atualize este snapshot somente quando mudar outcome, plano, acceptance target ou blocker real.

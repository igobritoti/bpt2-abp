# Current work

Last verified: **2026-08-29**

Este arquivo é um snapshot curto do trabalho corrente. Não é histórico, changelog nem inventário de CI.

## Active outcome

Issue #117 / PR #132 executa o primeiro benchmark cross-worker do runner de Saved Search sem habilitar runner automático.

Issue #122 foi concluída e integrada no `main` pelo PR #131: o consumer quantitativo lossless/comparability boundary foi provado no fixture delimitado; Comparator continua bloqueado por cobertura Brasil/produção.

Issue #112 foi concluída e integrada no `main` pelo PR #129: o benchmark reproduzível de Discovery mede baseline exata, gaps de presentation/typo, filtros/facets e custo no corpus fixo sem escolher tecnologia de busca avançada.

Issue #111 foi integrada no `main` pelo PR #127: `powertrain`, `transmission` e `body_style` são projetados do Podium Catalog JSON `2.0` para Vehicle/Vehicle Hub como strings opacas nullable, sem filtros públicos.

## Active plan

Fechar o benchmark de coordenação PostgreSQL do #117 com documentação, gate funcional de Saved Search, Harness/CI fresco, review e merge. A issue #117 permanece aberta após o merge porque deployment topology, cadence, retry/backoff e full-detection transaction boundary ainda não estão estabelecidos.

## Evidência Saved Search runner #117

Green run: `33282515587`, artifact `9723418523`, artifact ZIP SHA-256 `d14fbd80aeb82c3289625afe80d36d7ca3dd27c109f4890560e6440be8c893b9`.

- PostgreSQL 17 + Fresh Migration Gate: verde;
- `FOR UPDATE SKIP LOCKED LIMIT 1` dentro de transação entregou ownership disjunto para workers concorrentes;
- rollback/cancellation tornou trabalho incompleto elegível novamente;
- match já persistido + owner rollback convergiu em replay para exatamente um match;
- item bloqueado/lento não impediu progresso independente;
- request concluído não foi reclaimed;
- corrida de enqueue convergiu em uma linha; constraint única funcionou como backstop, não como worker coordination;
- tempos observados neste CI: warm-up claim `314.3055 ms`, segundo worker `8.3492 ms`, reclaim `2.2502 ms`, transação observada `9.1788 ms`;
- nenhum desses tempos é SLO/threshold de produto.

Auditoria: [`../audits/2026-08-29-saved-search-postgres-claim-baseline.md`](../audits/2026-08-29-saved-search-postgres-claim-baseline.md).

## Decisões atuais

- `POSTGRES_TRANSACTIONAL_CLAIM_PRIMITIVE = PROVED_BOUNDED`;
- `MATCH_LEDGER_REPLAY_IDEMPOTENCY = PROVED_BOUNDED`;
- `UNIQUE_CONSTRAINT_AS_WORKER_COORDINATION = REJECTED`;
- `DURABLE_CLAIM_COLUMNS = NOT_JUSTIFIED_YET`;
- `AUTOMATIC_RUNNER = NOT_YET_AUTHORIZED`;
- `PRODUCTION_DEPLOYMENT_TOPOLOGY = STILL_UNESTABLISHED`;
- `POLL_LEASE_RETRY_THRESHOLDS = UNSET`;
- `HANGFIRE_QUARTZ_REDIS = NOT_JUSTIFIED`.

## Próximos gatilhos independentes

- #117: obter fatos concretos de deployment/process lifetime antes de autorizar runner automático;
- #118: delivery externo somente após canal, consentimento, destinatário verificável e durable side-effect/recovery contract;
- #113: recomendações dependem de ground truth/exposure protocol válido;
- #114: inteligência de mercado depende de provider/licença/metodologia/provenance concretos;
- #115: trust/histórico depende de autorização/contrato/purpose/privacy específicos;
- #116: true radius depende de autoridade para ponto físico da Listing e privacy;
- Comparator continua bloqueado por cobertura Brasil/produção, apesar do consumer boundary de #122 estar provado.

## Source of runtime truth

- Estado de branch/PR/checks: Git e GitHub Actions do commit corrente.
- Produto: [`../PRODUCT.md`](../PRODUCT.md).
- Fatos derivados: [`../generated/repository-facts.md`](../generated/repository-facts.md).
- Decisões: [`../MDV.md`](../MDV.md) e [`../adr/`](../adr/).
- Cobertura funcional: [`../audits/2026-08-27-unified-functional-coverage-matrix.md`](../audits/2026-08-27-unified-functional-coverage-matrix.md).
- Baseline Discovery: [`../audits/2026-08-29-advanced-discovery-baseline.md`](../audits/2026-08-29-advanced-discovery-baseline.md).
- Benchmark quantitative consumer: [`../audits/2026-08-29-podium-quantitative-consumer-benchmark.md`](../audits/2026-08-29-podium-quantitative-consumer-benchmark.md).
- Saved Search claim baseline: [`../audits/2026-08-29-saved-search-postgres-claim-baseline.md`](../audits/2026-08-29-saved-search-postgres-claim-baseline.md).

## Open blockers

- Saved Search runner: deployment topology/cadence/retry/full-detection transaction boundary ainda não fixados (#117).
- Saved Search external delivery: canal/consentimento/destinatário/cadence/provider e durable delivery/recovery continuam pendentes (#118).
- Comparator/ficha técnica ampla: cobertura Brasil/produção insuficiente; PBEV/coverage continuam upstream-gated.
- Discovery avançado: baseline mede gaps reais, mas nenhuma implementação candidata foi comparada sob o mesmo corpus.
- Recomendações, market intelligence, trust e true radius permanecem bloqueados pelos respectivos contracts/evidence gates.

## Update rule

Atualize este snapshot somente quando mudar outcome, plano, acceptance target ou blocker real.

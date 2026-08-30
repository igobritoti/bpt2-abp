# Current work

Last verified: **2026-08-29**

Este arquivo é um snapshot curto do trabalho corrente. Não é histórico, changelog nem inventário de CI.

## Active outcome

Issue #118 / PR #136 executa o primeiro boundary durável provider-neutral para futura entrega externa de alertas de Saved Search por email, sem selecionar provedor real nem enviar email real.

Issue #116 teve a baseline de identidade municipal IBGE integrada no `main` pelo PR #135; true physical radius continua bloqueado por autoridade do ponto físico da Listing e privacy/minimization.

Issue #117 teve o benchmark PostgreSQL de claim/recovery integrado no `main` pelo PR #133 e agora também possui runner automático provider-neutral com retry diferido por `NextAttemptAtUtc`. A validação local do build ficou bloqueada por restore NuGet externo; a operação de produção ainda precisa da decisão de rollout, mas a topologia de execução não está mais ausente.

Issue #122 foi concluída e integrada pelo PR #131; o consumer quantitativo lossless/comparability boundary foi provado no fixture delimitado, enquanto Comparator continua bloqueado por cobertura Brasil/produção.

Issue #112 foi concluída e integrada pelo PR #129; o benchmark reproduzível de Discovery mede baseline exata, gaps de presentation/typo, facets e custo no corpus fixo sem escolher tecnologia avançada.

Issue #111 foi concluída pelo PR #127 e reconciliada como `completed`: `powertrain`, `transmission` e `body_style` são projetados do Podium Catalog JSON `2.0` para Vehicle/Vehicle Hub como strings opacas nullable, sem filtros públicos.

## Active plan

Fechar #118 com o durable delivery-intent boundary, documentação, Harness/CI fresco, review e merge. A issue #118 permanece aberta após esse slice porque product email-consent authority, real-provider sandbox, cadence/retry policy e operação de produção continuam não estabelecidos.

## Evidência delivery externo #118

Green provider-neutral benchmark run: `33285470611`.

Artifact:

- ID `9724291877`;
- size `951` bytes;
- ZIP SHA-256 `026c6a87251492c90c315206887890655d38f7ae511f23ce6eb8f47364be4b7b`.

Medições:

- Fresh Migration Gate: verde;
- `11` scenario records cobrindo `12` acceptance conditions lógicas, pois criação + exact replay são verificadas juntas;
- `9` fake-provider calls;
- `4` logical acceptances após deduplicação por idempotency key;
- durable intent único por `(SavedSearchAlertMatchId, Channel)`;
- nenhum endereço de email persistido no intent de Marketplace;
- recipient verification + external-email authorization revalidados no dispatch;
- timeout com outcome desconhecido preservado explicitamente;
- accepted-then-crash converge com a mesma idempotency key no fake provider;
- opt-out antes da chamada suprime sem provider call;
- mudança de endereço antes da chamada usa somente o endereço atual;
- permanent vs transient permanecem estados distintos;
- callback `Delivered` replay converge idempotentemente;
- falha de uma intent não bloqueia progresso independente.

Auditoria: [`../audits/2026-08-29-saved-search-email-delivery-contract-baseline.md`](../audits/2026-08-29-saved-search-email-delivery-contract-baseline.md).

## Decisões atuais

- `DURABLE_EMAIL_DELIVERY_INTENT = PROVED_BOUNDED`;
- `RECIPIENT_ADDRESS_STORED_IN_MARKETPLACE = NO`;
- `DISPATCH_TIME_RECIPIENT_REVALIDATION = PROVED_BOUNDED`;
- `MONITORING_OPT_IN_AS_EXTERNAL_EMAIL_CONSENT = REJECTED`;
- `OUTCOME_UNKNOWN_AS_EXPLICIT_STATE = PROVED_BOUNDED`;
- `PROVIDER_NEUTRAL_IDEMPOTENCY_RECOVERY = PROVED_BOUNDED_WITH_FAKE_PROVIDER`;
- `REAL_EMAIL_PROVIDER = NOT_SELECTED`;
- `PRODUCTION_EMAIL_CONSENT_AUTHORITY = STILL_REQUIRED`;
- `PRODUCTION_CADENCE = UNSET`;
- `REAL_EMAIL_SENDING = NOT_AUTHORIZED_BY_THIS_BENCHMARK`;
- `MUNICIPALITY_IDENTITY_AUTHORITY = IBGE_DTB_2025_PINNED` (#116);
- `TRUE_LISTING_RADIUS = STILL_BLOCKED_ON_LOCATION_POINT_AUTHORITY_AND_PRIVACY` (#116);
- `POSTGRES_TRANSACTIONAL_CLAIM_PRIMITIVE = PROVED_BOUNDED` (#117);
- `AUTOMATIC_RUNNER = PROVISIONED_IN_CODE` (#117).

## Próximos gatilhos independentes

- #118: depois deste fake-provider boundary, definir uma autoridade real de consentimento externo e só então executar sandbox de provedor preservando recipient revalidation/idempotency semantics; Resend/SES continuam candidatos, não decisão de produção;
- #117: runner automático já está provisionado no código; falta apenas validar em build/CI com restore disponível e decidir rollout operacional;
- #116: true radius continua separado e bloqueado em point authority/privacy;
- #113: recomendações dependem de ground truth/exposure protocol válido;
- #114: inteligência de mercado depende de provider/licença/metodologia/provenance concretos;
- #115: trust/histórico depende de autorização/contrato/purpose/privacy específicos;
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
- Município IBGE: [`../audits/2026-08-29-ibge-municipality-identity-baseline.md`](../audits/2026-08-29-ibge-municipality-identity-baseline.md).
- Saved Search external email delivery: [`../audits/2026-08-29-saved-search-email-delivery-contract-baseline.md`](../audits/2026-08-29-saved-search-email-delivery-contract-baseline.md).

## Open blockers

- Saved Search external delivery: durable provider-neutral recovery boundary provado; product email-consent authority, real-provider sandbox, cadence/retry policy e production operation continuam pendentes (#118).
- Saved Search runner: boundary transacional e runner automático provisionados; resta validar build/CI e rollout operacional (#117).
- True radius: falta autoridade para ponto físico da Listing + privacy/minimization; município/centroide não é veículo (#116).
- Comparator/ficha técnica ampla: cobertura Brasil/produção insuficiente.
- Discovery avançado: baseline mede gaps reais, mas nenhuma implementação candidata foi comparada sob o mesmo corpus.
- Recomendações, market intelligence e trust permanecem bloqueados pelos respectivos contracts/evidence gates.

## Update rule

Atualize este snapshot somente quando mudar outcome, plano, acceptance target ou blocker real.

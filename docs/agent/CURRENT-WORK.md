# Current work

Last verified: **2026-08-30**

Este arquivo é um snapshot curto do trabalho corrente. Não é histórico, changelog nem inventário de CI.

## Active outcome

Issue #118 / draft PR #145 implementa o contrato explícito de autorização externa `EMAIL_EACH_NEW_MATCH`, runner provider-neutral e boundary Resend/webhook para alertas de Saved Search.

Issue #117 foi concluída e integrada em `main` pelo PR #144 (squash `122594aea314388282cd4e53c5e70997b15e6984`).

Issue #118 já possuía, desde o PR #137, o ledger provider-neutral durável de delivery intent, idempotency key estável, recipient revalidation boundary e fake-provider recovery matrix. O PR #145 não recria esse baseline: adiciona autorização explícita por busca, dispatch automático, recipient atual confirmado, adapter/probe Resend e webhook autenticado/idempotente sem segredos no repositório.

## Active plan

1. Manter o head funcional de #118 estável enquanto roda a validação fresca.
2. Validar o benchmark provider-neutral/Resend após a correção do fixture que chamava `AbpDbContext.SaveChangesAsync` fora do runtime ABP.
3. Validar Harness após atualização dos fatos gerados para o novo fixture/projeto.
4. Confirmar Fresh Migration, Host, Public Buyer/Web, claim benchmark e demais gates relevantes no mesmo head final.
5. Confirmar que o probe Resend real reporta SKIP, e não PASS, quando credenciais externas não estão configuradas.
6. Fazer review/thread/base refresh, atualizar PR para ready quando a matriz de engenharia estiver verde e mergear somente então.
7. Verificar fechamento de #118 e `main` remoto após o merge.

## Repo health

- Os workflows de Saved Search agora cancelam runs superseded por PR e o benchmark de claim passou a observar o processor real `SavedSearchAlertDetectionProcessor.cs` e o request row correspondente, em vez de um nome antigo de app service.

## Decisões atuais

- `EMAIL_EACH_NEW_MATCH_DEFAULT = OFF`;
- `EMAIL_EACH_NEW_MATCH_SCOPE = PER_SAVED_SEARCH`;
- `EXISTING_ALERT_ENABLED_AS_EMAIL_CONSENT = REJECTED`;
- `FIRST_EMAIL_CADENCE = EXPLICIT_PER_MATCH_SELECTION`;
- `RECIPIENT_AUTHORITY = CURRENT_ACTIVE_CONFIRMED_IDENTITY_EMAIL`;
- `RECIPIENT_ADDRESS_STORED_IN_MARKETPLACE = NO`;
- `DURABLE_DELIVERY_INTENT = EXISTS`;
- `PROVIDER_NEUTRAL_RECOVERY = PROVED_BOUNDED`;
- `AUTOMATIC_EMAIL_DELIVERY_RUNNER = IMPLEMENTED`;
- `FIRST_SANDBOX_PROBE = RESEND`;
- `PROVIDER_ACCEPTED_EQUALS_DELIVERED = NO`;
- `RESEND_WEBHOOK_AUTHENTICITY = IMPLEMENTED`;
- `RESEND_WEBHOOK_REPLAY = DURABLE_ATOMIC_LEDGER`;
- `OPEN_CLICK_TRACKING = NOT_AUTHORIZED`;
- `PRODUCTION_PROVIDER_ACTIVATION = EXTERNAL_DEPLOYMENT_ACTION`;
- `POSTGRES_TRANSACTIONAL_CLAIM_PRIMITIVE = PROVED_BOUNDED` (#117);
- `AUTOMATIC_SAVED_SEARCH_DETECTION_RUNNER = PROVISIONED_AND_GREEN` (#117).

## Evidence on the current slice

Focused local builds were green with `RestoreIgnoreFailedSources=true` for:

- `modules/marketplace/src/BomPraTi.Marketplace/BomPraTi.Marketplace.csproj`;
- `tests/BomPraTi.SavedSearchEmailDeliveryBenchmarkFixture/BomPraTi.SavedSearchEmailDeliveryBenchmarkFixture.csproj`;
- `tests/BomPraTi.ResendSavedSearchEmailProbeFixture/BomPraTi.ResendSavedSearchEmailProbeFixture.csproj`.

On remote head `84d4f6bf6ac9dd05db1bae2eb3248b880906b75e`, 21 of 23 workflows were green. The two focused failures were diagnosed from logs rather than retried blindly:

- Saved Search Email Delivery Benchmark: build and fresh migration were green; execution failed because the fixture manually constructed an ABP DbContext and then called `SaveChangesAsync`, which requires runtime DI services. The fixture setup was changed to direct PostgreSQL state preparation and the production provider-event processor was strengthened to use an atomic unique-ledger claim.
- Harness Gate: only `docs/generated/repository-facts.md` was stale after adding the new test project; generated counters were reconciled.

The active head after those corrections and documentation reconciliation must receive a fresh CI round before merge. Earlier green results are supporting evidence, not a substitute for final-head CI.

## Source of runtime truth

- Estado de branch/PR/checks: Git e GitHub Actions do commit corrente.
- Produto: [`../PRODUCT.md`](../PRODUCT.md).
- Fatos derivados: [`../generated/repository-facts.md`](../generated/repository-facts.md).
- Decisões: [`../MDV.md`](../MDV.md) e [`../adr/`](../adr/).
- Saved Search claim baseline: [`../audits/2026-08-29-saved-search-postgres-claim-baseline.md`](../audits/2026-08-29-saved-search-postgres-claim-baseline.md).
- Saved Search external email delivery baseline: [`../audits/2026-08-29-saved-search-email-delivery-contract-baseline.md`](../audits/2026-08-29-saved-search-email-delivery-contract-baseline.md).

## Open blockers

- Nenhum blocker de engenharia conhecido impede o slice #118 definido na issue; o boundary atual é validação fresca do head final, review e merge.
- O probe Resend real depende de credencial, sender/domain e recipient seguro fornecidos externamente; ausência desses itens deve permanecer `SKIP`/evidência não executada.
- Production commercial activation, provider account approval, DPA/legal approval e production secrets continuam ações externas de deployment, não requisitos para manter #118 aberta depois do contrato executável ficar verde.

## Parallel precondition reconciliation

Enquanto #118 aguardava CI, as issues #114 e #116 foram revalidadas contra `main` sem criar features especulativas:

- #114: external provider identifiers já são normalizados pelo Podium feed, preservados em raw identity e sincronizados/persistidos no Catalog com ownership único por `Authority + Namespace + Value`; o blocker remanescente é semântica/source/license de market price, não identity projection.
- #116: o benchmark IBGE DTB 2025 já fixa source/member hashes, prova o boundary `City + UF` de identidade municipal e preserva unidades especiais; true Listing radius continua bloqueado em location-point authority/privacy e nenhuma semântica de centroid/PostGIS foi promovida.

## Update rule

Atualize este snapshot somente quando mudar outcome, plano, acceptance target ou blocker real.
# Current work

Last verified: **2026-08-30**

Este arquivo é um snapshot curto do trabalho corrente. Não é histórico, changelog nem inventário de CI.

## Active outcome

Issue #118 / draft PR #145 executa o contrato explícito de autorização externa `EMAIL_EACH_NEW_MATCH` e o boundary de dispatch Resend para alertas de Saved Search.

Issue #117 foi concluída e integrada em `main` pelo PR #144 (squash `122594aea314388282cd4e53c5e70997b15e6984`). O head validado teve 21 workflows verdes, incluindo o benchmark PostgreSQL de claim/recovery e o correctness slice de retry/cancellation.

Issue #118 já possui, desde o PR #137, o ledger provider-neutral durável de delivery intent, idempotency key estável, recipient revalidation boundary e fake-provider recovery matrix. O trabalho corrente não recria esse baseline: adiciona autorização explícita por busca, dispatch automático e adapter/probe Resend sem segredos no repositório.

## Active plan

1. Persistir autorização `EMAIL_EACH_NEW_MATCH` independente de `AlertEnabled`, default OFF, com operações Buyer autenticadas e UI explícita.
2. Criar intents de email somente para novos matches quando monitoramento e autorização estiverem válidos.
3. Evoluir delivery intent para claim/lease/retry durável sem manter lock de banco durante I/O externo.
4. Resolver email atual confirmado em Identity imediatamente antes do send, sem persistir endereço no Marketplace.
5. Implementar adapter Resend com idempotency key estável, taxonomia transient/permanent/ambiguous e webhook autenticado/idempotente.
6. Preservar e ampliar benchmarks provider-neutral; executar probe real somente quando credencial/recipient seguro estiverem configurados.
7. Fechar #118 somente após CI fresco, review/base refresh e merge verde.

## Decisões atuais

- `EMAIL_EACH_NEW_MATCH_DEFAULT = OFF`;
- `EMAIL_EACH_NEW_MATCH_SCOPE = PER_SAVED_SEARCH`;
- `EXISTING_ALERT_ENABLED_AS_EMAIL_CONSENT = REJECTED`;
- `FIRST_EMAIL_CADENCE = EXPLICIT_PER_MATCH_SELECTION`;
- `RECIPIENT_AUTHORITY = CURRENT_VERIFIED_IDENTITY_EMAIL`;
- `RECIPIENT_ADDRESS_STORED_IN_MARKETPLACE = NO`;
- `DURABLE_DELIVERY_INTENT = EXISTS`;
- `PROVIDER_NEUTRAL_RECOVERY = PROVED_BOUNDED`;
- `FIRST_SANDBOX_PROBE = RESEND`;
- `PRODUCTION_PROVIDER_ACTIVATION = EXTERNAL_DEPLOYMENT_ACTION`;
- `POSTGRES_TRANSACTIONAL_CLAIM_PRIMITIVE = PROVED_BOUNDED` (#117);
- `AUTOMATIC_SAVED_SEARCH_DETECTION_RUNNER = PROVISIONED_AND_GREEN` (#117).

## Validação local

Compilações focadas verdes com `RestoreIgnoreFailedSources=true`:

- `modules/marketplace/src/BomPraTi.Marketplace/BomPraTi.Marketplace.csproj`;
- `tests/BomPraTi.SavedSearchEmailDeliveryBenchmarkFixture/BomPraTi.SavedSearchEmailDeliveryBenchmarkFixture.csproj`;
- `tests/BomPraTi.ResendSavedSearchEmailProbeFixture/BomPraTi.ResendSavedSearchEmailProbeFixture.csproj`.

## Source of runtime truth

- Estado de branch/PR/checks: Git e GitHub Actions do commit corrente.
- Produto: [`../PRODUCT.md`](../PRODUCT.md).
- Fatos derivados: [`../generated/repository-facts.md`](../generated/repository-facts.md).
- Decisões: [`../MDV.md`](../MDV.md) e [`../adr/`](../adr/).
- Saved Search claim baseline: [`../audits/2026-08-29-saved-search-postgres-claim-baseline.md`](../audits/2026-08-29-saved-search-postgres-claim-baseline.md).
- Saved Search external email delivery baseline: [`../audits/2026-08-29-saved-search-email-delivery-contract-baseline.md`](../audits/2026-08-29-saved-search-email-delivery-contract-baseline.md).

## Open blockers

- Nenhum blocker de engenharia impede o slice #118 definido na issue.
- O probe Resend real depende de credencial, sender/domain e recipient seguro fornecidos externamente; ausência desses itens não autoriza inventar evidência nem segredo.
- Production commercial activation, provider account approval, DPA/legal approval e production secrets continuam ações externas de deployment, não requisitos para manter #118 aberta depois do contrato executável ficar verde.

## Update rule

Atualize este snapshot somente quando mudar outcome, plano, acceptance target ou blocker real.

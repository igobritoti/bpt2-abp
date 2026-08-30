# Current work

Last verified: **2026-08-30**

Este arquivo é um snapshot curto do trabalho corrente. Não é histórico, changelog nem inventário de CI.

## Active outcome

Issue #118 foi concluída e integrada em `main` pelo PR #145 (squash `b6a9e2e693be2a80de32cdc38ee52ca910a44de2`). O boundary entregue inclui autorização explícita por Saved Search `EMAIL_EACH_NEW_MATCH`, dispatch automático provider-neutral, recipient atual ativo+confirmado vindo de Identity, adapter Resend, webhook autenticado/idempotente e ledger durável de eventos do provider.

Issue #117 já havia sido concluída e integrada em `main` pelo PR #144 (squash `122594aea314388282cd4e53c5e70997b15e6984`), incluindo claim PostgreSQL, runner automático e correctness de retry/cancellation.

Não há outro slice de implementação automaticamente autorizado neste snapshot. As issues abertas #113–#116 permanecem em boundaries de autoridade, provider, dataset, privacy ou ground truth. Advanced Discovery possui benchmark reproduzível e gaps medidos, mas qualquer candidato de melhoria precisa ser comparado no corpus/qrels congelado antes de promoção de tecnologia ou feature.

## Evidence — #118 final

Head final validado do PR #145: `a735495707e4486ad75787e2398944d94ed9d280`.

- GitHub Actions: **23/23 workflows verdes** no mesmo head final;
- Saved Search Email Delivery Benchmark: `PASS`;
- cenário provider-neutral: `12` scenarios, `9` provider calls, `4` logical acceptances;
- Fresh Migration Gate: verde;
- Harness, Host, Public Web, Public Buyer, Public Discovery, Saved Search claim e regressões relevantes: verdes;
- Resend bounded probe: `SKIP` porque `BPT_RESEND_API_KEY`, sender, safe recipient e public URL não estavam configurados;
- o `SKIP` é a evidência correta para ausência de credenciais externas e não foi transformado em `PASS`;
- artifact do benchmark final: ID `9737276483`, ZIP SHA-256 `1d1f1aea048a0a59a8fcd9a1a45fd84739f1a1b1efb151401531e2edcb5f9acd`;
- PR sem review threads pendentes;
- `main` não havia avançado além da base durante a validação final;
- issue #118 fechou como `completed` após o merge.

## Decisões atuais

- `EMAIL_EACH_NEW_MATCH_DEFAULT = OFF`;
- `EMAIL_EACH_NEW_MATCH_SCOPE = PER_SAVED_SEARCH`;
- `EXISTING_ALERT_ENABLED_AS_EMAIL_CONSENT = REJECTED`;
- `FIRST_EMAIL_CADENCE = EXPLICIT_PER_MATCH_SELECTION`;
- `RECIPIENT_AUTHORITY = CURRENT_ACTIVE_CONFIRMED_IDENTITY_EMAIL`;
- `RECIPIENT_ADDRESS_STORED_IN_MARKETPLACE = NO`;
- `DURABLE_DELIVERY_INTENT = EXISTS`;
- `PROVIDER_NEUTRAL_RECOVERY = PROVED_BOUNDED`;
- `AUTOMATIC_EMAIL_DELIVERY_RUNNER = IMPLEMENTED_AND_GREEN`;
- `FIRST_SANDBOX_PROBE = RESEND`;
- `PROVIDER_ACCEPTED_EQUALS_DELIVERED = NO`;
- `RESEND_WEBHOOK_AUTHENTICITY = IMPLEMENTED`;
- `RESEND_WEBHOOK_REPLAY = DURABLE_ATOMIC_LEDGER`;
- `OPEN_CLICK_TRACKING = NOT_AUTHORIZED`;
- `PRODUCTION_PROVIDER_ACTIVATION = EXTERNAL_DEPLOYMENT_ACTION`;
- `POSTGRES_TRANSACTIONAL_CLAIM_PRIMITIVE = PROVED_BOUNDED` (#117);
- `AUTOMATIC_SAVED_SEARCH_DETECTION_RUNNER = IMPLEMENTED_AND_GREEN` (#117).

## Remaining blockers / next valid triggers

- #113 Recommendations: bloqueado até existir autoridade de avaliação válida — qrels humanos para uma pergunta explícita ou dataset comportamental exposure-aware. Favorite/Lead atuais não criam negativos de relevância.
- #114 Market intelligence: external provider identifier projection já está entregue; resta definir a quantidade de produto e obter source/provider com licença, metodologia, coverage e direitos de uso verificáveis.
- #115 Trust/history/inspection: bloqueado em provider/authorization, Listing-instance identity, purpose/privacy/retention e assertion semantics verificáveis.
- #116 True radius: baseline de município IBGE está entregue; raio físico continua bloqueado em autoridade do ponto da Listing, provenance/precision/lifecycle e privacy/minimization.
- Advanced Discovery: benchmark atual mede gaps de presentation normalization e typo tolerance; próximo experimento válido deve alterar uma variável por vez e comparar contra o corpus/qrels congelado, incluindo false positives e planner/latency. Nenhuma tecnologia avançada está selecionada.
- Comparator/enrichment quantitativo: consumer/comparability boundary #122 foi provado, mas promoção de ficha técnica/Comparator continua condicionada a cobertura Brasil/produção suficiente e ao produto concreto.
- Resend produção: credenciais, sender/domain, safe recipient, DPA/legal/commercial approval e operação de produção são ações externas de deployment; não reabrem #118 por si só.

## Source of runtime truth

- Estado de branch/PR/checks: Git e GitHub Actions do commit corrente.
- Produto: [`../PRODUCT.md`](../PRODUCT.md).
- Fatos derivados: [`../generated/repository-facts.md`](../generated/repository-facts.md).
- Decisões: [`../MDV.md`](../MDV.md) e [`../adr/`](../adr/).
- Cobertura funcional: [`../audits/2026-08-27-unified-functional-coverage-matrix.md`](../audits/2026-08-27-unified-functional-coverage-matrix.md).
- Advanced Discovery: [`../audits/2026-08-29-advanced-discovery-baseline.md`](../audits/2026-08-29-advanced-discovery-baseline.md).
- Podium quantitative consumer: [`../audits/2026-08-29-podium-quantitative-consumer-benchmark.md`](../audits/2026-08-29-podium-quantitative-consumer-benchmark.md).
- Saved Search claim: [`../audits/2026-08-29-saved-search-postgres-claim-baseline.md`](../audits/2026-08-29-saved-search-postgres-claim-baseline.md).
- Município IBGE: [`../audits/2026-08-29-ibge-municipality-identity-baseline.md`](../audits/2026-08-29-ibge-municipality-identity-baseline.md).
- Saved Search email delivery: [`../audits/2026-08-29-saved-search-email-delivery-contract-baseline.md`](../audits/2026-08-29-saved-search-email-delivery-contract-baseline.md).

## Update rule

Atualize este snapshot somente quando mudar outcome, plano, acceptance target ou blocker real.

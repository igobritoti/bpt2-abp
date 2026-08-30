# Saved Search external email delivery contract baseline

Date: 2026-08-29
Authority issue: #118
Draft PR: #136

## Question

Can BPT2 establish a durable, provider-neutral recovery boundary for future Saved Search email delivery before selecting a real provider, cadence, retry policy or product consent surface?

## Evidence level

- **A** — repository code and CI executed against PostgreSQL 17 after the BPT2 Fresh Migration Gate;
- **B** — reproduced fake-provider behavior in the retained benchmark artifact;
- **C** — architectural conclusions limited to what the executed A/B evidence supports;
- no production-provider quality, commercial choice or email deliverability claim is made.

## Existing authority boundary

The source event is the existing durable `SavedSearchAlertMatch`, which is already unique by `(SavedSearchId, ListingId)`. ADR-0003 requires durable application state before an external side effect.

The new bounded contract introduces `SavedSearchAlertDeliveryIntent` after that match. A logical intent carries:

- `SavedSearchAlertMatchId`;
- `UserId`;
- normalized `Channel`;
- a stable `IdempotencyKey`;
- durable delivery status;
- creation / last-attempt timestamps.

It deliberately does **not** persist a recipient email address in Marketplace. Recipient email, verification and channel authorization must be resolved/revalidated at dispatch time from their current authorities.

`SavedSearch.AlertEnabled` remains monitoring intent only. It is not treated as external-email product consent.

## Persistence invariants

The ephemeral Fresh Migration Gate generated/applied the schema successfully. The delivery table has:

- unique `(SavedSearchAlertMatchId, Channel)` logical-intent key;
- unique `IdempotencyKey`;
- indexed `(Status, CreatedAtUtc)` recovery surface;
- provider-neutral statuses: `Pending`, `OutcomeUnknown`, `Accepted`, `Delivered`, `PermanentFailed`, `Suppressed`.

No tracked Gate migration is introduced; the repository's existing ephemeral migration authority remains unchanged.

## Executed benchmark

Green run: `33285470611`

Artifact:

- ID: `9724291877`;
- archive size: `951` bytes;
- archive SHA-256: `026c6a87251492c90c315206887890655d38f7ae511f23ce6eb8f47364be4b7b`.

Observed output:

- executable scenario records: `11`;
- fake-provider calls: `9`;
- logical provider acceptances after idempotency deduplication: `4`;
- Fresh Migration Gate: passed;
- benchmark result: passed.

The 11 recorded scenarios cover 12 acceptance conditions because first creation plus exact source-event replay are asserted together in one scenario.

## Acceptance conditions proved in the bounded fake-provider model

1. Unconfirmed email does not create/send an external delivery intent.
2. Confirmed email without explicit external-email product authorization does not create/send.
3. An eligible source event creates one durable logical intent.
4. Exact source-event replay converges to that same intent.
5. A crash after durable intent creation but before provider call can later dispatch once.
6. A provider timeout with unknown outcome remains `OutcomeUnknown`; it is not mislabeled delivered/failed.
7. Provider acceptance followed by process crash can retry with the same idempotency key and converge without a second logical acceptance when the provider honors that key.
8. Opt-out before the provider call suppresses the pending intent without making the call.
9. A recipient-address change before dispatch uses the current address and does not use the stale address from intent creation.
10. Permanent rejection and transient failure remain distinct; transient failure remains recoverable.
11. Replaying a delivered callback is state-idempotent in the provider-neutral state model.
12. Failure of one intent does not block independent delivery progress.

The benchmark also reflection-checks that the production durable intent model exposes no email-address property.

## Failure investigation retained

Two failed iterations were useful harness findings, not product failures:

1. Direct `AbpDbContext.SaveChangesAsync` outside the ABP dependency container caused a null internal service. The fixture was aligned with the existing claim benchmark and uses EF for the real model/read surface plus SQL writes against the Fresh-Migration-produced tables.
2. A timestamp read back with `DateTimeKind.Unspecified` was rejected by Npgsql for `timestamp with time zone`. The fixture now explicitly restores the already-defined UTC semantic before writing it back.

Both corrections preserved the domain/schema contract and the Fresh Migration Gate remained green.

## Decisions supported by this benchmark

- `DURABLE_EMAIL_DELIVERY_INTENT = PROVED_BOUNDED`
- `SOURCE_EVENT_CHANNEL_UNIQUENESS = PROVED_BOUNDED`
- `RECIPIENT_ADDRESS_STORED_IN_MARKETPLACE = NO`
- `DISPATCH_TIME_RECIPIENT_REVALIDATION = PROVED_BOUNDED`
- `MONITORING_OPT_IN_AS_EXTERNAL_EMAIL_CONSENT = REJECTED`
- `OUTCOME_UNKNOWN_AS_EXPLICIT_STATE = PROVED_BOUNDED`
- `PROVIDER_NEUTRAL_IDEMPOTENCY_RECOVERY = PROVED_BOUNDED_WITH_FAKE_PROVIDER`
- `REAL_EMAIL_PROVIDER = NOT_SELECTED`
- `PRODUCTION_EMAIL_CONSENT_AUTHORITY = STILL_REQUIRED`
- `PRODUCTION_CADENCE = UNSET`
- `REAL_EMAIL_SENDING = NOT_AUTHORIZED_BY_THIS BENCHMARK`

## What this does not prove

This benchmark does not establish:

- a production opt-in UI/data owner or revocation lifecycle;
- Resend, SES or any other provider as the production choice;
- real-provider idempotency beyond provider-specific future tests;
- real delivery, bounce, complaint or suppression performance;
- webhook signature verification or provider event identifiers;
- retry/backoff/cadence thresholds;
- production worker/deployment topology;
- open/click tracking, which remains outside the first contract.

A real-provider sandbox experiment must preserve the durable-intent and dispatch-time recipient-authority semantics proved here rather than bypass them.

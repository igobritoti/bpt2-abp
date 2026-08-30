# Saved Search external email delivery contract baseline

Date: 2026-08-29
Authority issue: #118
Original provider-neutral baseline PR: #136 / merged follow-up evidence in #137
Current implementation PR: #145

## Status of this audit

This document began as the provider-neutral delivery-intent baseline before a concrete external-email authorization and provider probe were selected. That historical evidence remains useful, but several original `STILL_REQUIRED` / `UNSET` dispositions are now superseded by the executable #118 slice.

Current repository contract on PR #145:

- first external channel: email;
- recipient authority: current active + confirmed Identity email resolved at dispatch time;
- product authorization: explicit per-Saved-Search `EMAIL_EACH_NEW_MATCH`, default OFF and independent from `AlertEnabled`;
- cadence: one email for each newly detected durable Saved Search match when the explicit authorization is valid;
- provider-neutral durable dispatch: claim/lease/retry runner with PostgreSQL coordination and no provider call inside Buyer/Seller HTTP requests;
- first bounded provider adapter/probe: Resend;
- provider acceptance is distinct from delivery confirmation;
- Resend/Svix webhook authenticity is verified before provider events are accepted;
- provider-event replay is protected by a durable unique ledger and atomic PostgreSQL `ON CONFLICT DO NOTHING` claim;
- Marketplace does not persist recipient email plaintext;
- open/click tracking is outside the authorized contract and opened/clicked webhook events are not processed.

Production provider account activation, production secrets, commercial/DPA/legal review and a real-provider credentialed probe remain external deployment/evidence actions. They are not represented as executed evidence when credentials are absent.

## Question of the original baseline

Can BPT2 establish a durable, provider-neutral recovery boundary for future Saved Search email delivery before selecting a real provider, cadence, retry policy or product consent surface?

The original benchmark answered that bounded question positively. The current #118 implementation then selected the minimum explicit product authorization and a bounded Resend adapter/probe without discarding that provider-neutral durability boundary.

## Evidence level

- **A** — repository code and CI executed against PostgreSQL 17 after the BPT2 Fresh Migration Gate;
- **B** — reproduced fake-provider behavior in the retained benchmark artifact;
- **C** — architectural conclusions limited to what executed A/B evidence supports;
- conditional real-provider evidence remains conditional: when Resend credentials are absent, the bounded probe must report SKIP rather than fabricated PASS.

## Durable authority boundary

The source event is the existing durable `SavedSearchAlertMatch`, unique by `(SavedSearchId, ListingId)`. ADR-0003 requires durable application state before an external side effect.

`SavedSearchAlertDeliveryIntent` is created after that match and carries:

- `SavedSearchAlertMatchId`;
- `UserId`;
- normalized `Channel`;
- stable `IdempotencyKey`;
- provider-neutral delivery status;
- creation/attempt/retry/lease timestamps;
- a recipient fingerprint used to preserve exact same-key/same-payload retry semantics without storing the recipient address;
- provider message id after provider acceptance.

It deliberately does **not** persist a recipient email address in Marketplace. Recipient email and verification are resolved from current Identity state at dispatch time.

`SavedSearch.AlertEnabled` remains monitoring intent only. It is not external-email product consent.

The explicit external-email authorization is the independent per-search `EmailEachNewMatchEnabled` state, with its authorization timestamp. Disabling that authorization suppresses still-undispatched intents.

## Persistence and dispatch invariants

Fresh Migration coverage has generated/applied the current schema successfully in CI on earlier #118 heads, and the current head retains the same migration authority.

The delivery boundary includes:

- unique `(SavedSearchAlertMatchId, Channel)` logical-intent key;
- unique `IdempotencyKey`;
- provider-neutral statuses `Pending`, `InFlight`, `RetryScheduled`, `OutcomeUnknown`, `Accepted`, `Delivered`, `PermanentFailed`, `Suppressed`;
- due/stale claim selection coordinated with PostgreSQL `FOR UPDATE SKIP LOCKED`;
- leases so stale `InFlight` work is reclaimable;
- transient retry without an invented terminal retry-count threshold;
- no database transaction held across Identity resolution or provider network I/O;
- durable provider-event uniqueness by `(Provider, ProviderEventId)`;
- atomic provider-event insertion with `ON CONFLICT DO NOTHING` before applying an event transition.

No tracked Gate migration is introduced; the repository's existing ephemeral migration authority remains unchanged.

## Original executed provider-neutral benchmark

Historical green run: `33285470611`

Artifact:

- ID: `9724291877`;
- archive size: `951` bytes;
- archive SHA-256: `026c6a87251492c90c315206887890655d38f7ae511f23ce6eb8f47364be4b7b`.

Observed historical output:

- executable scenario records: `11`;
- fake-provider calls: `9`;
- logical provider acceptances after idempotency deduplication: `4`;
- Fresh Migration Gate: passed;
- benchmark result: passed.

The retained provider-neutral matrix covers:

1. Unconfirmed email does not create/send external delivery.
2. Confirmed email without explicit product authorization does not create/send.
3. Eligible source event creates one durable logical intent.
4. Exact source-event replay converges to that same intent.
5. Crash after durable intent creation but before provider call can recover.
6. Unknown provider outcome remains explicit.
7. Accepted-then-crash retry reuses the stable logical idempotency key.
8. Opt-out before provider call suppresses without the call.
9. Dispatch uses the current recipient rather than a stale copied address.
10. Permanent and transient failure remain distinct.
11. Provider callback replay is idempotent.
12. One failed intent does not block unrelated progress.

The benchmark also verifies that the durable Marketplace intent model does not expose an email-address property.

## Current #118 executable additions

The active #118 slice adds concrete engineering beyond the historical baseline:

### Explicit product authorization

- authorization is per Saved Search;
- default is OFF;
- `AlertEnabled` is not overloaded;
- Buyer enable/disable operations are explicit;
- UI wording states the cadence: one email for each newly detected offer;
- intent creation is gated by monitoring plus the explicit authorization and its effective timestamp;
- opt-out, monitoring disable, deletion and current ineligibility suppress future undispatched work.

### Recipient revalidation

The dispatch resolver requires a current Identity user that exists, is active, has a confirmed email, and has a nonblank current email address. Marketplace receives the address only transiently for the provider call and stores a SHA-256 recipient fingerprint rather than the plaintext address.

### Automatic provider-neutral runner

The delivery processor claims due work through PostgreSQL, releases the transaction before external work, revalidates eligibility, resolves the current recipient, binds the recipient fingerprint and then performs the provider call. Unexpected/ambiguous outcomes stay recoverable; transient failures schedule retry; no arbitrary terminal retry-count threshold is introduced.

### Resend adapter and bounded probe

Resend is selected as the **first bounded sandbox probe**, not as an irreversible commercial commitment.

The adapter:

- uses the BPT2 logical intent key as `Idempotency-Key`;
- maps accepted/transient/permanent/unknown outcomes without treating acceptance as delivery;
- requires a provider message id for a clean `Accepted` transition;
- sends no open/click tracking fields;
- is configuration/secret driven.

The retained real-provider probe is executable only when the required credential, sender, safe recipient and public-web base URL are supplied. It sends one fixed logical message, retries the exact same message with the exact same idempotency key, and requires the same provider message id. When configuration is missing, it reports SKIP rather than replacing real-provider evidence with a fake assertion.

### Resend/Svix webhook boundary

The webhook path:

- reads the raw body;
- requires configured webhook secret and fails closed when absent;
- verifies `svix-id`, `svix-timestamp`, `svix-signature` with the `whsec_` secret using HMAC-SHA256 and bounded timestamp tolerance;
- rejects malformed/tampered/stale signatures;
- processes delivery/failure-class events only after verification;
- ignores opened/clicked events;
- stores a provider event ledger without recipient email;
- uses `(Provider, ProviderEventId)` uniqueness plus atomic `ON CONFLICT DO NOTHING` to make replay/concurrent duplicate processing converge.

## Failure investigations retained

Harness failures found during development are evidence about the fixture, not provider success:

1. Direct `AbpDbContext.SaveChangesAsync` from a manually constructed `MarketplaceDbContext` lacks the ABP runtime services supplied by DI. The benchmark therefore uses EF for the production model/read surface and direct PostgreSQL writes for fixture setup; the production webhook processor itself also uses an atomic SQL ledger boundary, eliminating a check-then-insert replay race.
2. A prior timestamp read back as `DateTimeKind.Unspecified` had to be restored to the already-defined UTC semantic before writing to PostgreSQL `timestamp with time zone`.
3. Generated repository facts must be refreshed when the retained test/project inventory changes; this is enforced by the Harness Gate.

None of these is evidence of a successful real Resend send.

## Current decisions

- `DURABLE_EMAIL_DELIVERY_INTENT = PROVED_BOUNDED`
- `SOURCE_EVENT_CHANNEL_UNIQUENESS = PROVED_BOUNDED`
- `RECIPIENT_ADDRESS_STORED_IN_MARKETPLACE = NO`
- `RECIPIENT_AUTHORITY = CURRENT_ACTIVE_CONFIRMED_IDENTITY_EMAIL`
- `DISPATCH_TIME_RECIPIENT_REVALIDATION = IMPLEMENTED`
- `MONITORING_OPT_IN_AS_EXTERNAL_EMAIL_CONSENT = REJECTED`
- `EMAIL_PRODUCT_AUTHORIZATION = EMAIL_EACH_NEW_MATCH_PER_SAVED_SEARCH`
- `EMAIL_CADENCE = EXPLICIT_ONE_EMAIL_PER_NEW_MATCH`
- `OUTCOME_UNKNOWN_AS_EXPLICIT_STATE = IMPLEMENTED`
- `AUTOMATIC_DURABLE_RETRY_RUNNER = IMPLEMENTED`
- `FIRST_BOUNDED_PROVIDER_PROBE = RESEND`
- `PROVIDER_ACCEPTED_EQUALS_DELIVERED = NO`
- `WEBHOOK_AUTHENTICITY = IMPLEMENTED_AND_BOUNDED_TESTED`
- `WEBHOOK_REPLAY = DURABLE_ATOMIC_LEDGER`
- `OPEN_CLICK_TRACKING = NOT_AUTHORIZED`
- `REAL_RESEND_SEND_EVIDENCE = CONDITIONAL_ON_EXTERNAL_CREDENTIALS`
- `PRODUCTION_PROVIDER_ACTIVATION = EXTERNAL_DEPLOYMENT_ACTION`

## What remains unproved without external credentials/production activation

This engineering slice does not claim:

- that a real Resend message was sent when CI credentials are absent;
- production inbox placement/deliverability;
- production bounce/complaint rates;
- provider-account approval or sender/domain verification;
- DPA/legal/commercial approval;
- production secret provisioning;
- production operational SLOs or arbitrary retry/dead-letter thresholds.

Those external or future operational claims must remain separate from the engineering contract proved here.
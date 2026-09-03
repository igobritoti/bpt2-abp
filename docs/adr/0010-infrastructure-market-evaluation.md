# ADR-0010: Evaluate mature infrastructure solutions before build or experiment

Status: Accepted

## Context

BPT2 deliberately postpones additional infrastructure until a concrete product or operational need exists. That rule avoids speculative complexity, but it is not sufficient by itself: once a need appears, the team could still jump directly into a custom spike and spend engineering effort rediscovering a capability already available in platform/framework features, maintained OSS projects, managed services or commercial products.

Infrastructure decisions also have long-lived operational consequences: security surface, failure modes, observability, upgrades, vendor or protocol lock-in, staffing burden, data portability and migration cost. Those consequences exist both when adopting a product and when building an internal solution.

This ADR establishes a selection principle. It does not select any specific storage, search, cache, broker, job system, lock provider or other infrastructure technology.

## Decision

For a **new infrastructure capability**, use the following sequence:

1. prove the need and constraints in BPT2;
2. **before a custom implementation or capability experiment**, identify existing options relevant to those constraints;
3. include, when applicable, platform/framework-native capability, maintained OSS/self-hosted options and managed/commercial services;
4. shortlist only options whose documented or measured properties satisfy the important constraints;
5. run the smallest appropriate empirical study where documentation and existing reproducible evidence do not resolve a material comparison;
6. document the final decision to **adopt** an existing solution or **build** a custom one before production adoption.

“Evaluate existing options first” is not “buy SaaS by default”. A native platform feature or OSS project may fit the bounded need, and a custom implementation remains valid when evidence shows that existing options materially fail required constraints. Claims that a custom or third-party option is simpler, safer, cheaper, faster, easier to maintain or otherwise superior are comparative empirical claims and must satisfy `ENGINEERING.md` and `QUALITY.md`.

## Required evaluation

The depth is proportional to the decision, but the record must identify the relevant criteria rather than rely on preference. Typical criteria include:

- functional fit and known constraints;
- maintenance status/model and evidence relevant to operational continuity;
- security/compliance implications supported by applicable documentation, tests or analysis;
- integration with current BPT2 boundaries;
- failure modes, recovery and observability;
- deployment and staffing burden when these are material and can be estimated or measured;
- total cost where material, with assumptions and horizon stated;
- lock-in, portability and data ownership;
- migration/exit path;
- performance/scale evidence when performance is actually part of the requirement.

Terms such as “mature”, “simple”, “safe”, “low-cost” or “maintainable” must not act as proxy metrics. If they influence selection, operationalize them into observable criteria appropriate to the decision or leave them explicitly as unverified hypotheses.

A benchmark is required only when the unresolved decision depends on benchmarkable behavior. Other empirical questions may require a different method. Vendor claims, adoption counts, repository stars or popularity alone are not proof of fitness or superiority for BPT2.

## Documentation rule

A material infrastructure adoption or custom build must leave a durable decision record before production use. The record must state at least:

- the need and constraints;
- alternatives considered;
- evidence supporting material comparative claims;
- why the selected option satisfies the decision criteria;
- ownership and architectural boundary;
- important operational consequences;
- reversibility or exit/migration strategy;
- limitations or unresolved uncertainty that materially affect confidence.

Use an ADR when the choice changes or constrains architecture. Execution plans may hold experiment history; `docs/MDV.md` holds the formal decision state. Do not bury a durable infrastructure decision only in a PR description or transient chat/history.

## Scope

This principle applies to shared/non-domain operational capabilities such as, for example, object storage, external search, caching, brokers/messaging, distributed locks, background-job infrastructure, observability platforms, CDN/edge capabilities and similar infrastructure additions.

It does not require a market survey for ordinary application code, domain logic, small local implementation details or use of infrastructure already fixed by an accepted ADR unless that decision is being reopened.

## Consequences

- BPT2 remains evidence-first without becoming build-first.
- Custom infrastructure is an explicit decision, not the default experiment.
- Existing solutions are evaluated before engineering cost is committed to reproducing them.
- Adoption and custom build are subject to the same requirement to operationalize comparative claims and record compatible evidence.
- Existing deferred decisions remain deferred. This ADR changes the process used when they are opened; it does not activate Redis, brokers, external search, object storage providers, distributed locks or background jobs by itself.

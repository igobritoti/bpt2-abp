# ADR-0010: Evaluate mature infrastructure solutions before build or experiment

Status: Accepted

## Context

BPT2 deliberately postpones additional infrastructure until a concrete product or operational need exists. That rule avoids speculative complexity, but it is not sufficient by itself: once a need appears, the team could still jump directly into a custom spike and spend engineering effort rediscovering a capability already solved by mature products, managed services, open-source projects or the current platform/framework.

Infrastructure decisions also have long-lived operational consequences: security surface, failure modes, observability, upgrades, vendor or protocol lock-in, staffing burden, data portability and migration cost. Those consequences exist both when adopting a product and when building an internal solution.

This ADR establishes a selection principle. It does not select any specific storage, search, cache, broker, job system, lock provider or other infrastructure technology.

## Decision

For a **new infrastructure capability**, use the following sequence:

1. prove the need and constraints in BPT2;
2. **before a custom implementation or capability experiment**, evaluate mature existing options relevant to those constraints;
3. include, when applicable, platform/framework-native capability, mature OSS/self-hosted options and managed/commercial services;
4. shortlist only options that fit the important constraints;
5. run the smallest experiment/benchmark needed only where documentation and existing evidence do not resolve the decision;
6. document the final decision to **adopt** an existing solution or **build** a custom one before production adoption.

“Evaluate mature market solutions first” is not “buy SaaS by default”. A native platform feature or mature OSS project may be the best option, and a custom implementation remains valid when evidence shows that existing options materially fail the required constraints or that the custom solution is demonstrably simpler and safer for the bounded need.

## Required evaluation

The depth is proportional to the decision, but the record must identify the relevant criteria rather than rely on preference. Typical criteria include:

- functional fit and known constraints;
- operational maturity and maintenance model;
- security/compliance implications;
- integration with current BPT2 boundaries;
- failure modes, recovery and observability;
- deployment and staffing burden;
- total cost where material;
- lock-in, portability and data ownership;
- migration/exit path;
- performance/scale evidence when performance is actually part of the requirement.

A benchmark is required only when the unresolved decision depends on measurable behavior. Vendor claims or popularity alone are not proof of fitness for BPT2.

## Documentation rule

A material infrastructure adoption or custom build must leave a durable decision record before production use. The record must state at least:

- the need and constraints;
- alternatives considered;
- why the selected option fits better;
- ownership and architectural boundary;
- important operational consequences;
- reversibility or exit/migration strategy.

Use an ADR when the choice changes or constrains architecture. Execution plans may hold experiment history; `docs/MDV.md` holds the formal decision state. Do not bury a durable infrastructure decision only in a PR description or transient chat/history.

## Scope

This principle applies to shared/non-domain operational capabilities such as, for example, object storage, external search, caching, brokers/messaging, distributed locks, background-job infrastructure, observability platforms, CDN/edge capabilities and similar infrastructure additions.

It does not require a market survey for ordinary application code, domain logic, small local implementation details or use of infrastructure already fixed by an accepted ADR unless that decision is being reopened.

## Consequences

- BPT2 remains evidence-first without becoming build-first.
- Custom infrastructure is an explicit decision, not the default experiment.
- Mature existing solutions are evaluated before engineering cost is committed to reproducing them.
- Adopting a vendor/product is also subject to architectural scrutiny; maturity does not waive documentation.
- Existing deferred decisions remain deferred. This ADR changes the process used when they are opened; it does not activate Redis, brokers, external search, object storage providers, distributed locks or background jobs by itself.

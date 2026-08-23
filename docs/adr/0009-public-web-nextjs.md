# ADR-0009: First public web implementation uses Next.js 16

Status: Accepted

## Context

ADR-0004 already fixes the structural boundary: the public marketplace UX/SEO is an independent client of the ABP application API. The repository has no public frontend to preserve, while the product requires a real public listing/detail/contact consumer and SEO-capable pages.

The first consumer therefore needs a web framework that can render public pages on the server, generate page metadata, remain independently deployable/self-hostable and consume the existing HTTP API without leaking its technology into the backend modules.

## Decision

Use **Next.js 16 Active LTS with App Router** for the first BPT2 public-web implementation.

Constraints:

- public web remains a separate project from the ABP host;
- backend integration is HTTP/API only;
- React/Next code and types must not enter Catalog, Sellers, Marketplace, Media or Ingestion assemblies;
- the backend must not introduce framework-specific DTOs for Next.js;
- pin a supported patched Next.js 16 release and update within the supported line when security releases require it.

## Evidence and rationale

Verified on 2026-08-23 against current official documentation:

- ABP's current modern UI direction supports React/No-UI while the existing ADR keeps the BPT public client independent from the ABP host;
- Next.js 16 is the Active LTS major according to the official support policy;
- App Router supports server-rendered applications and dynamic metadata;
- Next.js provides first-class metadata, `robots` and `sitemap` conventions needed for public/SEO evolution;
- Next.js supports self-hosting, preserving deployment independence.

This evidence establishes fitness for the first implementation. It does **not** prove that Next.js is uniquely superior to every alternative.

## Consequences

- The public buyer flow can evolve independently from the ABP administrative/runtime UI.
- Replacing the public framework remains possible because the durable boundary is the HTTP API.
- Nuxt or other SSR-capable frameworks are not classified as incapable; they are simply not selected for this implementation.
- Framework security advisories affect the public-web package pin, not domain architecture.

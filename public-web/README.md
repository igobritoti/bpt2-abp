# BPT2 Public Web

Independent marketplace client for the BPT2 HTTP API. Public buyer pages stay server-rendered; the Seller area lives under `/vender` and authenticates directly against the BPT2 Auth Server as a public OIDC client.

## Baseline

- Next.js 16 Active LTS / App Router
- React 19
- TypeScript
- ESLint
- `oidc-client-ts` for Seller Authorization Code + PKCE

The public web must not reference backend .NET projects or internal assemblies. Its durable integration boundary is the public HTTP API.

## Runtime configuration

- `BPT_API_BASE_URL`: server-side base URL used by Next.js to call the BPT2 API.
- `NEXT_PUBLIC_BPT_API_BASE_URL`: browser-reachable API base URL used for public Listing photos and as Seller API fallback.
- `NEXT_PUBLIC_BPT_AUTHORITY`: browser-reachable BPT2 Auth Server authority. Defaults to `NEXT_PUBLIC_BPT_API_BASE_URL` and then `http://127.0.0.1:5093`.
- `NEXT_PUBLIC_BPT_SELLER_CLIENT_ID`: Seller public OIDC client id. Defaults to `BomPraTi_SellerWeb`.

The canonical local shell flow runs the backend at `http://127.0.0.1:5093`. For a complete clone-to-running-stack procedure, use [`../docs/LOCAL-DEVELOPMENT.md`](../docs/LOCAL-DEVELOPMENT.md).

Example:

```bash
export BPT_API_BASE_URL='http://127.0.0.1:5093'
export NEXT_PUBLIC_BPT_API_BASE_URL='http://127.0.0.1:5093'
export NEXT_PUBLIC_BPT_AUTHORITY='http://127.0.0.1:5093'
export NEXT_PUBLIC_BPT_SELLER_CLIENT_ID='BomPraTi_SellerWeb'
npm run dev
```

Seller login starts at `http://localhost:3000/vender`. The browser is redirected to the ABP Account/Auth Server for credential entry and returns through `/auth/callback`. Logout uses the OpenIddict end-session endpoint and `/auth/logout-callback`. The Seller Web client is public, allows only Authorization Code, and requires PKCE; it does not receive the Seller password and is not allowed to use the password grant.

## Commands

```bash
npm install --no-audit --no-fund
npm run lint
npm run typecheck
npm run build
npm run dev
```

`BPT2 Public Web Gate` executes dependency install, lint, typecheck and production build in GitHub Actions. `BPT2 Seller Auth PKCE Gate` exercises a real Auth Server with a fresh PostgreSQL database and proves discovery/S256, interactive Account login redirection, authorization-code exchange with PKCE, bearer access to a Seller API, PKCE enforcement and password-grant rejection for the Seller client. The end-to-end buyer gate separately proves Draft invisibility, Publish, list, detail, photo and WhatsApp CTA over HTTP.

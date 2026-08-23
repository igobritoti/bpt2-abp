# BPT2 Public Web

Independent marketplace client for the BPT2 HTTP API. Public buyer pages remain anonymous; Seller routes under `/vender` use the same deployable client but an isolated OpenID Connect session.

## Baseline

- Next.js 16 Active LTS / App Router
- React 19
- TypeScript
- ESLint

The web client must not reference backend .NET projects or internal assemblies. Its durable integration boundary is the HTTP API/Auth Server.

## Runtime configuration

- `BPT_API_BASE_URL`: server-side base URL used by Next.js to call the BPT2 API.
- `NEXT_PUBLIC_BPT_API_BASE_URL`: browser-reachable API base URL used for public Listing photo URLs.
- `NEXT_PUBLIC_BPT_AUTHORITY`: browser-reachable OpenIddict authority for Seller login.
- `NEXT_PUBLIC_BPT_SELLER_CLIENT_ID`: Seller browser client ID; defaults to `BomPraTi_SellerWeb`.

The canonical local shell flow runs the backend at `http://127.0.0.1:5093`. For a complete clone-to-running-stack procedure, use [`../docs/LOCAL-DEVELOPMENT.md`](../docs/LOCAL-DEVELOPMENT.md).

Example:

```bash
export BPT_API_BASE_URL='http://127.0.0.1:5093'
export NEXT_PUBLIC_BPT_API_BASE_URL='http://127.0.0.1:5093'
export NEXT_PUBLIC_BPT_AUTHORITY='http://127.0.0.1:5093'
export NEXT_PUBLIC_BPT_SELLER_CLIENT_ID='BomPraTi_SellerWeb'
npm run dev
```

Seller login uses Authorization Code + PKCE and delegates credentials to the ABP/OpenIddict Auth Server. The password grant used by HTTP fixtures is not a product login mechanism.

## Commands

```bash
npm install --no-audit --no-fund
npm run lint
npm run typecheck
npm run build
npm run dev
```

`BPT2 Public Web Gate` executes dependency install, lint, typecheck and production build in GitHub Actions. The Buyer HTTP gate proves the anonymous buyer flow; the Seller Auth HTTP gate proves the OpenIddict/PKCE boundary used by `/vender`.

# BPT2 Public Web

Independent public marketplace client for the BPT2 HTTP API.

## Baseline

- Next.js 16 Active LTS / App Router
- React 19
- TypeScript
- ESLint

The public web must not reference backend .NET projects or internal assemblies. Its durable integration boundary is the public HTTP API.

## Runtime configuration

- `BPT_API_BASE_URL`: server-side base URL used by Next.js to call the BPT2 API.
- `NEXT_PUBLIC_BPT_API_BASE_URL`: browser-reachable API base URL used for public Listing photo URLs.

The canonical local shell flow runs the backend at `http://127.0.0.1:5093`. For a complete clone-to-running-stack procedure, use [`../docs/LOCAL-DEVELOPMENT.md`](../docs/LOCAL-DEVELOPMENT.md).

Example:

```bash
export BPT_API_BASE_URL='http://127.0.0.1:5093'
export NEXT_PUBLIC_BPT_API_BASE_URL='http://127.0.0.1:5093'
npm run dev
```

## Commands

```bash
npm install --no-audit --no-fund
npm run lint
npm run typecheck
npm run build
npm run dev
```

`BPT2 Public Web Gate` executes dependency install, lint, typecheck and production build in GitHub Actions. The end-to-end buyer gate additionally starts the real ABP host and the built Next.js app and proves Draft invisibility, Publish, list, detail, photo and WhatsApp CTA over HTTP.

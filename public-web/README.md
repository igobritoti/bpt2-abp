# BPT2 Public Web

Independent public marketplace client for the BPT2 HTTP API.

## Baseline

- Next.js 16 Active LTS / App Router
- React 19
- TypeScript
- ESLint

The public web must not reference backend .NET projects or internal assemblies. Its durable integration boundary is the public HTTP API.

## Commands

```bash
npm install
npm run lint
npm run typecheck
npm run build
npm run dev
```

`BPT2 Public Web Gate` executes lint, typecheck and production build in GitHub Actions for public-web changes.

Runtime API configuration is introduced only when the first API-consuming page lands.

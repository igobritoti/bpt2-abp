# Execution Plan 0024 — Public Seller Hub Sitemap

Status: **COMPLETO**

## Objetivo

Fechar a descoberta por sitemap do Seller Hub público já entregue nos Plans 0022–0023:

`Listing público → seller projetado → sitemap.xml → /vendedores/{sellerId}`

## Evidência que abriu o slice

- O sitemap já percorria todos os Listings públicos e emitia home + detalhes de Listing.
- Cada `PublicListingDto` já projetava `seller.sellerId`; não foi necessário endpoint, query ou contrato novo.
- O Seller Hub existe somente enquanto o Seller possui pelo menos um Listing público; essa regra já havia sido provada no Plan 0022.
- O Plan 0023 tornou o Hub socialmente compartilhável, mas deixou sitemap explicitamente fora de escopo.
- Metadata social da home seria acabamento sobre metadata global existente; sort/ranking exigiria semântica nova. O sitemap do Seller Hub era o menor gap com autoridade e comportamento já definidos.

## Escopo entregue

- `public-web/app/sitemap.ts` reutiliza a varredura paginada pública existente;
- `sellerId` dos Listings públicos é acumulado em `Set`, produzindo uma URL `/vendedores/{sellerId}` por Seller com oferta pública;
- home e URLs de Listings existentes permanecem no sitemap;
- `scripts/public-seo-http-smoke.sh` prova Draft excluído, Publish incluído, deduplicação com dois Listings do mesmo Seller, permanência após pausar apenas uma oferta e remoção depois de pausar a última;
- o sitemap continua dinâmico e derivado exclusivamente da API pública.

## Fora de escopo preservado

- sitemap completo do Catalog/Vehicle Hub;
- Seller sem Listing público;
- slug semântico;
- cache/revalidation específica de sitemap;
- prioridades/frequências baseadas em ranking;
- landing pages locais;
- JSON-LD;
- novo backend, contrato, schema, migration ou endpoint.

## Critérios de aceite

1. [x] home e Listing público continuam no sitemap como antes.
2. [x] Seller Hub aparece uma única vez quando há pelo menos um Listing público do Seller.
3. [x] Draft não cria URL de Seller no sitemap.
4. [x] Pause da última oferta pública remove a URL do Seller.
5. [x] deduplicação foi provada com dois Listings públicos do mesmo Seller.
6. [x] nenhum backend/domain/schema/migration/contrato novo foi introduzido.
7. [x] gate focal e 9 workflows aplicáveis passaram no head funcional; o merge fica condicionado a CI fresco no head documental final.

## Evidência executada

Head funcional: `51902a3147075fc7707adca12a638714a714ddcb`.

Public Buyer HTTP Gate:

- run `32771717430`;
- job `97573330921`;
- conclusão: `success`.

Marcadores focais observados no log:

- `PUBLIC_SEO_DRAFT_EXCLUDED: PASS`
- `PUBLIC_SEO_SELLER_HUB_DRAFT_EXCLUDED: PASS`
- `PUBLIC_SEO_PUBLISHED_IN_SITEMAP: PASS`
- `PUBLIC_SEO_SELLER_HUB_IN_SITEMAP: PASS`
- `PUBLIC_SEO_SELLER_HUB_DEDUPED: PASS`
- `PUBLIC_SEO_CANONICAL: PASS`
- `PUBLIC_SEO_SELLER_HUB_PERSISTS_WITH_OFFER: PASS`
- `PUBLIC_SEO_PAUSED_EXCLUDED: PASS`
- `PUBLIC_SEO_SELLER_HUB_LAST_OFFER_REMOVED: PASS`
- `PUBLIC SEO HTTP: PASSED`

O mesmo job também manteve verdes Public Buyer, Seller Hub, Vehicle Hub e authenticated Lead forwarding. Build .NET observado no gate: `0 Warning(s)`, `0 Error(s)`.

No head funcional, os 9 workflows aplicáveis concluíram `success`:

- BPT2 Harness Gate
- BPT2 Public Web Gate
- BPT2 Public Buyer HTTP Gate
- BPT2 Public Discovery HTTP Gate
- BPT2 Buyer Favorites HTTP Gate
- BPT2 Seller Auth HTTP Gate
- BPT2 Seller Draft Edit HTTP Gate
- BPT2 Seller Shell HTTP Gate
- BPT2 Seller Photos Publish HTTP Gate

Classe de evidência: **B** — comportamento reproduzido em CI sobre banco fresco, host real e Next real.

## Decision log

- **DECIDIDO:** a autoridade para incluir Seller Hub no sitemap é a mesma visibilidade pública dos Listings; Seller sem oferta pública não recebe URL no sitemap.
- **DECIDIDO:** múltiplos Listings públicos do mesmo Seller geram uma única URL de Hub.
- **DECIDIDO:** não foi criado endpoint ou projeção dedicada para sitemap; a implementação reaproveita a paginação pública já existente.
- **NÃO DECIDIDO:** sitemap de todo o Catalog/Vehicle Hub, slugs, cache/revalidation, prioridades SEO baseadas em negócio, landing pages e ranking.

## Progress log

- 2026-08-24: `main` remoto confirmado em `7ce722d228de42a6be30c5e3d8374c300706ca3b`, merge do Plan 0023, sem plan ativo ou blocker.
- 2026-08-24: auditoria comparou Seller Hub sitemap, metadata social da home e sort/ranking; Seller Hub sitemap selecionado como menor gap com regra e dados já provados.
- 2026-08-24: branch `feat/public-seller-hub-sitemap` criada e draft PR #43 aberto antes do código.
- 2026-08-24: sitemap passou a deduplicar `sellerId`; smoke SEO foi ampliado com dois Listings do mesmo Seller e lifecycle completo da URL do Hub.
- 2026-08-24: head funcional `51902a3147075fc7707adca12a638714a714ddcb` fechou 9/9 workflows aplicáveis em `success` e o gate focal registrou todos os marcadores novos como PASS.

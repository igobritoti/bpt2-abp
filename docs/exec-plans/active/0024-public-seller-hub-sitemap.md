# Execution Plan 0024 — Public Seller Hub Sitemap

Status: **ATIVO**

## Objetivo

Fechar a descoberta por sitemap do Seller Hub público já entregue nos Plans 0022–0023:

`Listing público → seller projetado → sitemap.xml → /vendedores/{sellerId}`

## Evidência que abriu o slice

- O sitemap atual já percorre todos os Listings públicos e emite home + detalhes de Listing.
- Cada `PublicListingDto` já projeta `seller.sellerId`; não é necessário endpoint, query ou contrato novo.
- O Seller Hub existe somente enquanto o Seller possui pelo menos um Listing público; essa regra foi provada no Plan 0022.
- O Plan 0023 tornou o Hub socialmente compartilhável, mas deixou sitemap explicitamente fora de escopo.
- Metadata social da home seria apenas acabamento sobre metadata global já existente; sort/ranking exigiria semântica de produto nova. O sitemap do Seller Hub é o menor gap com autoridade e comportamento já definidos.

## Escopo

- reutilizar a varredura paginada já existente em `public-web/app/sitemap.ts`;
- deduplicar `sellerId` entre Listings públicos;
- emitir uma entrada `/vendedores/{sellerId}` por Seller atualmente com oferta pública;
- preservar home e URLs de Listings já emitidas;
- ampliar o smoke SEO existente para provar Draft excluído, Publish incluído e Pause da última oferta removendo a URL do Seller;
- manter o sitemap dinâmico e derivado exclusivamente da API pública.

## Fora de escopo

- sitemap completo do Catalog/Vehicle Hub;
- Seller sem Listing público;
- slug semântico;
- cache/revalidation específica de sitemap;
- prioridades/frequências baseadas em ranking;
- landing pages locais;
- JSON-LD;
- novo backend, contrato, schema, migration ou endpoint.

## Critérios de aceite

1. [ ] home e Listing público continuam no sitemap como hoje.
2. [ ] Seller Hub aparece uma única vez quando há pelo menos um Listing público do Seller.
3. [ ] Draft não cria URL de Seller no sitemap.
4. [ ] Pause da última oferta pública remove a URL do Seller.
5. [ ] deduplicação funciona sem depender da quantidade de Listings públicos do Seller.
6. [ ] nenhum backend/domain/schema/migration/contrato novo é introduzido.
7. [ ] gate focal e workflows aplicáveis passam no head funcional e novamente no head documental final.

## Decision log

- **DECIDIDO para este slice:** a autoridade para incluir Seller Hub no sitemap é a mesma visibilidade pública dos Listings; Seller sem oferta pública não recebe URL no sitemap.
- **DECIDIDO para este slice:** múltiplos Listings públicos do mesmo Seller geram uma única URL de Hub.
- **NÃO DECIDIDO:** sitemap de todo o Catalog/Vehicle Hub, slugs, cache/revalidation, prioridades SEO baseadas em negócio, landing pages e ranking.

## Progress log

- 2026-08-24: `main` remoto confirmado em `7ce722d228de42a6be30c5e3d8374c300706ca3b`, merge do Plan 0023, sem plan ativo ou blocker.
- 2026-08-24: auditoria comparou Seller Hub sitemap, metadata social da home e sort/ranking; Seller Hub sitemap selecionado como menor gap com regra e dados já provados.
- 2026-08-24: branch `feat/public-seller-hub-sitemap` criada a partir do `main` verificado.

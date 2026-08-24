# Execution Plan 0016 — Public Listing Share Metadata

Status: **COMPLETO**

## Objetivo

Fechar a primeira fatia explícita de metadata de compartilhamento para o detalhe público do Listing:

`Listing publicado → metadata social SSR → link compartilhado com título/descrição/foto`

## Evidência que abriu o slice

- `PRODUCT.md` mantinha SEO como capacidade central e Open Graph/Twitter como decisão aberta.
- o detalhe público já possuía `generateMetadata`, title, description, canonical e robots.
- `PublicListing` já expunha título, preço, localização, identidade do Vehicle e fotos públicas.
- `publicPhotoUrl` já produzia a URL pública absoluta da foto.
- a busca no repo não encontrou implementação de Open Graph/Twitter, nem implementação parcial equivalente de Promoções, Admin UI ou Buyer Alerts.

## Escopo entregue

- Open Graph no detalhe público do Listing existente;
- Twitter card equivalente;
- title/description/canonical sociais derivados exatamente da mesma projeção pública já usada pela metadata normal;
- primeira foto pública reutilizada como `og:image` e `twitter:image` quando existe;
- `summary_large_image` quando existe foto e `summary` quando não existe;
- nenhum placeholder ou asset social paralelo inventado;
- Draft/Pause/Archive permanecem sem detalhe público e sem URL social indexável;
- prova adicionada ao Public Buyer HTTP flow já existente, sem novo workflow.

## Fora de escopo

- JSON-LD/schema.org;
- metadata social do Vehicle Hub, home ou páginas agregadas;
- geração/redimensionamento dedicado de imagem social;
- upload de thumbnail social;
- analytics/Search Console;
- landing pages, keywords/conteúdo e ranking;
- Promoções, Admin UI, Buyer Alerts;
- backend, migration, cache ou infraestrutura nova.

## Critérios de aceite

1. [x] Listing publicado retorna `og:title`, `og:description` e `og:url` coerentes com title/description/canonical atuais.
2. [x] Listing publicado retorna Twitter card coerente.
3. [x] Listing com foto pública usa a primeira foto como imagem social absoluta.
4. [x] metadata social não inventa campos de domínio nem copia regra de visibilidade.
5. [x] Listing Draft/Paused/Archive continua não acessível publicamente e não ganha superfície social indexável.
6. [x] build e nove workflows aplicáveis passaram no head funcional.
7. [x] docs fecham somente Listing share metadata; JSON-LD, Vehicle Hub metadata social e outras extensões permanecem abertas.

## Evidência executada

Head funcional comprovado: `1bd7d89fef5e4276a74b876bb6c0bdbabf97e98c`.

`BPT2 Public Buyer HTTP Gate`, run `32736992815`, job `97462071601`, usando PostgreSQL fresco, host ABP real e build/start de produção do Next.js:

- `FRESH MIGRATION GATE: PASSED`
- build Release: `0 Warning(s)` / `0 Error(s)`
- `PUBLIC_WEB_DRAFT_PRIVATE: PASS`
- `PUBLIC_WEB_DETAIL: PASS`
- `PUBLIC_WEB_METADATA: PASS`
- `PUBLIC_WEB_SHARE_METADATA: PASS`
- `PUBLIC_WEB_WHATSAPP_LEAD: PASS`
- `PUBLIC_WEB_PHOTO: PASS`
- `PUBLIC_LEAD_PAUSED_BLOCKED: PASS`
- `PUBLIC_WEB_SHARE_METADATA_PAUSED_PRIVATE: PASS`
- `PUBLIC_LEAD_ARCHIVED_BLOCKED: PASS`
- `PUBLIC BUYER HTTP FLOW: PASSED`

O mesmo run preservou verdes o Vehicle Hub, SEO público e authenticated Lead forwarding. No mesmo head, os nove workflows aplicáveis concluíram `success`: Harness, Public Web, Public Buyer, Public Discovery, Buyer Favorites, Seller Auth, Seller Draft/Edit, Seller Shell e Seller Photos/Publish.

A prova social usa parser HTML e compara `og:title`/Twitter title com o título público; `og:description`/Twitter description com a description normal; `og:url` com canonical; e `og:image`/Twitter image com a primeira foto pública real. Após Pause, o detalhe retorna 404 e a URL social do Listing deixa de existir no HTML retornado.

Classe da evidência: **B — comportamento observado/reproduzido no CI do BPT2**.

## Decision log

- **DECIDIDO:** metadata social do Listing deriva somente da projeção pública atual; não existe segunda fonte de verdade.
- **DECIDIDO:** a primeira foto pública, quando existente, é reutilizada como imagem social; não existe asset paralelo.
- **DECIDIDO:** sem foto, o Listing usa card sem imagem em vez de inventar placeholder.
- **NÃO DECIDIDO:** JSON-LD, social image dedicada, metadata social do Vehicle Hub/home/páginas agregadas e estratégia editorial.

## Progress log

- 2026-08-24: `main` remoto confirmado em `7ab5cafb3d63e8348839245cb7ad8024bc5a997a` após o Plan 0015.
- 2026-08-24: auditoria encontrou Open Graph/Twitter explicitamente aberto e zero implementação no repo; Promoções/Admin/Alerts não possuíam implementação parcial comparável.
- 2026-08-24: branch `feat/public-listing-share-metadata` e draft PR #35 abertos.
- 2026-08-24: metadata Open Graph/Twitter implementada no `generateMetadata` do detalhe do Listing e prova incorporada ao smoke público existente.
- 2026-08-24: Harness detectou somente divergência byte-a-byte no arquivo de fatos gerados; o arquivo foi corrigido para reproduzir exatamente o gerador, sem mudança de código ou weakening de gate.
- 2026-08-24: head funcional `1bd7d89fef5e4276a74b876bb6c0bdbabf97e98c` concluiu 9/9 workflows aplicáveis com sucesso e prova HTTP social explícita.
- 2026-08-24: fechamento documental iniciado; readiness de merge deve usar CI fresco do head documental final.

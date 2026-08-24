# Execution Plan 0013 — Public SEO Discovery

Status: **COMPLETO**

## Objetivo

Abrir a primeira fatia explícita de SEO técnico tornando a superfície pública rastreável sem criar contrato backend novo.

Fluxo:

`Listing público → sitemap/robots → crawler descobre URL → detalhe publica canonical`

## Evidência que abriu o slice

- `docs/PRODUCT.md` mantém SEO como capacidade central.
- O detalhe público já publicava `title` e `description`, mas não havia `robots.txt` nem `sitemap.xml` no App Router.
- A API pública paginada já é autoridade de visibilidade e permite projetar somente Listings atualmente públicos.
- Um painel administrativo exigiria decidir nova superfície UI/auth; SEO técnico fechava um gap menor com boundaries existentes.

## Escopo entregue

- helper de URL pública canônica via `BPT_PUBLIC_BASE_URL`;
- `robots.txt` dinâmico apontando ao sitemap e bloqueando `/favoritos`, `/vender` e `/api/` para crawling;
- `sitemap.xml` dinâmico que pagina a API pública existente;
- home e Listings publicados no sitemap;
- canonical absoluto e robots index/follow no detalhe público;
- metadata no detalhe inexistente marcada como noindex/nofollow;
- prova HTTP real de Draft, Publish e Pause.

## Fora de escopo

- schema.org/JSON-LD;
- Open Graph/Twitter cards;
- landing pages por marca/modelo/localidade;
- estratégia de keywords/conteúdo;
- Search Console/analytics;
- cache/revalidation específica do sitemap;
- ranking de busca;
- endpoint backend novo de SEO.

## Critérios de aceite

- [x] `robots.txt` existe e aponta para o sitemap canônico;
- [x] `/favoritos`, `/vender` e `/api/` são desabilitados para crawling;
- [x] sitemap inclui home;
- [x] Draft/private não entra no sitemap;
- [x] Published entra no sitemap;
- [x] detalhe Published publica canonical absoluto;
- [x] Pause remove o Listing do sitemap;
- [x] public web build e workflows aplicáveis permanecem verdes.

## Evidência executada

Head funcional: `7e2cc2ec93fd5d7ca1ce0b829cb163064a1f5dfd`.

Public Buyer HTTP Gate, run `32729394598`, job `97437944549`, em PostgreSQL fresco, host ABP real e Next.js de produção:

- `PUBLIC_SEO_ROBOTS: PASS`
- `PUBLIC_SEO_DRAFT_EXCLUDED: PASS`
- `PUBLIC_SEO_PUBLISHED_IN_SITEMAP: PASS`
- `PUBLIC_SEO_CANONICAL: PASS`
- `PUBLIC_SEO_PAUSED_EXCLUDED: PASS`
- `PUBLIC SEO HTTP: PASSED`

O mesmo run preservou verde o fluxo Public Buyer, Lead/WhatsApp, fresh migration e build Release com 0 warnings/0 errors. O Public Web Gate também passou e o head funcional fechou 9/9 workflows aplicáveis verdes.

Classe da evidência: **B — comportamento observado/reproduzido no CI do BPT2**.

## Progress log

- 2026-08-24: slice aberto após nova auditoria do menor gap central; SEO técnico já tinha metadata parcial e não exigia domínio/auth novos.
- 2026-08-24: adicionados `robots.ts`, `sitemap.ts`, URL canônica e canonical no detalhe.
- 2026-08-24: o gate focal executou o ciclo Draft → Publish → Pause e passou integralmente sem correção funcional intermediária.
- 2026-08-24: head funcional fechou 9/9 workflows aplicáveis verdes.

## Decision log

- 2026-08-24: sitemap reutiliza a API pública; não duplica a matriz de status de Listing no frontend.
- 2026-08-24: produção deve fornecer `BPT_PUBLIC_BASE_URL`; fallback local existe apenas para desenvolvimento/CI.
- 2026-08-24: rotas autenticadas/utilitárias de Buyer, Seller e API não são alvo de crawling.
- 2026-08-24: JSON-LD, Open Graph e landing pages permanecem NÃO DECIDIDOS até necessidade/evidência.

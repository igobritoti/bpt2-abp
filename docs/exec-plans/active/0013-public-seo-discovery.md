# Execution Plan 0013 — Public SEO Discovery

Status: **ATIVO**

## Objetivo

Abrir a primeira fatia explícita de SEO técnico tornando a superfície pública rastreável por mecanismos de busca sem criar contrato backend novo.

Fluxo:

`Listing público → sitemap/robots → crawler descobre URL → detalhe publica canonical`

## Evidência que abriu o slice

- `docs/PRODUCT.md` mantém SEO como capacidade central.
- O detalhe público já publica `title` e `description`, portanto SEO não está zerado.
- Não existe `sitemap.ts` nem `robots.ts` no App Router atual.
- A API pública já fornece Listings paginados e aplica a regra canônica de visibilidade, permitindo gerar sitemap sem duplicar regra de Draft/Pause/Archive.
- O painel administrativo exigiria decidir uma nova superfície UI/auth; este slice fecha um gap menor usando boundaries já existentes.

## Escopo

- URL pública canônica configurável para o public web;
- `robots.txt` permitindo a superfície pública e bloqueando rotas utilitárias/autenticadas;
- `sitemap.xml` gerado a partir da API pública paginada;
- canonical no detalhe de Listing público;
- prova HTTP real de inclusão de Published e remoção após Pause.

## Fora de escopo

- schema.org/JSON-LD;
- Open Graph/Twitter cards;
- landing pages por marca/modelo/localidade;
- estratégia de keywords/conteúdo;
- Search Console/analytics;
- cache/revalidation de sitemap;
- mudança no ranking de busca;
- novo endpoint backend de SEO.

## Critérios de aceite

- [ ] `robots.txt` existe e aponta para o sitemap canônico;
- [ ] rotas `/favoritos`, `/vender` e `/api/` não são destinadas a crawling;
- [ ] `sitemap.xml` inclui a home e Listings atualmente públicos;
- [ ] Draft/private não entra no sitemap;
- [ ] Listing pausado deixa de entrar no sitemap sem apagar domínio/histórico;
- [ ] detalhe público contém canonical absoluto;
- [ ] builds e gates aplicáveis permanecem verdes.

## Progress log

- 2026-08-24: slice selecionado por evidência após o Plan 0012; SEO técnico é central, já possui metadata parcial e pode ser completado sem nova auth, domínio ou infraestrutura.

## Decision log

- 2026-08-24: sitemap reutiliza `getPublicListings`; a regra de indexabilidade não duplica a matriz de status do backend.
- 2026-08-24: URL pública do site entra por configuração `BPT_PUBLIC_BASE_URL`; produção deve configurá-la explicitamente.

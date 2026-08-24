# Execution Plan 0023 — Public Seller Hub Share Metadata

Status: **ATIVO**

## Objetivo

Fechar a metadata social mínima do Seller Hub recém-entregue no Plan 0022:

`Seller com oferta pública → /vendedores/{sellerId} → metadata social SSR → link compartilhável coerente`

## Evidência que abriu o slice

- O Plan 0022 criou `/vendedores/{sellerId}` derivado somente de Listings públicos e já publica `title`, `description` e `canonical` via `generateMetadata`.
- O Plan 0016 provou o padrão Open Graph/Twitter para Listing reutilizando a metadata normal da própria página.
- O Plan 0019 provou o mesmo padrão para Vehicle Hub e decidiu não inventar imagem quando não existe asset canônico próprio.
- `PRODUCT.md` mantém metadata social de páginas agregadas como decisão aberta.
- Sort/ranking exigiria semântica nova; incluir Seller Hub no sitemap exige deduplicação transversal. A metadata social é a menor extensão sustentada por implementação existente.

## Escopo

- reutilizar `displayName`, `description` e `canonical` já calculados no Seller Hub;
- publicar Open Graph `title`, `description`, `url` e `type=website`;
- publicar Twitter `card=summary`, `title` e `description`;
- não publicar `og:image`/`twitter:image` sem asset canônico próprio do Seller;
- ampliar o smoke HTTP existente do Seller Hub para provar metadata social e ausência de imagem inventada;
- preservar 404/noindex para Seller inválido ou sem Listing público.

## Fora de escopo

- avatar/logo/imagem social dedicada;
- perfil público paralelo, descrição editorial, endereço, reputação ou verificação;
- WhatsApp genérico fora de Listing/Lead;
- sitemap do Seller Hub;
- JSON-LD/schema.org;
- slug semântico;
- metadata social da home ou outras páginas agregadas;
- novo backend, schema, migration ou contrato.

## Critérios de aceite

1. [ ] Seller Hub público mantém title/description/canonical atuais.
2. [ ] Open Graph usa exatamente o mesmo title/description/canonical.
3. [ ] Twitter usa `summary` e o mesmo title/description.
4. [ ] nenhuma imagem social é inventada ou derivada arbitrariamente de Listing.
5. [ ] Seller inexistente/sem oferta pública continua sem página social válida.
6. [ ] nenhum backend/domain/schema/migration/contrato novo é introduzido.
7. [ ] gate focal e workflows aplicáveis passam no head funcional e novamente no head documental final.

## Decisões

- **DECIDIDO para este slice:** metadata social deriva exclusivamente da identidade já projetada pelo primeiro Listing público e do canonical existente.
- **DECIDIDO para este slice:** sem asset canônico próprio, Twitter usa `summary` e não há `og:image`/`twitter:image`.
- **NÃO DECIDIDO:** logo/avatar do Seller, social image dedicada, JSON-LD, sitemap, slug, reputação/verificação e enriquecimento editorial.

## Progress log

- 2026-08-24: `main` remoto confirmado em `bdf3f347062779a980e4c9430ab05569a2ce72df`, merge do Plan 0022, sem plan ativo ou blocker.
- 2026-08-24: auditoria comparou Seller Hub share metadata, sitemap e sort; share metadata selecionada como menor gap com implementação parcial explícita.
- 2026-08-24: branch `feat/public-seller-hub-share-metadata` criada a partir do `main` verificado.

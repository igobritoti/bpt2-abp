# Execution Plan 0023 — Public Seller Hub Share Metadata

Status: **CONCLUÍDO**

## Objetivo

Fechar a metadata social mínima do Seller Hub entregue no Plan 0022:

`Seller com oferta pública → /vendedores/{sellerId} → metadata social SSR → link compartilhável coerente`

## Evidência que abriu o slice

- O Plan 0022 criou `/vendedores/{sellerId}` derivado somente de Listings públicos e já publicava `title`, `description` e `canonical` via `generateMetadata`.
- O Plan 0016 provou o padrão Open Graph/Twitter para Listing reutilizando a metadata normal da própria página.
- O Plan 0019 provou o mesmo padrão para Vehicle Hub e decidiu não inventar imagem quando não existe asset canônico próprio.
- `PRODUCT.md` mantém metadata social de páginas agregadas como decisão aberta; este slice resolve somente o Seller Hub.
- Sort/ranking exigiria semântica nova; incluir Seller Hub no sitemap exige deduplicação transversal. A metadata social era a menor extensão sustentada por implementação existente.

## Escopo executado

- `generateMetadata` do Seller Hub passou a publicar Open Graph `type=website`, `title`, `description` e `url`;
- Twitter passou a publicar `card=summary`, `title` e `description`;
- os valores reutilizam exatamente `displayName`, `description` e `canonical` já calculados pela página;
- não foram adicionados `og:image`/`twitter:image`;
- o smoke HTTP existente passou a validar metadata social, ausência de imagem e 404 sem `og:url` para Seller inexistente ou sem oferta pública;
- nenhuma mudança de backend, domínio, schema, migration ou contrato foi necessária.

## Fora de escopo

- avatar/logo/imagem social dedicada;
- perfil público paralelo, descrição editorial, endereço, reputação ou verificação;
- WhatsApp genérico fora de Listing/Lead;
- sitemap do Seller Hub;
- JSON-LD/schema.org;
- slug semântico;
- metadata social da home ou demais páginas agregadas;
- novo backend, schema, migration ou contrato.

## Critérios de aceite

1. [x] Seller Hub público mantém title/description/canonical atuais.
2. [x] Open Graph usa exatamente o mesmo title/description/canonical.
3. [x] Twitter usa `summary` e o mesmo title/description.
4. [x] nenhuma imagem social é inventada ou derivada arbitrariamente de Listing.
5. [x] Seller inexistente/sem oferta pública continua sem página social válida.
6. [x] nenhum backend/domain/schema/migration/contrato novo foi introduzido.
7. [x] gate focal e todos os workflows aplicáveis passaram no head funcional.

## Evidência executada

Head funcional: `c1335f82c3c3a56c3ffce3e90867618e50e0b7fa`.

Todos os **9/9 workflows aplicáveis** passaram nesse head.

O gate focal **BPT2 Public Buyer HTTP Gate** executou no run `32765993829`, job `97555480382`, contra PostgreSQL 17 fresco, host ABP real e build/start de produção do Next.js.

Marcadores exatos do Seller Hub:

- `PUBLIC_SELLER_HUB_DETAIL_LINK: PASS`
- `PUBLIC_SELLER_HUB_SHARE_METADATA: PASS`
- `PUBLIC_SELLER_HUB_SHARE_METADATA_NO_IMAGE: PASS`
- `PUBLIC_SELLER_HUB_VISIBLE: PASS`
- `PUBLIC_SELLER_HUB_ISOLATED: PASS`
- `PUBLIC_SELLER_HUB_SHARE_METADATA_UNKNOWN_404: PASS`
- `PUBLIC_SELLER_HUB_UNKNOWN_HIDDEN: PASS`
- `PUBLIC_SELLER_HUB_SHARE_METADATA_EMPTY_404: PASS`
- `PUBLIC_SELLER_HUB_EMPTY_HIDDEN: PASS`
- `PUBLIC_SELLER_HUB_FIXTURES_CLEANED: PASS`
- `PUBLIC SELLER HUB HTTP: PASSED`

No mesmo job, Vehicle Hub, SEO e Lead forwarding autenticado também concluíram em SUCCESS após o Seller Hub.

Classe da evidência: **B — comportamento reproduzido em CI contra aplicação real**.

## Falhas investigadas

- O primeiro head funcional falhou apenas no Harness porque o execution plan usava `## Decisões` em vez do heading literal exigido `## Decision log`.
- A correção alterou somente o heading documental; código e smoke permaneceram idênticos.
- Nenhuma falha funcional da metadata foi observada.

## Decision log

- **DECIDIDO para este slice:** metadata social deriva exclusivamente da identidade já projetada pelo primeiro Listing público e do canonical existente.
- **DECIDIDO para este slice:** sem asset canônico próprio, Twitter usa `summary` e não há `og:image`/`twitter:image`.
- **NÃO DECIDIDO:** logo/avatar do Seller, social image dedicada, JSON-LD, sitemap, slug, reputação/verificação e enriquecimento editorial.

## Progress log

- 2026-08-24: `main` remoto confirmado em `bdf3f347062779a980e4c9430ab05569a2ce72df`, merge do Plan 0022, sem plan ativo ou blocker.
- 2026-08-24: auditoria comparou Seller Hub share metadata, sitemap e sort; share metadata selecionada como menor gap com implementação parcial explícita.
- 2026-08-24: branch `feat/public-seller-hub-share-metadata` criada e draft PR #42 aberto.
- 2026-08-24: Open Graph/Twitter e prova HTTP adicionados sem backend/schema/migration/contrato.
- 2026-08-24: Harness acusou somente heading documental; correção focada aplicada.
- 2026-08-24: head funcional `c1335f82c3c3a56c3ffce3e90867618e50e0b7fa` concluiu 9/9 workflows SUCCESS; documentação preparada para CI final fresco.

## Resultado

**PASSA / CONCLUÍDO.** O Seller Hub agora possui metadata social SSR coerente com sua metadata normal, sem inventar identidade visual ou contato paralelo.

## Gaps futuros

Sitemap do Seller Hub, JSON-LD, slug semântico, logo/avatar, imagem social dedicada, reputação/verificação e enriquecimento editorial permanecem abertos. Metadata social da home e demais páginas agregadas também continua não decidida.

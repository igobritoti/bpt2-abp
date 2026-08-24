# Execution Plan 0019 — Public Vehicle Hub Share Metadata

Status: **COMPLETO**

## Objetivo

Fechar a metadata social mínima do Vehicle Hub público já existente:

`Vehicle canônico → /veiculos/{id} → metadata social SSR → link compartilhável coerente`

## Evidência que abriu o slice

- `PRODUCT.md` mantinha metadata social do Vehicle Hub explicitamente aberta após os Plans 0015/0016.
- `/veiculos/{id}` já possuía `generateMetadata`, title, description, canonical, robots e identidade canônica carregada do Catalog.
- o Plan 0016 já havia comprovado no mesmo Next.js/App Router que `openGraph` e `twitter` derivados da metadata pública atual funcionam em SSR e build de produção.
- o smoke `public-vehicle-hub-http-smoke.sh` já validava title/canonical/404/noindex e rodava dentro do Public Buyer HTTP Gate.
- buscas no repo não encontraram implementação parcial de Promoções, Buyer Alerts ou JSON-LD; esses candidatos exigiriam novos conceitos ou vocabulário semântico adicional.
- documentação oficial atual do Next.js mantém `generateMetadata`/Metadata API e Open Graph como mecanismo suportado para shareability.

## Escopo entregue

- Open Graph no `generateMetadata` do Vehicle Hub existente;
- Twitter card equivalente;
- title, description e URL social derivados exatamente dos mesmos valores já usados pela metadata normal;
- nenhuma consulta adicional de Listing/foto para produzir metadata;
- nenhum `og:image`/`twitter:image` inventado sem asset canônico próprio do Vehicle;
- `twitter:card=summary` quando não há imagem;
- Vehicle inexistente continua 404/noindex e não publica `og:url` para a URL inexistente;
- prova incorporada ao smoke do Vehicle Hub já existente, sem novo workflow.

## Fora de escopo

- imagem social dedicada ou geração dinâmica de imagem;
- reutilizar foto de Listing como se fosse imagem canônica do Vehicle;
- metadata social da home ou páginas agregadas;
- JSON-LD/schema.org;
- landing pages, keywords/conteúdo, analytics/Search Console;
- enrichment do Vehicle Hub;
- páginas Brand/Model/Generation/Version;
- Promoções, Buyer Alerts ou novo backend;
- schema/migration/cache/infra nova.

## Critérios de aceite

1. [x] Vehicle existente retorna `og:title`, `og:description` e `og:url` coerentes com title/description/canonical atuais.
2. [x] Vehicle existente retorna Twitter card coerente e sem imagem inventada.
3. [x] metadata social deriva somente da identidade canônica já carregada do Catalog.
4. [x] Vehicle inexistente continua 404 + noindex e não ganha superfície social pública válida.
5. [x] nenhuma consulta de Listing/foto, backend, schema, migration ou contrato novo foi introduzido.
6. [x] Public Web build, smoke focal e nove workflows aplicáveis passaram no head funcional.
7. [x] docs finais fecham somente Vehicle Hub share metadata e preservam JSON-LD/imagem dedicada/home/agregados como NÃO DECIDIDOS.

## Evidência executada

Head funcional comprovado: `7d0e3ac84b7bc1c8953fc1e58696435668b7442d`.

`BPT2 Public Buyer HTTP Gate`, run `32749940572`, job `97504258600`, usando PostgreSQL fresco, host ABP real e build/start de produção do Next.js 16.2.12:

- `FRESH MIGRATION GATE: PASSED`
- build Release: `0 Warning(s)` / `0 Error(s)`
- `PUBLIC BUYER HTTP FLOW: PASSED`
- `VEHICLE_HUB_UNKNOWN_404: PASS`
- `VEHICLE_HUB_UNKNOWN_NOINDEX: PASS`
- `VEHICLE_HUB_SHARE_METADATA_UNKNOWN_404: PASS`
- `VEHICLE_HUB_CANONICAL_IDENTITY: PASS`
- `VEHICLE_HUB_METADATA: PASS`
- `VEHICLE_HUB_SHARE_METADATA: PASS`
- `VEHICLE_HUB_DRAFT_PRIVATE: PASS`
- `VEHICLE_HUB_PUBLISHED_VISIBLE: PASS`
- `VEHICLE_HUB_LINKED_FROM_LISTING: PASS`
- `VEHICLE_HUB_PAUSE_REMOVES_LISTING: PASS`
- `VEHICLE_HUB_PERSISTS_WITHOUT_OFFER: PASS`
- `PUBLIC VEHICLE HUB HTTP: PASSED`
- `PUBLIC SEO HTTP: PASSED`
- `AUTHENTICATED_LEAD_FORWARDING: PASS`

No mesmo head, os nove workflows aplicáveis concluíram `success`: Harness, Public Web, Public Buyer, Public Discovery, Buyer Favorites, Seller Auth, Seller Draft/Edit, Seller Shell e Seller Photos/Publish.

A primeira execução focal em `d513089415b37a4cccda0c1121776da12b3a99c9` falhou somente porque o smoke hard-coded ignorava a marca randômica da fixture ao comparar `og:title`; o HTML já continha o título social derivado da identidade canônica completa. O smoke foi corrigido para comparar `og:title`/Twitter title com o `<title>` normal renderizado, preservando a exigência de igualdade entre metadata normal e social. Nenhuma linha de produto mudou nessa correção.

Classe da evidência: **B — comportamento observado/reproduzido no CI do BPT2**.

## Checkpoints

- [x] `main` remoto confirmado em `89f68c8f51d119624a6ec21ceb2bfa07cf71c74e` após o Plan 0018.
- [x] gaps de produto e implementação parcial revalidados.
- [x] branch `feat/vehicle-hub-share-metadata` criada.
- [x] draft PR #38 aberto antes da implementação funcional.
- [x] metadata social e prova HTTP focal implementadas.
- [x] falha observada corrigida somente no smoke, sem alterar produto.
- [x] head funcional `7d0e3ac84b7bc1c8953fc1e58696435668b7442d` com 9/9 workflows aplicáveis em SUCCESS.
- [ ] exigir CI fresco do head documental final, review/base refresh e merge verde.

## Decision log

- **DECIDIDO:** Vehicle Hub reutiliza o padrão de Open Graph/Twitter já comprovado no Listing, sem nova fonte de verdade.
- **DECIDIDO:** title/description/canonical sociais derivam dos mesmos valores da metadata normal do Hub.
- **DECIDIDO:** não usar foto de Listing como imagem canônica do Vehicle Hub; ausência de asset próprio significa card sem imagem.
- **NÃO DECIDIDO:** imagem social dedicada, JSON-LD, metadata social da home/agregados, enrichment e estratégia editorial.

## Progress log

- 2026-08-24: `main` remoto confirmado em `89f68c8f51d119624a6ec21ceb2bfa07cf71c74e` após merge do Plan 0018.
- 2026-08-24: auditoria confirmou metadata social do Vehicle Hub como menor gap componível: a página, metadata normal e smoke já existiam, enquanto Promoções/Alerts/JSON-LD não tinham implementação parcial equivalente.
- 2026-08-24: branch `feat/vehicle-hub-share-metadata` criada e draft PR #38 aberto.
- 2026-08-24: Open Graph/Twitter adicionados ao Vehicle Hub sem imagem e sem consulta adicional; smoke focal passou a validar igualdade com metadata normal, ausência de imagem e 404/noindex.
- 2026-08-24: a primeira execução revelou apenas assumption inválida do teste sobre a marca da fixture; a correção derivou o esperado do `<title>` normal e manteve o produto intacto.
- 2026-08-24: head funcional `7d0e3ac84b7bc1c8953fc1e58696435668b7442d` fechou 9/9 workflows aplicáveis com sucesso.

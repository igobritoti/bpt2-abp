# Execution Plan 0019 — Public Vehicle Hub Share Metadata

Status: **ATIVO**

## Objetivo

Fechar a metadata social mínima do Vehicle Hub público já existente:

`Vehicle canônico → /veiculos/{id} → metadata social SSR → link compartilhável coerente`

## Evidência que abriu o slice

- `PRODUCT.md` mantém metadata social do Vehicle Hub explicitamente aberta após os Plans 0015/0016.
- `/veiculos/{id}` já possui `generateMetadata`, title, description, canonical, robots e identidade canônica carregada do Catalog.
- o Plan 0016 já comprovou no mesmo Next.js/App Router que `openGraph` e `twitter` derivados da metadata pública atual funcionam em SSR e build de produção.
- o smoke `public-vehicle-hub-http-smoke.sh` já valida title/canonical/404/noindex e roda dentro do Public Buyer HTTP Gate.
- buscas no repo não encontraram implementação parcial de Promoções, Buyer Alerts ou JSON-LD; esses candidatos exigiriam novos conceitos ou vocabulário semântico adicional.
- documentação oficial atual do Next.js mantém `generateMetadata`/Metadata API e Open Graph como mecanismo suportado para shareability.

## Escopo

- adicionar Open Graph ao `generateMetadata` do Vehicle Hub existente;
- adicionar Twitter card equivalente;
- derivar title, description e URL social exatamente da mesma identidade/canonical já usados pela metadata normal;
- não buscar Listing/foto extra só para metadata;
- sem imagem social quando não existe asset canônico próprio do Vehicle Hub;
- manter 404/noindex para Vehicle inexistente;
- ampliar somente o smoke do Vehicle Hub já existente.

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

1. [ ] Vehicle existente retorna `og:title`, `og:description` e `og:url` coerentes com title/description/canonical atuais.
2. [ ] Vehicle existente retorna Twitter card coerente e sem imagem inventada.
3. [ ] metadata social deriva somente da identidade canônica já carregada do Catalog.
4. [ ] Vehicle inexistente continua 404 + noindex e não ganha superfície social pública válida.
5. [ ] nenhuma consulta de Listing/foto, backend, schema, migration ou contrato novo é introduzido.
6. [ ] Public Web build e smoke focal passam; workflows aplicáveis permanecem verdes.
7. [ ] docs finais fecham somente Vehicle Hub share metadata e preservam JSON-LD/imagem dedicada/home/agregados como NÃO DECIDIDOS.

## Checkpoints

- [x] `main` remoto confirmado em `89f68c8f51d119624a6ec21ceb2bfa07cf71c74e` após o Plan 0018.
- [x] gaps de produto e implementação parcial revalidados.
- [x] branch `feat/vehicle-hub-share-metadata` criada.
- [ ] abrir draft PR.
- [ ] implementar metadata social e prova HTTP focal.
- [ ] corrigir somente falhas observadas.
- [ ] fechar docs, exigir CI fresco, review/base refresh e merge verde.

## Decision log

- **DECIDIDO para este slice:** Vehicle Hub reutiliza o padrão de Open Graph/Twitter já comprovado no Listing, sem nova fonte de verdade.
- **DECIDIDO para este slice:** não usar foto de Listing como imagem canônica do Vehicle Hub; ausência de asset próprio significa card sem imagem.
- **NÃO DECIDIDO:** imagem social dedicada, JSON-LD, metadata social da home/agregados, enrichment e estratégia editorial.

## Progress log

- 2026-08-24: `main` remoto confirmado em `89f68c8f51d119624a6ec21ceb2bfa07cf71c74e` após merge do Plan 0018.
- 2026-08-24: auditoria confirmou metadata social do Vehicle Hub como menor gap componível: a página, metadata normal e smoke já existem, enquanto Promoções/Alerts/JSON-LD não têm implementação parcial equivalente.
- 2026-08-24: branch `feat/vehicle-hub-share-metadata` criada a partir do `main` corrente.

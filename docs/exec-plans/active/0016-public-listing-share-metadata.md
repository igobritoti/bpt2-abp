# Execution Plan 0016 — Public Listing Share Metadata

Status: **ATIVO**

## Objetivo

Fechar a primeira fatia explícita de metadata de compartilhamento para o detalhe público do Listing:

`Listing publicado → metadata social SSR → link compartilhado com título/descrição/foto`

O slice deve reutilizar exclusivamente dados já públicos do Listing e a configuração canônica existente, sem criar backend, schema, armazenamento de imagem ou serviço externo.

## Evidência que abriu o slice

- `PRODUCT.md` mantém SEO como capacidade central e ainda lista Open Graph/Twitter cards como decisão aberta.
- o detalhe público já possui `generateMetadata`, title, description, canonical e robots.
- `PublicListing` já expõe título, preço, localização, identidade do Vehicle e fotos públicas.
- `publicPhotoUrl` já produz URL absoluta da foto pública quando ela existe.
- busca no repo não encontrou implementação de Open Graph/Twitter, nem implementação parcial equivalente de Promoções, Admin UI ou Buyer Alerts.
- portanto este slice fecha um gap real com composição no public web e zero decisão de domínio/infraestrutura nova.

## Escopo

- publicar Open Graph no detalhe público de Listing existente;
- publicar Twitter card equivalente;
- reutilizar a mesma description e canonical já derivadas do Listing;
- usar a primeira foto pública como `og:image`/Twitter image quando já existir;
- usar card sem imagem quando o Listing não tiver foto;
- manter Listing inexistente/privado como 404/noindex, sem metadata social indexável;
- provar o comportamento por HTTP real no gate público já existente.

## Fora de escopo

- JSON-LD/schema.org;
- metadata do Vehicle Hub, home ou páginas agregadas;
- geração/redimensionamento dedicado de imagem social;
- upload de thumbnail social;
- analytics/Search Console;
- landing pages, keywords/conteúdo e ranking;
- Promoções, Admin UI, Buyer Alerts;
- backend, migration, cache ou infraestrutura nova.

## Critérios de aceite

1. [ ] Listing publicado retorna `og:title`, `og:description` e `og:url` coerentes com title/description/canonical atuais.
2. [ ] Listing publicado retorna Twitter card coerente.
3. [ ] Listing com foto pública usa a primeira foto como imagem social absoluta.
4. [ ] metadata social não inventa campos de domínio nem copia regra de visibilidade.
5. [ ] Listing Draft/Paused/Archive continua não acessível publicamente e não ganha superfície social indexável.
6. [ ] build e workflows aplicáveis passam no head final.
7. [ ] docs fecham somente Listing share metadata; JSON-LD, Vehicle Hub metadata social e outras extensões permanecem abertas.

## Checkpoints

- [x] refetch do `main` remoto em `7ab5cafb3d63e8348839245cb7ad8024bc5a997a`.
- [x] auditar Promoções, Admin UI, Buyer Alerts e extensões SEO contra código existente.
- [x] confirmar ausência de Open Graph/Twitter e presença de dados públicos suficientes no Listing.
- [x] criar branch `feat/public-listing-share-metadata`.
- [ ] abrir draft PR.
- [ ] implementar metadata social mínima.
- [ ] ampliar prova HTTP existente somente com assertions do slice.
- [ ] corrigir apenas falhas observadas.
- [ ] self-review e fechamento documental.
- [ ] exigir CI fresco no head final e merge somente verde.
- [ ] verificar `main` pós-merge e zero planos ativos.

## Decisões abertas necessárias

Nenhuma decisão arquitetural nova. JSON-LD, imagem social dedicada, Vehicle Hub social metadata, estratégia de conteúdo e integrações externas permanecem abertas.

## Decision log

- **DECIDIDO para este slice:** metadata social deriva apenas da projeção pública atual do Listing.
- **DECIDIDO para este slice:** a primeira foto pública, quando existente, é reutilizada como imagem social; não haverá asset paralelo.
- **DECIDIDO para este slice:** sem foto, a página continua compartilhável sem inventar placeholder de domínio.
- **NÃO DECIDIDO:** JSON-LD, social image dedicada, metadata social do Vehicle Hub/home e estratégia editorial.

## Progress log

- 2026-08-24: `main` remoto confirmado em `7ab5cafb3d63e8348839245cb7ad8024bc5a997a` após o Plan 0015.
- 2026-08-24: auditoria encontrou Open Graph/Twitter explicitamente aberto e zero implementação no repo; Promoções/Admin/Alerts não possuem implementação parcial comparável.
- 2026-08-24: branch `feat/public-listing-share-metadata` criada a partir do `main` verificado.

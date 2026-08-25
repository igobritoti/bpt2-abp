# Execution Plan 0031 — Public Listing Structured Data

Status: **ATIVO**

## Objetivo

Adicionar JSON-LD semântico ao detalhe de Listing público usando somente dados já canônicos e visíveis, sem alterar backend, schema, ranking ou política de produto.

Outcome vertical esperado:

`Listing publicado → detalhe SSR → Product + Vehicle JSON-LD → Offer com preço BRL → crawler recebe markup coerente com a página`

## Evidência que justifica o slice

- `public-web/app/anuncios/[id]/page.tsx` já produz detalhe SSR, canonical, Open Graph e Twitter a partir de `PublicListing`.
- O detalhe exibe título, descrição, preço, marca/modelo/versão, quilometragem, cor, localização e fotos quando disponíveis.
- Não existe `application/ld+json` no detalhe atual.
- Google Search Central recomenda JSON-LD como formato geralmente mais simples de implementar/manter e exige que structured data descreva conteúdo da própria página.
- A documentação atual de Product snippets exige `Product.name` e ao menos um entre `review`, `aggregateRating` ou `offers`; `Offer.price` é requerido quando `offers` é usado.
- A mesma documentação recomenda markup de produto em páginas focadas em um único produto e explicita que subtipos automotivos devem incluir também `Product` para elegibilidade da feature.
- Schema.org define `Vehicle` como subtipo de `Product` e documenta `Offer` para representar um automóvel ofertado com preço/moeda.

## Escopo

- renderizar JSON-LD no HTML SSR somente quando o Listing for público;
- usar `@context = https://schema.org` e `@type = [Product, Vehicle]`;
- mapear somente dados já visíveis/canônicos: `name`, `description`, URL canônica, marca, modelo, versão, cor/quilometragem quando presentes, fotos públicas quando presentes e `Offer` com preço BRL;
- serializar o JSON-LD de forma segura para conteúdo controlado pelo Seller;
- estender o smoke SEO existente para validar o markup renderizado e sua coerência com o HTML/API.

## Fora de escopo

- reviews/ratings inexistentes;
- VIN, SKU/MPN, condição novo/usado ou datas não modeladas;
- inferir `Person` versus `Organization` para Seller;
- merchant listing/feed, Merchant Center ou checkout;
- garantia de rich result, CTR ou ganho de ranking;
- JSON-LD da home, Seller Hub ou Vehicle Hub;
- sitemap de Vehicle Hub;
- backend, migration ou nova infraestrutura.

## Critérios de aceite

1. [ ] detalhe público contém exatamente um bloco `application/ld+json` do Listing;
2. [ ] JSON-LD é JSON válido e explicita `Product` + `Vehicle`;
3. [ ] `name`, `description`, `url`, `brand`, `model` e versão correspondem à projeção/HTML visível;
4. [ ] `Offer` contém o mesmo preço visível, `BRL`, URL canônica e `InStock` apenas porque o detalhe existe somente para `Published`;
5. [ ] mileage/color são emitidos somente quando presentes, sem valores inventados;
6. [ ] fotos, quando presentes, usam somente URLs públicas já existentes; sem foto não se inventa imagem;
7. [ ] conteúdo textual controlado pelo Seller não consegue encerrar o bloco JSON-LD;
8. [ ] Draft/Pause/Moderated/Archived continuam sem detalhe público e portanto sem structured data;
9. [ ] Public Web e Public Buyer/SEO gates aplicáveis ficam verdes sem backend/schema novo.

## Decision log

- **DECIDIDO por evidência externa + modelo:** emitir `Product` e `Vehicle` juntos; `Product` preserva compatibilidade com a feature documentada pelo Google e `Vehicle` preserva semântica automotiva schema.org.
- **DECIDIDO:** usar `Offer`, não `AggregateOffer`, pois cada URL representa um único Listing/oferta.
- **DECIDIDO:** não emitir propriedades cuja autoridade não existe no modelo atual.
- **NÃO DECIDIDO:** structured data de Vehicle Hub/Seller Hub/home, Merchant Center e efeito mensurável em Search permanecem slices separados.

## Progress log

- 2026-08-25: `main` refetchado em `207ae3bf064e90b37cb094d86ef626be9d6ca48c` após merge do Plan 0030.
- 2026-08-25: sitemap de Vehicle Hub avaliado e adiado neste ponto porque enumeração pública do Catalog é limitada a 100 sem paginação.
- 2026-08-25: documentação atual de Google Search Central, Schema.org e Next.js confrontada com o detalhe público existente; JSON-LD do Listing selecionado como menor slice vertical sem nova autoridade.

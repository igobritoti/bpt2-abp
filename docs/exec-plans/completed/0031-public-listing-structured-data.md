# Execution Plan 0031 — Public Listing Structured Data

Status: **COMPLETO**

## Objetivo

Adicionar JSON-LD semântico ao detalhe de Listing público usando somente dados já canônicos e visíveis, sem alterar backend, schema, ranking ou política de produto.

Outcome vertical comprovado:

`Listing publicado → detalhe SSR → Product + Vehicle JSON-LD → Offer com preço BRL → crawler recebe markup coerente com a página`

## Evidência que justificou o slice

- `public-web/app/anuncios/[id]/page.tsx` já produzia detalhe SSR, canonical, Open Graph e Twitter a partir de `PublicListing`.
- O detalhe já exibia título, descrição, preço, marca/modelo/versão, quilometragem, cor, localização e fotos quando disponíveis.
- Não existia `application/ld+json` no detalhe.
- Google Search Central recomenda JSON-LD como formato geralmente mais simples de implementar/manter e exige que structured data descreva conteúdo da própria página.
- A documentação de Product snippets exige `Product.name` e ao menos um entre `review`, `aggregateRating` ou `offers`; `Offer.price` é requerido quando `offers` é usado.
- A mesma documentação recomenda markup de produto em páginas focadas em um único produto e explicita que subtipos automotivos devem incluir também `Product` para elegibilidade da feature.
- Schema.org define `Vehicle` como subtipo de `Product`, `Offer` para representar o automóvel ofertado e `mileageFromOdometer` com `QuantitativeValue`/`KMT`.
- O sitemap de Vehicle Hub foi considerado, mas adiado porque a enumeração pública do Catalog segue limitada a 100 itens sem paginação/skip; resolver isso exigiria ampliar o contrato do Catalog e não era o menor slice independente.

## Escopo entregue

- JSON-LD renderizado no HTML SSR somente quando o Listing é público;
- `@context = https://schema.org` e `@type = [Product, Vehicle]`;
- `name`, `description`, URL canônica, Brand, model e `vehicleConfiguration` derivados somente da projeção pública;
- `color` e `mileageFromOdometer` condicionais;
- fotos públicas condicionais, sem inventar imagem quando ausente;
- `Offer` com URL canônica, preço, `BRL` e `InStock` para Listing publicamente disponível;
- serialização que escapa `<` como `\u003c`, impedindo conteúdo Seller como `</script>` de encerrar o bloco JSON-LD;
- `formatPrice` passou a preservar até duas casas decimais quando existentes, coerente com `Listing.Price` persistido como `numeric(18,2)` e com o preço emitido no Offer;
- smoke HTTP focal integrado ao `BPT2 Public Buyer HTTP Gate`, sem workflow novo.

## Fora de escopo preservado

- reviews/ratings inexistentes;
- VIN, SKU/MPN, condição novo/usado ou datas não modeladas;
- inferir `Person` versus `Organization` para Seller;
- merchant listing/feed, Merchant Center ou checkout;
- garantia de rich result, CTR ou ganho de ranking;
- JSON-LD da home, Seller Hub ou Vehicle Hub;
- sitemap de Vehicle Hub;
- backend, migration ou nova infraestrutura.

## Critérios de aceite

1. [x] detalhe público contém exatamente um bloco `application/ld+json` do Listing;
2. [x] JSON-LD é JSON válido e explicita `Product` + `Vehicle`;
3. [x] `name`, `description`, `url`, `brand`, `model` e versão correspondem à projeção/HTML visível;
4. [x] `Offer` contém o mesmo preço visível, `BRL`, URL canônica e `InStock` apenas porque o detalhe existe somente para `Published`;
5. [x] mileage/color são emitidos somente quando presentes, sem valores inventados;
6. [x] fotos, quando presentes, usam somente URLs públicas já existentes; sem foto não se inventa imagem;
7. [x] conteúdo textual controlado pelo Seller não consegue encerrar o bloco JSON-LD;
8. [x] estados não públicos continuam sem detalhe público e portanto sem structured data;
9. [x] Public Web, Public Buyer/SEO e todas as regressões aplicáveis ficaram verdes sem backend/schema novo.

## Evidência executada

Head funcional `4a8fd22a1f746b455f118ac26f8bda9dec82c9b1`:

- `BPT2 Public Buyer HTTP Gate` run `32850643822`: **success**; o smoke focal validou JSON válido, exatamente um bloco, `Product` + `Vehicle`, Offer BRL, dados coerentes com a API, preço decimal visível, ausência de campos inventados, Draft/Pause sem markup e payload Seller incapaz de criar breakout de `<script>`;
- `BPT2 Public Web Gate` run `32850643854`: **success**, incluindo lint, typecheck e production build;
- `BPT2 Harness Gate` run `32850643869`: **success**;
- Seller Draft Edit, Public Discovery, Buyer Favorites, Seller Photos Publish, Seller Auth e Seller Shell também concluíram com **success** no mesmo head;
- portanto os **9 workflows aplicáveis** ao head funcional concluíram com sucesso.

A primeira execução do Harness no head anterior falhou somente porque o plano usava o heading `## Decisões` em vez do literal exigido `## Decision log`; o heading foi corrigido sem alterar código de produto e o Harness passou no head funcional final.

## Decision log

- **DECIDIDO por evidência externa + modelo:** emitir `Product` e `Vehicle` juntos; `Product` preserva compatibilidade com a feature documentada pelo Google e `Vehicle` preserva semântica automotiva schema.org.
- **DECIDIDO:** usar `Offer`, não `AggregateOffer`, pois cada URL representa um único Listing/oferta.
- **DECIDIDO:** não emitir propriedades cuja autoridade não existe no modelo atual.
- **DECIDIDO por coerência executada:** preço visível deve preservar centavos quando persistidos para não divergir do `Offer.price`.
- **DECIDIDO:** o smoke focal usa Listing sem foto para reutilizar com segurança o build Next produzido pelo smoke SEO anterior; a emissão condicional de fotos permanece no código e os gates existentes continuam cobrindo o fluxo de mídia.
- **NÃO DECIDIDO:** structured data de Vehicle Hub/Seller Hub/home, Merchant Center e efeito mensurável em Search permanecem slices separados.

## Progress log

- 2026-08-25: `main` refetchado em `207ae3bf064e90b37cb094d86ef626be9d6ca48c` após merge do Plan 0030.
- 2026-08-25: sitemap de Vehicle Hub avaliado e adiado porque enumeração pública do Catalog é limitada a 100 sem paginação.
- 2026-08-25: documentação atual de Google Search Central, Schema.org e Next.js confrontada com o detalhe público existente; JSON-LD do Listing selecionado como menor slice vertical sem nova autoridade.
- 2026-08-25: JSON-LD, serialização segura, coerência decimal e smoke focal implementados.
- 2026-08-25: primeira execução do Harness revelou somente incompatibilidade de heading do execution plan; corrigida isoladamente.
- 2026-08-25: os 9 workflows aplicáveis ficaram verdes no head funcional `4a8fd22a1f746b455f118ac26f8bda9dec82c9b1`; PR sem reviews, issue comments ou inline review comments e `main` ainda no base esperado antes do fechamento documental.
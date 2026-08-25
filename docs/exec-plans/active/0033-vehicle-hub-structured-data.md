# Execution Plan 0033 — Vehicle Hub Structured Data

Status: **ATIVO**

## Objetivo

Adicionar dados estruturados server-rendered ao Vehicle Hub canônico usando somente a identidade automotiva já exibida na página.

Vertical proof:

`Canonical Vehicle → /veiculos/{id} SSR → schema.org Vehicle JSON-LD → identidade visível e URL canônica coerentes`

## Contexto

O `main` de partida é `d610b0f0a5bd244da9e8504265f667e0e2416d95`, depois do merge do Plan 0032.

Evidência atual:

- o Vehicle Hub já é uma página canônica pública, existe mesmo sem oferta ativa e está enumerado no sitemap completo;
- a página já expõe Brand, Model, Generation opcional, Version e ModelYear opcional;
- não existe bloco `application/ld+json` no Vehicle Hub;
- Schema.org mantém `Vehicle` como subtipo de `Product` e define `vehicleConfiguration` para a configuração/versão do veículo;
- `vehicleModelDate`/`modelDate` exigem `Date`; o BPT2 possui somente um ano numérico, portanto esse valor não será inventado como data.

## Escopo

- adicionar exatamente um bloco JSON-LD ao Vehicle Hub existente;
- usar `@context = https://schema.org` e `@type = Vehicle`;
- publicar somente dados canônicos visíveis: `name`, `url`, `brand`, `model`, `vehicleConfiguration` e, quando presente, `vehicleModelDate` somente se houver autoridade de data compatível — atualmente não há, então fica omitido;
- incluir `generation` apenas como `description`/campo genérico se houver semântica oficial inequívoca; na ausência disso, não inventar propriedade automotiva;
- serialização segura contra fechamento prematuro de `<script>`;
- estender o smoke HTTP existente do Vehicle Hub.

## Fora de escopo

- Offer/preço no Vehicle Hub;
- condição novo/usado;
- VIN, SKU, MPN, ratings/reviews;
- imagem canônica de Vehicle, pois o catálogo não possui esse ativo;
- inferir `Car` para todo Vehicle;
- transformar ano numérico em data;
- prometer rich result ou ganho de ranking;
- backend, migration, storage, search ou infraestrutura.

## Critérios de aceite

1. [ ] Vehicle Hub conhecido retorna 200 e exatamente um bloco JSON-LD válido.
2. [ ] JSON-LD usa `@context=https://schema.org` e `@type=Vehicle`.
3. [ ] `name`, `url`, `brand`, `model` e `vehicleConfiguration` correspondem aos dados canônicos visíveis.
4. [ ] Nenhum Offer, condition, VIN, rating/review, SKU/MPN ou imagem inventada é emitido.
5. [ ] Ano de modelo não é serializado como data sem autoridade semântica suficiente.
6. [ ] Vehicle Hub desconhecido continua 404/noindex e sem JSON-LD.
7. [ ] O bloco permanece presente quando não há oferta pública ativa e quando uma oferta é publicada/pausada.
8. [ ] Public Web e Public Buyer/Vehicle Hub gates ficam verdes sem mudança backend/schema.

## Decision log

- **DECIDIDO por evidência:** usar `Vehicle`, sem inferir subtipo `Car`.
- **DECIDIDO por evidência:** usar `vehicleConfiguration` para a Version canônica.
- **DECIDIDO por evidência:** não transformar `modelYear` inteiro em `vehicleModelDate`/`modelDate`, pois Schema.org tipa essas propriedades como `Date`.
- **DECIDIDO:** não emitir Offer no Hub canônico; ofertas permanecem representadas pelas páginas individuais de Listing.
- **NÃO DECIDIDO:** enriquecimento futuro de specs, imagem canônica e taxonomia de tipo de veículo.

## Progress log

- 2026-08-25: PR #51/Plan 0032 mergeado; `main` confirmado em `d610b0f0a5bd244da9e8504265f667e0e2416d95`.
- 2026-08-25: página `/veiculos/[id]` confirmada sem JSON-LD e com identidade canônica suficiente para um `Vehicle` mínimo.
- 2026-08-25: documentação Schema.org atual confirma `Vehicle` e `vehicleConfiguration`; propriedades de data de modelo permanecem `Date`, então o ano numérico do BPT2 não será convertido artificialmente.

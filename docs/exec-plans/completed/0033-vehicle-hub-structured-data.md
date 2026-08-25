# Execution Plan 0033 — Vehicle Hub Structured Data

Status: **COMPLETO**

## Objetivo

Adicionar dados estruturados server-rendered ao Vehicle Hub canônico usando somente a identidade automotiva já exibida na página.

Vertical proof:

`Canonical Vehicle → /veiculos/{id} SSR → schema.org Vehicle JSON-LD → identidade visível e URL canônica coerentes`

## Contexto

O `main` de partida foi `d610b0f0a5bd244da9e8504265f667e0e2416d95`, depois do merge do Plan 0032.

Evidência de partida:

- o Vehicle Hub já era uma página canônica pública, persistia sem oferta ativa e estava enumerado no sitemap completo;
- a página expunha Brand, Model, Generation opcional, Version e ModelYear opcional;
- não existia bloco `application/ld+json` no Vehicle Hub;
- Schema.org mantém `Vehicle` como subtipo de `Product` e define `vehicleConfiguration` para a configuração/versão do veículo;
- `vehicleModelDate`/`modelDate` exigem `Date`; o BPT2 possui somente um ano numérico, portanto esse valor não foi inventado como data.

## Escopo realizado

- exatamente um bloco JSON-LD no Vehicle Hub conhecido;
- `@context = https://schema.org` e `@type = Vehicle`;
- `name`, URL canônica, Brand, Model e `vehicleConfiguration` derivados da identidade canônica já visível;
- serialização segura de JSON em `<script>`;
- extensão do smoke HTTP existente do Vehicle Hub;
- nenhuma mudança backend, schema, migration, storage, search ou infraestrutura.

## Fora de escopo preservado

- Offer/preço no Vehicle Hub;
- condição novo/usado;
- VIN, SKU, MPN, ratings/reviews;
- imagem canônica de Vehicle, pois o catálogo não possui esse ativo;
- inferir `Car` para todo Vehicle;
- transformar ano numérico em data;
- prometer rich result ou ganho de ranking;
- geração como propriedade inventada de Schema.org.

## Critérios de aceite

1. [x] Vehicle Hub conhecido retorna 200 e exatamente um bloco JSON-LD válido.
2. [x] JSON-LD usa `@context=https://schema.org` e `@type=Vehicle`.
3. [x] `name`, `url`, `brand`, `model` e `vehicleConfiguration` correspondem aos dados canônicos visíveis.
4. [x] Nenhum Offer, condition, VIN, rating/review, SKU/MPN ou imagem inventada é emitido.
5. [x] Ano de modelo não é serializado como data sem autoridade semântica suficiente.
6. [x] Vehicle Hub desconhecido continua 404/noindex e sem JSON-LD.
7. [x] O bloco permanece presente quando não há oferta pública ativa e quando uma oferta é publicada/pausada.
8. [x] Public Web e Public Buyer/Vehicle Hub gates ficam verdes sem mudança backend/schema.

## Evidência executada

Head funcional: `e5552ecf7ef005f57ca640ac6892bfb6dc0dfa95`.

Public Buyer run `32855902160`, job `97827687663`:

- `VEHICLE_HUB_STRUCTURED_DATA_UNKNOWN_EXCLUDED: PASS`
- `VEHICLE_HUB_STRUCTURED_DATA: PASS`
- `VEHICLE_HUB_STRUCTURED_DATA_NO_INVENTED_FIELDS: PASS`
- `VEHICLE_HUB_STRUCTURED_DATA_WITH_OFFER: PASS`
- `VEHICLE_HUB_STRUCTURED_DATA_PERSISTS_WITHOUT_OFFER: PASS`
- `PUBLIC VEHICLE HUB HTTP: PASSED`

Regressões do mesmo job também passaram: unknown 404/noindex, identidade canônica, metadata, social metadata, Draft privado, Listing publicado visível, link Listing → Vehicle Hub, remoção após Pause, persistência do Hub sem oferta, SEO público, structured data de Listing e forwarding autenticado.

Os 9 workflows aplicáveis ao head funcional terminaram `success`:

- BPT2 Harness Gate;
- BPT2 Public Web Gate;
- BPT2 Public Buyer HTTP Gate;
- BPT2 Public Discovery HTTP Gate;
- BPT2 Buyer Favorites HTTP Gate;
- BPT2 Seller Auth HTTP Gate;
- BPT2 Seller Shell HTTP Gate;
- BPT2 Seller Draft Edit HTTP Gate;
- BPT2 Seller Photos Publish HTTP Gate.

Nenhuma correção funcional foi necessária depois do primeiro head de implementação.

## Decision log

- **DECIDIDO por evidência:** usar `Vehicle`, sem inferir subtipo `Car`.
- **DECIDIDO por evidência:** usar `vehicleConfiguration` para a Version canônica.
- **DECIDIDO por evidência:** não transformar `modelYear` inteiro em `vehicleModelDate`/`modelDate`, pois Schema.org tipa essas propriedades como `Date`.
- **DECIDIDO:** não emitir Offer no Hub canônico; ofertas permanecem representadas pelas páginas individuais de Listing.
- **DECIDIDO:** não inventar imagem, condição, VIN, ratings/reviews, SKU/MPN ou propriedade de geração.
- **NÃO DECIDIDO:** enriquecimento futuro de specs, imagem canônica e taxonomia de tipo de veículo.

## Progress log

- 2026-08-25: PR #51/Plan 0032 mergeado; `main` confirmado em `d610b0f0a5bd244da9e8504265f667e0e2416d95`.
- 2026-08-25: página `/veiculos/[id]` confirmada sem JSON-LD e com identidade canônica suficiente para um `Vehicle` mínimo.
- 2026-08-25: documentação Schema.org atual confirmou `Vehicle` e `vehicleConfiguration`; propriedades de data de modelo permanecem `Date`, então o ano numérico do BPT2 não foi convertido artificialmente.
- 2026-08-25: implementação adicionou exatamente um JSON-LD `Vehicle` ao Hub conhecido e preservou unknown 404/noindex sem structured data.
- 2026-08-25: smoke HTTP focal e todos os 9 workflows aplicáveis ficaram verdes no primeiro head funcional.

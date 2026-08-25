# Execution Plan 0032 — Vehicle Hub Sitemap Pagination

Status: **COMPLETO**

## Objetivo

Remover o limite estrutural que impedia o sitemap público de enumerar todos os Vehicle Hubs canônicos quando o Catalog possui mais de 100 Vehicles, sem criar nova fonte de verdade, migration ou infraestrutura.

Outcome vertical comprovado:

`Catalog paginado → sitemap percorre todos os Vehicles → /veiculos/{id} de todo Vehicle canônico é descobrível`

## Evidência que justificou o slice

- Plan 0015 já criou `/veiculos/{id}` como Hub público para qualquer `Vehicle` canônico existente, mesmo sem Listing publicado.
- `public-web/app/sitemap.ts` enumerava home + Listings públicos + Seller Hubs, mas não incluía Vehicle Hubs.
- `IVehicleCatalogAppService.GetListAsync` aceitava `take`, mas não `skip`.
- `VehicleCatalogReader.SearchAsync` aplicava `Take(Math.Clamp(take, 1, 100))`, então um consumidor público não conseguia percorrer deterministicamente além dos primeiros 100 Vehicles.
- Plan 0031 registrou explicitamente esse limite ao adiar o sitemap de Vehicle Hub.

## Escopo entregue

- `skip` opcional adicionado ao contrato público e ao reader do Catalog sem quebrar chamadas existentes;
- `take` continua limitado a 100 e `skip` negativo é normalizado para zero;
- ordenação pública agora termina em `Id` como desempate e só então aplica `Skip`/`Take`;
- `public-web/lib/catalog.ts` ganhou `getVehicleCatalogPage`;
- o sitemap percorre páginas do Catalog até uma página curta e deduplica `VehicleId`;
- cada Vehicle canônico recebe `/veiculos/{id}` no sitemap independentemente de existir oferta pública;
- o smoke SEO existente foi ampliado para criar 101 Vehicles canônicos adicionais, provar duas páginas não sobrepostas e confirmar um Vehicle da segunda página no sitemap;
- nenhum workflow novo, migration, schema ou infraestrutura foi introduzido.

## Fora de escopo preservado

- slugs semânticos;
- sitemap index/sharding por 50 mil URLs;
- enrichment de Vehicle Hub;
- JSON-LD do Vehicle Hub;
- autocomplete/facets do Catalog;
- mudar filtros/ordenação de descoberta de Listings;
- migration/schema/engine externa.

## Critérios de aceite

1. [x] listagem pública do Catalog aceita `skip >= 0` e mantém limite máximo de página em 100;
2. [x] paginação é aplicada depois da ordenação determinística Brand → Model → ModelYear → Version → Id;
3. [x] chamadas existentes sem `skip` preservam o comportamento atual;
4. [x] public web percorre páginas do Catalog até página curta;
5. [x] sitemap inclui `/veiculos/{id}` para Vehicle canônico sem exigir Listing publicado;
6. [x] um Vehicle após o primeiro lote de 100 também entra no sitemap;
7. [x] sitemap preserva home, Listings públicos e Seller Hubs e não duplica a Vehicle URL focal;
8. [x] nenhuma migration/schema ou infraestrutura nova foi criada;
9. [x] gate focal e todas as regressões aplicáveis ficaram verdes no head funcional.

## Evidência executada

Head funcional `23308ebe832a81dffde61c384be0313484ddd314`:

- `BPT2 Public Buyer HTTP Gate` run `32853550973`: **success**;
  - `PUBLIC_SEO_VEHICLE_CATALOG_PAGINATION: PASS` — primeira página retornou 100, segunda página não vazia e sem interseção de IDs;
  - `PUBLIC_SEO_VEHICLE_HUB_SECOND_PAGE_IN_SITEMAP: PASS` — Vehicle criado e posicionado após o primeiro lote apareceu exatamente uma vez no sitemap;
  - `PUBLIC_SEO_VEHICLE_HUB_WITHOUT_OFFER: PASS` — esse Hub respondeu 200 mesmo sem Listing;
  - `PUBLIC_SEO_VEHICLE_HUB_STABLE_WITH_OFFER: PASS` — publicação de Listings não alterou a identidade do Hub no sitemap;
  - `PUBLIC_SEO_VEHICLE_HUB_PERSISTS_WITHOUT_OFFER: PASS` — após remover a última oferta pública focal, o Vehicle Hub canônico permaneceu no sitemap;
  - regressões de Buyer, Seller Hub, Vehicle Hub, structured data e forwarding também passaram na mesma execução.
- `BPT2 Public Web Gate` run `32853551430`: **success**, incluindo lint, typecheck e production build.
- Os **16 workflows aplicáveis** concluíram com **success** no mesmo head: Host, Product API, Harness, Architecture, Public Web, Fresh Migration, Gate 01, Seller Auth, Admin Canonical Catalog, Seller Shell, Seller Draft Edit, Listing Lifecycle, Seller Photos Publish, Public Discovery, Buyer Favorites e Public Buyer.
- Fresh Migration permaneceu verde, confirmando ausência de mudança de schema.

## Self-review

- diff restrito a contratos/read path do Catalog, sitemap/public-web, smoke SEO e documentação do plano;
- nenhuma autorização foi relaxada e o Catalog continua `[AllowAnonymous]` somente para leitura;
- nenhum dado de Listing passou a controlar a existência do Vehicle Hub no sitemap;
- o loop do sitemap termina por página curta; o smoke prova que `skip` é realmente aplicado antes de executar a enumeração SSR;
- nenhuma nova dependência, workflow, migration ou infraestrutura foi adicionada.

## Decision log

- **DECIDIDO por evidência do código:** paginação offset é suficiente para destravar enumeração completa do Catalog; cursor/paged DTO não é necessário neste slice.
- **DECIDIDO:** manter `take` limitado a 100 e introduzir `skip` não negativo, preservando a proteção de volume existente.
- **DECIDIDO:** adicionar `Id` como último desempate explícito à ordenação da página para garantir fronteiras determinísticas entre páginas.
- **DECIDIDO:** todo Vehicle canônico existente é elegível ao sitemap porque o Vehicle Hub existe mesmo sem oferta ativa; visibilidade de Listings dentro do Hub continua sendo decidida pela projeção pública.
- **DECIDIDO:** reutilizar o smoke SEO existente evita workflow/build paralelo desnecessário e testa a integração no ponto em que o sitemap já era provado.
- **NÃO DECIDIDO:** sitemap index/sharding e slug final permanecem posteriores a evidência de escala real.

## Progress log

- 2026-08-25: Plan 0031 mergeado em `main` no commit `53b5451e9d245d972ae1ade5a134298b8404d41e`.
- 2026-08-25: `main` refetchado e confirmado nesse commit antes do novo slice.
- 2026-08-25: selecionado o gap registrado no Plan 0031: Catalog limitava listagem a 100 e não expunha `skip`, impedindo sitemap completo de Vehicle Hubs.
- 2026-08-25: paginação determinística, helper público, sitemap e prova >100 implementados sem migration/workflow novo.
- 2026-08-25: todos os 16 workflows aplicáveis passaram no head funcional; self-review não encontrou mudança fora de escopo.
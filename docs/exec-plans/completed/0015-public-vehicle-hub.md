# Execution Plan 0015 — Public Vehicle Hub

Status: **COMPLETO**

## Objetivo

Abrir a primeira fatia real de Vehicle Hub reutilizando integralmente o catálogo canônico e a busca pública já existentes:

`Listing público → Vehicle canônico → Hub público do Vehicle → Listings publicados desse Vehicle`

## Evidência que abriu o slice

- `PRODUCT.md` mantém Vehicle Hub como capacidade central.
- Catalog já modelava `Brand → Model → Generation → Version → Vehicle` e `VehicleRefDto` já projetava essa identidade.
- `IVehicleCatalogAppService.GetAsync(id)` já expunha o Vehicle canônico por HTTP.
- `PublicListingSearchInput.VehicleId` e `PublicListingQuery` já filtravam Listings públicos pelo Vehicle exato.
- o public web já possuía SSR, metadata/canonical, cards de Listing e helper de busca pública.
- Promoções não possuía aggregate/contrato equivalente já modelado; este Hub mínimo exigia menos decisão nova e nenhuma infraestrutura adicional.

## Escopo entregue

- helper read-only `getVehicle` no public web consumindo o Catalog HTTP existente;
- `/veiculos/[id]` SSR como primeira URL pública estável de um Vehicle canônico;
- identidade renderizada exclusivamente de `VehicleRefDto`: Brand, Model, Generation opcional, Version e ModelYear opcional;
- disponibilidade comercial derivada de `getPublicListings({ vehicleId })`, sem duplicar regra de status no frontend;
- detalhe público de Listing ligado ao Hub do `vehicleId` canônico;
- metadata com title, canonical absoluto e index/follow para Vehicle existente; id inexistente retorna 404/noindex;
- paginação mínima da disponibilidade por `skip`/`take` existentes;
- prova HTTP real integrada ao Public Buyer HTTP Gate existente.

## Fora de escopo

- specs técnicas, equipamentos, segurança, consumo, preço de mercado, editorial ou imagens enriquecidas ainda não modelados;
- páginas agregadas por Brand/Model/Generation/Version;
- sitemap de todo o catálogo;
- reviews, comparativos, FIPE, histórico, scoring ou conteúdo editorial;
- promoções;
- mudança de schema, migration, módulo, cache, search engine ou infraestrutura nova.

## Critérios de aceite

- [x] `/veiculos/{vehicleId}` retorna 200 para Vehicle canônico existente e 404 para id inexistente;
- [x] Hub mostra somente identidade proveniente do Catalog canônico;
- [x] detalhe de Listing publicado contém link para o Hub do seu `vehicleId`;
- [x] Listing Draft não aparece no Hub;
- [x] Listing Published do Vehicle aparece no Hub com link ao detalhe;
- [x] após Pause, o Listing deixa de aparecer no Hub;
- [x] o Hub do Vehicle continua 200 depois do Pause;
- [x] metadata inclui title/canonical absoluto do Hub existente e id inexistente é noindex;
- [x] build e nove workflows aplicáveis passaram no head funcional antes do reforço final de metadata;
- [x] docs fecham somente a fatia comprovada, sem transformar enrichment futuro em requisito.

## Evidência executada

Head funcional com o primeiro conjunto completo de assertions: `331a1a47da9796f86a5b808f623319211e5788cd`.

`BPT2 Public Buyer HTTP Gate`, run `32733933203`, job `97452242474`, em PostgreSQL fresco, host ABP real e Next.js de produção:

- `VEHICLE_HUB_UNKNOWN_404: PASS`
- `VEHICLE_HUB_CANONICAL_IDENTITY: PASS`
- `VEHICLE_HUB_DRAFT_PRIVATE: PASS`
- `VEHICLE_HUB_PUBLISHED_VISIBLE: PASS`
- `VEHICLE_HUB_LINKED_FROM_LISTING: PASS`
- `VEHICLE_HUB_PAUSE_REMOVES_LISTING: PASS`
- `VEHICLE_HUB_PERSISTS_WITHOUT_OFFER: PASS`
- `PUBLIC VEHICLE HUB HTTP: PASSED`

O mesmo run preservou verdes o Public Buyer flow, SEO público, authenticated Lead forwarding, fresh database e builds Release com 0 warnings/0 errors. No mesmo head, os nove workflows aplicáveis concluíram `success`: Harness, Public Web, Public Buyer, Public Discovery, Buyer Favorites, Seller Auth, Seller Draft/Edit, Seller Shell e Seller Photos/Publish.

O self-review adicionou duas assertions finais ao smoke (`VEHICLE_HUB_UNKNOWN_NOINDEX` e `VEHICLE_HUB_METADATA`) para tornar o critério de metadata inteiramente mecânico; readiness de merge deve usar o CI fresco do head documental final que contém essas assertions.

Classe da evidência: **B — comportamento observado/reproduzido no CI do BPT2**.

## Progress log

- 2026-08-24: `main` remoto confirmado em `4057a770c77d42146a7679d103846a9ec009699d` após o fechamento do Plan 0014.
- 2026-08-24: auditoria encontrou Catalog e busca pública já capazes de fornecer o primeiro Hub por composição, sem backend/schema novos; Promoções não tinha implementação parcial equivalente.
- 2026-08-24: branch `feat/public-vehicle-hub` e draft PR #34 abertos; helper Catalog, rota `/veiculos/[id]`, link no detalhe e smoke HTTP focal adicionados.
- 2026-08-24: Public Web Gate passou no primeiro head funcional; Harness falhou somente por ausência da seção obrigatória `Progress log`, corrigida sem mudança funcional.
- 2026-08-24: head `331a1a47...` fechou 9/9 workflows aplicáveis verdes e o smoke focal passou integralmente.
- 2026-08-24: self-review reforçou a prova de metadata/noindex antes do fechamento documental final.

## Decision log

- **DECIDIDO:** identidade do Hub é o `Vehicle` canônico por `id`; não há cópia de dados automotivos no Marketplace/public web.
- **DECIDIDO:** disponibilidade comercial é derivada da projeção pública existente filtrada por `VehicleId`; Draft/Pause/Archive continuam invisíveis estruturalmente.
- **DECIDIDO:** a primeira URL é `/veiculos/{id}` para não inventar slug policy antes de haver necessidade.
- **NÃO DECIDIDO:** enrichment, páginas agregadas, slug final, sitemap completo do catálogo e conteúdo editorial.

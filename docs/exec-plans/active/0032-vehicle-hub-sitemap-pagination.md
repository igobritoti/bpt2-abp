# Execution Plan 0032 — Vehicle Hub Sitemap Pagination

Status: **ATIVO**

## Objetivo

Remover o limite estrutural que impede o sitemap público de enumerar todos os Vehicle Hubs canônicos quando o Catalog possui mais de 100 Vehicles, sem criar nova fonte de verdade, migration ou infraestrutura.

Outcome vertical esperado:

`Catalog paginado → sitemap percorre todos os Vehicles → /veiculos/{id} de todo Vehicle canônico é descobrível`

## Evidência que justifica o slice

- Plan 0015 já criou `/veiculos/{id}` como Hub público para qualquer `Vehicle` canônico existente, mesmo sem Listing publicado.
- `public-web/app/sitemap.ts` atualmente enumera home + Listings públicos + Seller Hubs, mas não inclui Vehicle Hubs.
- `IVehicleCatalogAppService.GetListAsync` aceita `take`, mas não aceita `skip`.
- `VehicleCatalogReader.SearchAsync` aplica `Take(Math.Clamp(take, 1, 100))`, portanto um consumidor público não consegue percorrer deterministicamente além dos primeiros 100 Vehicles.
- Plan 0031 registrou explicitamente esse limite ao adiar o sitemap de Vehicle Hub.

## Escopo

- adicionar paginação offset determinística à listagem pública do Catalog preservando compatibilidade dos consumidores atuais;
- aplicar `Skip` antes do `Take` sobre a ordenação canônica já existente;
- expor helper no public web para listar páginas do Catalog;
- fazer o sitemap percorrer todas as páginas de Vehicles e emitir uma URL `/veiculos/{id}` por identidade canônica;
- manter home, Listings públicos e Seller Hubs existentes;
- adicionar prova HTTP focal de que Vehicles além da primeira página entram no sitemap e Vehicle inexistente não é inventado.

## Fora de escopo

- slugs semânticos;
- sitemap index/sharding por 50 mil URLs;
- enrichment de Vehicle Hub;
- JSON-LD do Vehicle Hub;
- autocomplete/facets do Catalog;
- mudar filtros/ordenação de descoberta de Listings;
- migration/schema/engine externa.

## Critérios de aceite

1. [ ] listagem pública do Catalog aceita `skip >= 0` e mantém limite máximo de página em 100;
2. [ ] paginação é aplicada depois da ordenação determinística Brand → Model → ModelYear → Version → Id;
3. [ ] chamadas existentes sem `skip` preservam o comportamento atual;
4. [ ] public web consegue percorrer páginas do Catalog até página vazia/curta;
5. [ ] sitemap inclui `/veiculos/{id}` para Vehicle canônico sem exigir Listing publicado;
6. [ ] um Vehicle após o primeiro lote de 100 também entra no sitemap;
7. [ ] sitemap preserva home, Listings públicos e Seller Hubs existentes sem duplicar Vehicle URL;
8. [ ] nenhuma migration/schema ou infraestrutura nova é criada;
9. [ ] gates focais e regressões aplicáveis ficam verdes no head final.

## Decision log

- **DECIDIDO por evidência do código:** paginação offset é suficiente para destravar enumeração completa do Catalog; cursor/paged DTO não é necessário neste slice.
- **DECIDIDO:** manter `take` limitado a 100 e introduzir `skip` não negativo, preservando a proteção de volume existente.
- **DECIDIDO:** adicionar `Id` como último desempate explícito à ordenação da página para garantir fronteiras determinísticas entre páginas.
- **DECIDIDO:** todo Vehicle canônico existente é elegível ao sitemap porque o Vehicle Hub existe mesmo sem oferta ativa; visibilidade de Listings dentro do Hub continua sendo decidida pela projeção pública.
- **NÃO DECIDIDO:** sitemap index/sharding e slug final permanecem posteriores a evidência de escala real.

## Progress log

- 2026-08-25: Plan 0031 mergeado em `main` no commit `53b5451e9d245d972ae1ade5a134298b8404d41e`.
- 2026-08-25: `main` refetchado e confirmado nesse commit antes do novo slice.
- 2026-08-25: selecionado o gap registrado no Plan 0031: Catalog limita listagem a 100 e não expõe `skip`, impedindo sitemap completo de Vehicle Hubs.

# Plan 0053 — Public canonical vehicle selector

Status: **ATIVO**

## Objetivo

Fechar o gap documentado de seleção guiada de veículo na descoberta pública sem duplicar taxonomia automotiva no frontend: o Buyer pesquisa por identidade canônica de catálogo e a busca pública recebe `VehicleId` como valor semântico.

## Evidência de base

- `PublicListingSearch` já aceita `VehicleId` e a home preserva esse valor na query string/Saved Search.
- `VehicleRefDto` já publica `Id`, Brand, Model, Generation, Version e ModelYear.
- `VehicleCatalogAppService` já é público e paginado.
- `VehicleCatalogReader.FindIdsByTextAsync` já define busca textual case-insensitive por Brand/Model/Generation/Version.
- `VehicleCatalogSearchInput` ainda não expõe texto canônico para o endpoint paginado; a UI pública, portanto, não consegue oferecer seleção guiada escalável sem carregar catálogo inteiro.

## Boundary

Entregar no mesmo slice:

1. adicionar `Query` opcional a `VehicleCatalogSearchInput`;
2. aplicar em `SearchAsync` a mesma semântica textual já usada pelo reader: trim + case-insensitive substring sobre Brand/Model/Generation/Version;
3. manter paginação determinística e limite máximo atual;
4. expor proxy server-side no public web para não acoplar o componente cliente à URL interna do host;
5. oferecer autocomplete/listbox acessível que grava somente `vehicleId` no formulário;
6. resolver o rótulo do `vehicleId` já presente na URL para refresh/paginação;
7. provar por smoke que busca canônica retorna o veículo fixture e que o formulário envia/preserva `vehicleId`.

## Não objetivos

- fuzzy search, sinônimos ou ranking inventado;
- dropdown limitado à primeira página do catálogo;
- alteração da identidade canônica ou do Podium;
- remoção dos filtros textuais Brand/Model existentes;
- mudança de Saved Search além de reutilizar o `VehicleId` já suportado.

## Decision log

- Reutilizar `VehicleId` como único valor semântico selecionado; labels de Brand/Model/Generation/Version/ModelYear são apresentação.
- Reutilizar a semântica textual já existente no `VehicleCatalogReader`, sem criar fuzzy search, synonyms ou ranking.
- Manter `take`/`skip` e o limite máximo de 100 no endpoint atual; autocomplete usa somente os 12 primeiros resultados do query.
- Usar proxy server-side do Next para o componente cliente não depender diretamente da URL interna do host ABP.
- Manter Brand/Model e busca textual geral existentes; o seletor canônico é uma opção adicional, não uma substituição neste slice.

## Critérios de aceite

- [ ] catálogo paginado aceita `query` sem quebrar Brand/Model/year existentes;
- [ ] query encontra Brand, Model, Generation e Version pela semântica existente;
- [ ] UI pública permite selecionar um resultado canônico e submete seu `VehicleId`;
- [ ] seleção atual sobrevive refresh/paginação via `vehicleId`;
- [ ] limpar seleção remove `vehicleId` sem afetar outros filtros;
- [ ] public-web build e smoke de discovery passam no head exato;
- [ ] documentação de produto e current-work refletem o estado final.

## Progress log

- 2026-08-27 — Plan aberto sobre `main` `f3e4d5a36aa29baba0ec969a301e2903fa1f9e42`.
- 2026-08-27 — `VehicleCatalogSearchInput.Query`, busca paginada por identidade, proxy Next, combobox público e smoke HTTP focado implementados.
- 2026-08-27 — PR #92 aberto draft; primeiro Harness Gate falhou apenas por seções canônicas ausentes neste plan e facts gerados ainda indicando zero planos ativos. Nenhuma falha funcional foi reportada nesse gate.

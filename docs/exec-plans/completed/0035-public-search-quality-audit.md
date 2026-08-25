# Execution Plan 0035 — Public Search Quality Audit

Status: **COMPLETO**

## Objetivo

Auditar a jornada pública principal de descoberta depois do Plan 0034 e selecionar, por evidência do repositório atual, o próximo gap pós-MVP pequeno e vertical.

Jornada auditada:

`Home → busca/filtros → resultados/paginação → detalhe público`

## Contexto

Base remota verificada: `c5957514a9af3bf7d46466e58bb80c49810f9e0f`, merge do PR #53 / Plan 0034.

## Critérios de aceite

1. [x] busca/filtros principais confrontados com o smoke existente;
2. [x] paginação/deep-link confrontados com o smoke existente;
3. [x] zero-results confrontado com a prova existente;
4. [x] candidatos pós-MVP explícitos do Plan 0027 não foram promovidos sem evidência nova;
5. [x] a auditoria concluiu que nenhum slice adicional é justificado nesta superfície.

## Resultado

| Comportamento | Evidência | Resultado |
|---|---|---|
| Busca por título | Public Discovery | PASSA |
| Busca por Brand/Model/Generation/Version | Plan 0034 + Public Discovery | PASSA |
| Case-insensitive + substring | Public Discovery | PASSA |
| Filtros Brand/Model/ano | Public Discovery | PASSA |
| City/StateCode | Public Discovery | PASSA |
| Preço | Public Discovery | PASSA |
| Quilometragem e limites | Public Discovery | PASSA |
| Filtros combinados | Public Discovery | PASSA |
| Draft excluído | Public Discovery | PASSA |
| Paginação | Public Discovery | PASSA |
| Preservação de parâmetros no link da próxima página | Public Discovery inspeciona query string do href | PASSA |
| Price sort | Plan 0030 + Public Discovery | PASSA |
| Zero resultados com filtros ativos | Public Discovery prova ranges inválidos de mileage e price com `0 anúncio(s)` + `Nenhum anúncio encontrado.` | PASSA |
| Facets/autocomplete/ranking/search externo | Plan 0027 mantém como pós-MVP e não apareceu evidência nova | DECIDIDO: não promover |

## Correção de hipótese durante a auditoria

A leitura inicial do começo de `scripts/public-discovery-http-smoke.sh` sugeriu ausência de prova dedicada de zero-results. A leitura completa do gate invalidou essa hipótese:

- `minMileageKm=50000` + `maxMileageKm=10000` exige `0 anúncio(s)` e `Nenhum anúncio encontrado.`;
- `minPrice=350000` + `maxPrice=150000` exige o mesmo estado vazio filtrado.

Pela regra epistemológica do projeto, a evidência executável prevalece sobre a inferência inicial.

## Decisão

**Nenhum novo slice de public discovery é justificado agora.**

Não criar Plan 0036 para zero-results, paginação, combinação de filtros, price sort ou busca textual: todos já possuem prova suficiente no gate atual.

A próxima escolha pós-MVP deve sair de outra área explicitamente ainda adiável no Plan 0027 e precisa ser promovida somente quando houver evidência adicional de valor/gap real.

## Fora de escopo mantido

- fuzzy search;
- autocomplete;
- facets;
- ranking por relevância;
- search engine externo;
- redesign da home;
- performance tuning sem falha observada.

## Decision log

- **DECIDIDO por evidência:** discovery público atual não possui gap de prova material identificado nesta auditoria.
- **DECIDIDO por evidência:** zero-results já é provado por HTTP; hipótese inicial rejeitada.
- **DECIDIDO:** facets/autocomplete/ranking/search externo continuam pós-MVP.
- **NÃO DECIDIDO:** qual área pós-MVP fora de discovery merece o próximo slice; deve ser escolhida por nova auditoria/evidência, não por preferência.

## Progress log

- 2026-08-25: PR #53 mergeado e `main` confirmado em `c5957514a9af3bf7d46466e58bb80c49810f9e0f`.
- 2026-08-25: home confrontada com Public Discovery smoke.
- 2026-08-25: leitura completa do smoke encontrou prova já existente de zero-results em ranges inválidos de mileage e price.
- 2026-08-25: auditoria encerrada sem promover feature nova por ausência de gap material nesta superfície.

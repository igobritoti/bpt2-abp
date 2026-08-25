# Execution Plan 0035 — Public Search Quality Audit

Status: **ATIVO**

## Objetivo

Auditar a jornada pública principal de descoberta depois do Plan 0034 e selecionar, por evidência do repositório atual, o próximo gap pós-MVP pequeno e vertical.

Jornada observada:

`Home → busca/filtros → resultados/paginação → detalhe público`

## Contexto

Base remota verificada: `c5957514a9af3bf7d46466e58bb80c49810f9e0f`, merge do PR #53 / Plan 0034.

Evidência atual:

- `public-web/app/page.tsx` expõe busca livre, Brand, Model, City, StateCode, ano, quilometragem, preço, sort e paginação;
- `scripts/public-discovery-http-smoke.sh` já prova formulário, filtros combinados, paginação com preservação de query, busca por título, Brand/Model/Generation/Version, case-insensitive substring, Draft excluído e price sort;
- `public-web/app/page.tsx` possui dois estados vazios explícitos: nenhum anúncio publicado e nenhum anúncio encontrado com filtros ativos;
- o smoke atual não possui uma asserção dedicada ao estado de zero resultados;
- o Plan 0027 mantém facets, autocomplete, ranking avançado e search engine externo como pós-MVP sem evidência nova para promovê-los.

## Escopo

- confrontar comportamentos públicos já expostos pela UI com provas HTTP existentes;
- classificar cada candidato como `PASSA`, `NÃO PASSA`, `DECIDIDO` ou `NÃO DECIDIDO`;
- escolher somente um próximo slice vertical quando existir gap comprovado;
- evitar teste duplicado quando o comportamento já estiver coberto por smoke atual.

## Fora de escopo

- implementar feature funcional neste plano;
- fuzzy search, autocomplete, facets, ranking por relevância ou search engine externo;
- redesign da home;
- performance tuning sem evidência de falha;
- criar infraestrutura nova.

## Critérios de aceite

1. [ ] busca/filtros principais confrontados com o smoke existente;
2. [ ] paginação/deep-link confrontados com o smoke existente;
3. [ ] zero-results confrontado com a prova existente;
4. [ ] candidatos pós-MVP explícitos do Plan 0027 não são promovidos sem evidência nova;
5. [ ] exatamente um próximo gap é escolhido, ou a auditoria conclui que nenhum slice adicional é justificado nesta superfície.

## Matriz inicial

| Comportamento | Evidência atual | Estado inicial |
|---|---|---|
| Busca por título + identidade canônica | Plan 0034 + Public Discovery verde | PASSA |
| Filtros exatos combinados | Public Discovery | PASSA |
| Paginação preservando parâmetros | Public Discovery valida href da próxima página | PASSA |
| Ordenação por preço | Plan 0030 + Public Discovery | PASSA |
| Draft excluído | Public Discovery | PASSA |
| Zero resultados com filtros ativos | UI implementada, sem asserção dedicada no smoke | NÃO PASSA como prova |
| Facets/autocomplete/ranking/search externo | Explicitamente pós-MVP no Plan 0027 | DECIDIDO: não promover |

## Hipótese de próximo slice

Candidato atual: provar por HTTP o estado público de zero resultados, incluindo contagem `0 anúncio(s)`, mensagem de nenhum resultado e ausência de fallback/leak de Listings fora do filtro.

Essa hipótese só vira próximo execution plan depois do fechamento desta auditoria.

## Decision log

- **DECIDIDO por evidência:** não reabrir busca, filtros, paginação ou price sort já cobertos por smokes verdes.
- **DECIDIDO por evidência:** facets/autocomplete/ranking/search externo continuam fora da próxima boundary.
- **NÃO DECIDIDO:** se zero-results merece slice próprio; confirmar que não existe prova equivalente em outro gate antes de fechar o plano.

## Progress log

- 2026-08-25: PR #53 mergeado; `main` confirmado em `c5957514a9af3bf7d46466e58bb80c49810f9e0f`.
- 2026-08-25: leitura de `public-web/app/page.tsx` confirmou estado vazio explícito para filtros ativos.
- 2026-08-25: leitura do Public Discovery smoke confirmou cobertura de filtros/paginação/query/sort e ausência de asserção dedicada ao zero-results no trecho auditado.

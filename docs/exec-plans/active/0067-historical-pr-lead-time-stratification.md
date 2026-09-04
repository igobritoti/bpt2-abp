# Plan 0067 — Historical PR lead-time stratification

Status: **ATIVO**

## Objetivo / outcome

Medir uma variável operacional ainda ausente na decisão monorepo vs split: o lead time observado dos PRs históricos reais do BPT2, estratificado pela mesma classificação de mudança usada no Plan 0062 (`backend_only`, `frontend_only`, `cross_boundary`).

O estudo mede associação no monorepo atual. Ele **não** estima causalmente o lead time de dois repositórios e não autoriza claim de que split seria melhor ou pior.

## Contexto congelado antes dos resultados

- `main` de origem: `f18337003f92885a1ec4abba7c9c3873d8ac7afb`;
- população de commits: os mesmos 100 commits first-parent do baseline 0062, congelados em `53be795b6205ef57c03f1118e0c0287dc0f2873c`;
- classificação de paths idêntica ao 0062:
  - backend: `main/**`, `modules/**`, `tests/**`;
  - frontend: `public-web/**`;
  - shared/control-plane não define sozinho commit de produto;
- denominador de produto esperado do 0062: 49 commits (`25 backend_only`, `11 frontend_only`, `13 cross_boundary`).

## Perguntas e métricas pré-declaradas

RQ1. Qual o lead time `merged_at - created_at` dos PRs associados aos commits de produto da população congelada?

RQ2. A distribuição de lead time dos PRs `cross_boundary` difere materialmente da distribuição dos PRs single-boundary (`backend_only + frontend_only`)?

RQ3. Qual a diferença de mediana, razão de medianas e Cliff's delta entre `cross_boundary` e single-boundary?

Métricas: número de commits resolvidos para PR, lead time em horas, mediana, Q1/Q3, razão de medianas, diferença de medianas e Cliff's delta. Também serão preservados PR number, timestamps, classificação e commit SHA no artifact.

## Desenho experimental pré-declarado

- usar **todos** os commits de produto da população congelada;
- resolver PR associado via API GitHub `commits/{sha}/pulls`;
- se um commit tiver múltiplos PRs associados, registrar ambiguidade e excluir do comparativo principal;
- se um commit não resolver para PR, registrar missing e não imputar tempo;
- single-boundary = `backend_only + frontend_only` para a comparação principal; categorias individuais também serão reportadas;
- estatística descritiva robusta: mediana e quartis;
- effect size não paramétrico: Cliff's delta calculado diretamente, sem hipótese de normalidade;
- nenhum threshold será redefinido após observar os dados.

## Regras de decisão pré-declaradas

- menos de 8 PRs resolvidos em `cross_boundary` ou menos de 16 em single-boundary: evidência insuficiente para comparação principal;
- razão de medianas entre 0,80 e 1,25 **e** |Cliff's delta| < 0,33: sem diferença operacional material demonstrada neste histórico;
- mediana `cross_boundary >= 1,50x` single-boundary **e** Cliff's delta >= 0,33: associação operacional relevante entre mudança cross-boundary e lead time maior no monorepo atual;
- mediana `cross_boundary <= 0,67x` single-boundary **e** Cliff's delta <= -0,33: associação operacional relevante na direção oposta;
- resultados entre esses limites são inconclusivos/trade-off;
- mesmo resultado forte continua sendo associação observacional e **não** prova causalidade arquitetural nem prediz automaticamente split multi-repo.

## Threats to validity

- lead time inclui fila humana, review, disponibilidade e prioridade, não apenas esforço técnico;
- squash merge e associação commit→PR dependem dos metadados preservados pelo GitHub;
- população é histórica e pequena;
- PR lead time pode ser afetado por tamanho, urgência e época do projeto;
- comparar categorias no mesmo repositório não é um experimento causal de arquitetura.

## Progress log

- 2026-09-03: protocolo pré-registrado antes de consultar lead times dos PRs da população.

## Decision log

- 2026-09-03: reutilizar exatamente a população/classificação do 0062 evita seleção posterior de casos.
- 2026-09-03: usar mediana + Cliff's delta reduz dependência de normalidade e evita tratar outliers de calendário como média representativa.
- 2026-09-03: qualquer conclusão será limitada ao monorepo histórico observado.

## Critérios de aceite

- protocolo registrado antes dos resultados;
- população congelada reproduzida exatamente;
- artifact machine-readable com resolução commit→PR;
- missing/ambiguous explícitos, sem imputação;
- interpretação contra thresholds pré-declarados;
- plano arquivado após resultado;
- checks/review verdes no head final.

# Plan 0067 — Historical PR lead-time stratification

Status: **CONCLUÍDO**

## Objetivo / outcome

Medir uma variável operacional ainda ausente na decisão monorepo vs split: o lead time observado dos PRs históricos reais do BPT2, estratificado pela mesma classificação de mudança usada no Plan 0062 (`backend_only`, `frontend_only`, `cross_boundary`).

O estudo mede associação no monorepo atual. Ele **não** estima causalmente o lead time de dois repositórios e não autoriza claim de que split seria melhor ou pior.

## Contexto congelado antes dos resultados

- `main` de origem: `f18337003f92885a1ec4abba7c9c3873d8ac7afb`;
- população de commits: os mesmos 100 commits first-parent do baseline 0062, congelados em `53be795b6205ef57c03f1118e0c0287dc0f2873c`;
- classificação de paths idêntica ao 0062;
- população esperada: 49 commits de produto (`25 backend_only`, `11 frontend_only`, `13 cross_boundary`).

## Regras de decisão pré-declaradas

- menos de 8 PRs resolvidos em `cross_boundary` ou menos de 16 em single-boundary: evidência insuficiente;
- razão de medianas entre 0,80 e 1,25 e |Cliff's delta| < 0,33: sem diferença operacional material demonstrada;
- mediana `cross_boundary >= 1,50x` single-boundary e Cliff's delta >= 0,33: associação operacional relevante com lead time maior;
- mediana `cross_boundary <= 0,67x` single-boundary e Cliff's delta <= -0,33: associação operacional relevante na direção oposta;
- resultados entre limites: inconclusivos/trade-off;
- nenhuma regra autoriza inferência causal sobre split multi-repo.

## Execução

Run autoritativo inicial: `33825785595`.
Head medido: `9c3e0edfd3158a23797237b0e886be28f4cf1c65`.
Artifact id: `9919890957`.
Artifact SHA-256: `afc4a936917ca0b4b94dfcfbfee101cd3f12a49f90e1365b8c517e8d0a9a25b1`.

A população foi reproduzida exatamente: **25 backend-only, 11 frontend-only, 13 cross-boundary**.

Resolução commit→PR:

- resolvidos: **48/49**;
- missing: **1**;
- ambiguous: **0**;
- o commit missing foi `eaf2a49b88453f751782fb2a5bc49f4170fe38f8`, classificado como `cross_boundary`; nenhum tempo foi imputado.

## Resultados

### Backend-only

- n: **25**;
- mediana: **0,326 h**;
- Q1: **0,097 h**;
- Q3: **0,661 h**;
- faixa observada: **0,004–7,021 h**.

### Frontend-only

- n: **11**;
- mediana: **0,291 h**;
- Q1: **0,248 h**;
- Q3: **0,602 h**;
- faixa observada: **0,074–1,632 h**.

### Cross-boundary

- n: **12**;
- mediana: **0,563 h**;
- Q1: **0,372 h**;
- Q3: **1,037 h**;
- faixa observada: **0,036–4,917 h**.

### Comparação principal: cross-boundary vs single-boundary

- single-boundary n: **36**;
- mediana single-boundary: **0,306 h**;
- mediana cross-boundary: **0,563 h**;
- diferença de medianas: **+0,257 h** (~15,4 min);
- razão de medianas: **1,841x**;
- Cliff's delta: **+0,343**;
- decisão pré-registrada: **`cross_boundary_higher_association`**.

## Interpretação contra thresholds

Os dois critérios pré-registrados para associação relevante na direção de lead time maior foram satisfeitos simultaneamente:

- razão de medianas **1,841x >= 1,50x**;
- Cliff's delta **0,343 >= 0,33**.

Portanto, nesta população histórica do BPT2, mudanças `cross_boundary` estiveram associadas a lead time de PR maior do que mudanças single-boundary no monorepo atual.

Essa diferença é observacional e de pequena escala absoluta em horas. O estudo não separa tempo técnico de fila humana, revisão, prioridade ou urgência. Também não mede o contrafactual multi-repo; logo, **não** demonstra que separar os repositórios aumentaria ou reduziria lead time.

## Threats to validity

- lead time inclui fila humana, review, disponibilidade e prioridade, não apenas esforço técnico;
- squash merge e associação commit→PR dependem dos metadados preservados pelo GitHub;
- população é histórica e pequena;
- um commit cross-boundary não resolveu para PR e foi excluído sem imputação;
- PR lead time pode ser afetado por tamanho, urgência e época do projeto;
- comparar categorias no mesmo repositório não é experimento causal de arquitetura.

## Progress log

- 2026-09-03: protocolo pré-registrado antes de consultar lead times.
- 2026-09-03: população 25/11/13 reproduzida exatamente.
- 2026-09-03: 48/49 commits resolveram para PR, sem ambiguidades.
- 2026-09-03: thresholds avaliados; associação cross-boundary→lead time maior registrada.

## Decision log

- 2026-09-03: reutilizar exatamente a população/classificação do 0062 evitou seleção posterior.
- 2026-09-03: mediana + Cliff's delta mantidos como métricas principais.
- 2026-09-03: o resultado não será promovido a claim causal de arquitetura.
- 2026-09-03: próximo estudo decision-relevant, se necessário, deve controlar tamanho/churn ou executar uma mudança equivalente em duas topologias; repetir apenas lead time bruto teria baixo valor marginal.

## Critérios de aceite

- protocolo antes dos resultados: PASS;
- população congelada reproduzida exatamente: PASS;
- artifact machine-readable: PASS;
- missing/ambiguous explícitos: PASS;
- thresholds pré-declarados: PASS;
- interpretação bounded: PASS;
- plano arquivado: PASS;
- checks/review no head final: revalidar no PR #192.

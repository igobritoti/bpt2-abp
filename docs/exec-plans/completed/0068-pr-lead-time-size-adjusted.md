# Plan 0068 — PR lead-time size-adjusted analysis

Status: **CONCLUÍDO**

## Objetivo / outcome

Testar se a associação observada no Plan 0067 entre mudanças `cross_boundary` e lead time maior permanece material depois de controlar aproximadamente tamanho/churn da mudança.

## Contexto congelado

- `main` de origem: `0a3439bc1ba60e52c426e70f8e684fbb17b89228`;
- população congelada 0062/0067: 49 commits de produto (`25 backend_only`, `11 frontend_only`, `13 cross_boundary`);
- resolução commit→PR idêntica ao 0067;
- churn = additions + deletions do commit first-parent;
- files changed = paths alterados no mesmo commit.

## Protocolo

- nearest-neighbor matching sem reposição em `log1p(churn)`, desempate por `log1p(files_changed)` e SHA;
- lead time não usado para formar pares;
- mínimo 8 pares;
- comparação por mediana e Cliff's delta;
- regressão complementar `log1p(lead_time_h) ~ cross_boundary + log1p(churn) + log1p(files_changed)` com HC3;
- thresholds definidos antes dos resultados.

## Execução

### Piloto não-autoritativo

Run `33827064229`, artifact `9920338575`, SHA-256 `dbacec7e4d77459a7b7d207453fd312fa78ad53d00015ce2889b17ce2d4ae60f`.

A análise completou, mas o workflow ainda fazia checkout da merge-ref; `tree_head` não identificava diretamente o PR head. Mantido apenas como piloto.

### Execução autoritativa

Run `33827200367`.
Head medido: `9bd9273ad000ffb20dbccad28ffdda577918b637`.
Artifact `9920384028`.
SHA-256 `138a0c0806aa895a51205a48574b2fe6dd5a41c9431e1ec1e621db13a4bdf1f3`.

População reproduzida: 49; PRs resolvidos: 48; missing: 1; ambiguous: 0.

## Resultados

### Tamanho observado

- cross-boundary churn mediano: **333,5** linhas;
- single-boundary churn mediano: **366,5** linhas;
- cross-boundary files changed mediano: **11**;
- single-boundary files changed mediano: **6**.

Cross-boundary não apresentou churn mediano maior, mas tocou mais arquivos na mediana.

### Matching por tamanho

- pares: **12/12**;
- lead time cross-boundary mediano: **0,563 h**;
- lead time single-boundary matched mediano: **0,408 h**;
- razão de medianas: **1,380x**;
- Cliff's delta: **0,236**;
- decisão pré-registrada: **`inconclusive_tradeoff`**.

O sinal bruto do 0067 (1,841x; delta 0,343) enfraquece abaixo dos thresholds de materialidade após matching aproximado por churn/tamanho.

### Regressão complementar

n = **48**, R² = **0,182**.

- `cross_boundary`: beta **-0,0698**, HC3 SE **0,2236**, p normal-approx **0,7548**;
- `log1p(churn)`: beta **-0,0301**, p **0,4485**;
- `log1p(files_changed)`: beta **+0,4041**, p **0,0178**.

A regra de reforço para `cross_boundary` (beta > 0 e p < 0,05) não foi satisfeita. O número de arquivos aparece positivamente associado ao lead time nesta especificação, mas isso continua observacional e não prova causalidade.

## Interpretação

O Plan 0067 mostrou associação bruta entre cross-boundary e lead time maior. O 0068 demonstra que essa associação **não permanece material pelos thresholds pré-registrados quando aproximamos controle por tamanho**, e a regressão não preserva efeito positivo de `cross_boundary`.

Portanto:

- não é válido usar o 0067 isoladamente como evidência de que uma fronteira cross-boundary, por si só, aumenta lead time;
- a dispersão por número de arquivos/escopo da mudança é uma ameaça de validade material;
- o resultado não prova que split é melhor, nem que monorepo é pior;
- a claim correta é que o efeito bruto de boundary é sensível ao controle por tamanho/escopo na população histórica observada.

## Threats to validity

- churn e files changed são proxies imperfeitos de complexidade;
- matching pequeno deixa confusão residual;
- regressão tem n pequeno e usa aproximação normal para p-values HC3;
- lead time inclui review, prioridade, fila e disponibilidade humana;
- estudo permanece observacional e não estima causalmente topologia de repositório.

## Progress log

- 2026-09-03: protocolo pré-registrado.
- 2026-09-03: piloto completou, mas foi rebaixado por rastreabilidade de merge-ref.
- 2026-09-03: workflow alinhado ao contrato de concurrency/checkout do Harness.
- 2026-09-03: execução autoritativa completou no head `9bd9273a...`.
- 2026-09-03: matching classificado como `inconclusive_tradeoff`; regressão não reforçou efeito cross-boundary.

## Decision log

- 2026-09-03: manter 0067 como associação bruta, mas não promover sua diferença para claim causal após o 0068.
- 2026-09-03: próximos estudos não devem repetir lead-time bruto; um teste decision-relevant deve usar mudança equivalente/controlada entre topologias ou medir deploy/rollback real.

## Critérios de aceite

- protocolo antes dos resultados: PASS;
- população reproduzida: PASS;
- >=8 pares: PASS (12);
- artifact machine-readable: PASS;
- head explícito no artifact autoritativo: PASS;
- interpretação contra thresholds: PASS;
- plano arquivado: PASS;
- checks/review: revalidar no head final do PR #193.

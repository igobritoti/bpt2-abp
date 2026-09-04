# Plan 0068 — PR lead-time size-adjusted analysis

Status: **ATIVO**

## Objetivo / outcome

Testar se a associação observada no Plan 0067 entre mudanças `cross_boundary` e lead time maior permanece material depois de controlar, de forma descritiva e pré-registrada, o tamanho/churn da mudança.

Este estudo continua observacional. Ele não estima causalmente o efeito de uma arquitetura multi-repo e não autoriza conclusão sobre produtividade futura.

## Contexto congelado antes dos resultados

- `main` de origem: `0a3439bc1ba60e52c426e70f8e684fbb17b89228`;
- mesma população congelada do Plan 0062/0067: 100 commits first-parent em `53be795b6205ef57c03f1118e0c0287dc0f2873c`;
- população de produto esperada: 49 commits (`25 backend_only`, `11 frontend_only`, `13 cross_boundary`);
- resolução commit→PR idêntica ao Plan 0067, sem imputar missing/ambiguous;
- lead time: `merged_at - created_at` do PR associado;
- churn: `additions + deletions` do commit de integração first-parent;
- files changed: número de paths alterados no mesmo commit de integração.

## Perguntas e métricas pré-declaradas

RQ1. Cross-boundary muda mais linhas/arquivos que single-boundary na população observada?

RQ2. A associação de lead time permanece quando comparamos casos de tamanho semelhante?

RQ3. Uma regressão robusta simples em `log1p(lead_time_hours)` com preditores `cross_boundary`, `log1p(churn)` e `log1p(files_changed)` mantém coeficiente positivo para `cross_boundary`?

Métricas: mediana/IQR de churn e arquivos por grupo; comparação pareada por nearest-neighbor em log-churn com matching sem reposição; razão de medianas e Cliff's delta no conjunto matched; coeficiente `cross_boundary` da regressão OLS com HC3; R² e n.

## Desenho pré-declarado

- usar todos os PRs resolvidos do 0067;
- calcular churn exclusivamente do commit first-parent congelado, não do patch cumulativo do PR;
- matching: para cada `cross_boundary`, selecionar um `single_boundary` ainda não usado que minimize distância absoluta em `log1p(churn)`; desempate por `log1p(files_changed)` e depois commit SHA;
- não usar lead time para formar pares;
- exigir pelo menos 8 pares matched;
- regressão complementar, não substituta do matching;
- sem redefinir thresholds após observar resultados.

## Regras de decisão pré-declaradas

- menos de 8 pares matched: evidência insuficiente para ajuste por tamanho;
- se matched median ratio >=1,50 e Cliff's delta >=0,33: associação de lead time maior permanece material após controle aproximado por tamanho;
- se matched median ratio entre 0,80 e 1,25 e |Cliff's delta| <0,33: a evidência do 0067 é compatível com confusão substancial por tamanho;
- demais resultados: inconclusivos/trade-off;
- regressão só reforça interpretação se coeficiente `cross_boundary > 0` e p HC3 <0,05; ausência disso não invalida o matching;
- nenhuma regra autoriza inferência causal de arquitetura.

## Threats to validity

- churn não mede complexidade semântica;
- commit de integração por squash pode agregar mudanças internas do PR de modo diferente entre casos;
- matching em amostra pequena deixa confusão residual;
- regressão com n pequeno tem baixo poder e sensibilidade a outliers;
- lead time inclui fatores humanos e prioridade.

## Progress log

- 2026-09-03: protocolo pré-registrado antes de consultar churn/tamanho da população.
- 2026-09-03: primeiro run completou a análise, mas o workflow ainda fazia checkout da merge-ref; `tree_head` do artifact não identificou diretamente o PR head. Esse run é mantido apenas como piloto não-autoritativo.
- 2026-09-03: workflow corrigido para checkout explícito de `github.event.pull_request.head.sha`, concurrency padrão e action pin vigente; resultado autoritativo será apenas uma execução posterior à correção.

## Decision log

- 2026-09-03: escolhido matching em churn + arquivos e regressão HC3 complementar para testar a principal ameaça de validade identificada no 0067.
- 2026-09-03: lead time não participa da seleção dos pares.
- 2026-09-03: o primeiro artifact não será usado como autoridade decisória por ambiguidade de rastreabilidade do checkout, mesmo com análise funcionalmente concluída.

## Critérios de aceite

- protocolo registrado antes dos resultados;
- população 0062/0067 reproduzida;
- >=8 pares matched;
- artifact machine-readable com pares e regressão;
- artifact autoritativo identifica o PR head medido;
- interpretação contra thresholds;
- plano arquivado;
- checks/review verdes no head final.

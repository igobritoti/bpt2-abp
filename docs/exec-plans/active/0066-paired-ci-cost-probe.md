# Plan 0066 — Paired CI cost probe

Status: **ATIVO**

## Objetivo / outcome

Medir uma quantidade operacional ainda ausente na decisão monorepo vs split: custo de execução CI de um workload equivalente backend+frontend, comparando no mesmo runner uma execução conjunta e uma execução particionada em snapshots independentes.

O estudo não mede produtividade humana, deploy real, custo financeiro nem manutenção de longo prazo. Ele mede duração observada e trabalho executado sob um protocolo controlado.

## Contexto congelado antes dos resultados

- `main` de origem: `4bdf7475d77320505bf4861fe39c3b18da54c40d`;
- partição idêntica ao Plan 0064: backend = checkout menos `public-web/**`; frontend = somente `public-web/**`;
- backend command: `dotnet build main/BomPraTi/BomPraTi.csproj --configuration Release --nologo`;
- frontend commands: `npm ci --no-audit --no-fund` + `npm run check`;
- comparação será executada dentro do mesmo GitHub-hosted runner por par para reduzir variação entre tipos de máquina;
- cada condição começa de diretório materializado novo e sem outputs de build reaproveitados entre condições;
- caches de package manager não serão tratados como equivalentes a outputs de build; qualquer cache disponível ao runner será documentado.

## Perguntas e métricas pré-declaradas

RQ1. Qual o wall-clock observado do workload conjunto?

RQ2. Qual o wall-clock observado do workload particionado quando backend e frontend são executados como streams independentes?

RQ3. Qual a soma de compute-seconds dos streams particionados e qual o critical-path wall-clock quando executados em paralelo?

RQ4. Qual a razão split/combined para compute-seconds e critical-path?

Métricas: duração backend, duração frontend install/check, duração combined, soma split compute, max(split streams) como critical path, ratios e exit status.

## Desenho experimental pré-declarado

- unidade experimental: um par de execuções no mesmo runner e mesmo checkout SHA;
- mínimo: **5 pares válidos**;
- ordem alternada por repetição para reduzir viés de warm-up: pares ímpares `combined -> split`, pares pares `split -> combined`;
- materialização nova antes de cada condição;
- medição com relógio monotônico;
- qualquer falha funcional invalida o par para comparação e é reportada separadamente;
- reportar mediana e distribuição dos pares, não apenas um run.

A condição `combined` executa backend e frontend a partir de uma árvore única, mas sem paralelismo artificial entre os comandos. A condição `split` materializa árvores independentes e mede cada stream; seu critical path é modelado como `max(backend, frontend)` e seu compute como `backend + frontend`. Essa modelagem separa latência potencial de consumo total e não finge que dois jobs reais têm zero overhead de scheduling/checkout.

## Regras de decisão pré-declaradas

- menos de 5 pares válidos: evidência insuficiente;
- diferença absoluta de mediana <10%: tratar como inconclusiva para custo CI neste protocolo;
- split compute >=20% acima do combined: registrar penalidade de compute relevante neste workload;
- split critical-path >=20% abaixo do combined: registrar benefício potencial de paralelização neste workload;
- resultados conflitantes entre compute e critical-path devem permanecer trade-off, não ser reduzidos a um vencedor;
- nenhum resultado deste estudo autoriza claim de produtividade, manutenção ou custo financeiro sem medição correspondente.

## Threats to validity

- GitHub-hosted runners têm ruído de infraestrutura;
- modelar streams split no mesmo runner não inclui fila/startup de dois jobs reais;
- package-manager caches podem variar;
- um workload de build/check não representa todo CI nem deploy;
- o estado atual do projeto pode não representar workloads futuros.

## Progress log

- 2026-09-03: protocolo pré-registrado antes da primeira execução.

## Decision log

- 2026-09-03: escolhido desenho pareado e ordem alternada para reduzir confusão por variação de runner/warm-up.
- 2026-09-03: compute e critical-path serão reportados separadamente para evitar confundir consumo com latência.

## Critérios de aceite

- protocolo antes dos resultados;
- >=5 pares válidos;
- artifact machine-readable com observações individuais;
- comandos funcionais idênticos ao Plan 0064;
- interpretação limitada às métricas observadas;
- checks/review verdes no head final.

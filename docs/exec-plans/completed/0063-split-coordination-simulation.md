# Plan 0063 — Split coordination simulation

Status: **CONCLUÍDO**

## Objetivo / outcome

Simular a separação frontend/backend para **todas as 13 mudanças cross-boundary** identificadas no baseline 0062 e medir a coordenação mecânica que surgiria em duas linhas de integração independentes.

Este estudo não cria dois repositórios reais e não mede produtividade humana. O objetivo foi quantificar transações mínimas de integração, duplicação de gates declarados, paths shared sem ownership único e sinais observáveis de sincronização de contrato.

## Contexto congelado

- baseline histórico: `53be795b6205ef57c03f1118e0c0287dc0f2873c`;
- configuração de workflows: `e0cb70b9307d0122541d1cf8a04686d9d044bad4`;
- conjunto de estudo: todos os 13 commits `cross_boundary` do Plan 0062;
- backend simulado: `main/**`, `modules/**`, `tests/**`;
- frontend simulado: `public-web/**`;
- demais paths: `shared/control-plane`, sem atribuição automática.

## Perguntas, classificação e métricas

RQ1. Transações mínimas de PR/merge e revert em duas linhas independentes.

RQ2. Invocações de workflows declarados para full change versus partições backend/frontend.

RQ3. Frequência de paths shared/control-plane que exigem decisão de ownership.

RQ4. Frequência de alteração simultânea de contrato/API backend e cliente/API frontend.

Sinal de contrato backend: path contendo `.Contracts/` ou `main/BomPraTi/Controllers/`.

Sinal de cliente/API frontend: `public-web/lib/**` ou `public-web/app/api/**`.

`contract_sync_candidate` exige ambos no mesmo commit.

Métricas pré-declaradas: número de mudanças; transações mínimas de PR/revert; invocações full/split/duplicadas de workflow; mudanças e total de shared paths; contract sync candidates; resultados por commit.

## Regra de decisão pré-declarada

- `extra_workflow_invocations_ratio >= 0.20`: protótipo posterior deve medir custo real de CI antes de recomendação de split;
- `contract_sync_candidates_ratio >= 0.25`: protótipo posterior deve incluir versionamento/compatibilidade de contrato e ordem de deploy;
- `changes_with_shared_paths_ratio >= 0.50`: protótipo posterior deve declarar e medir ownership de shared/control-plane;
- se nenhuma condição ocorrer, próximo estudo pode priorizar build/test isolation e CI lead time.

Os thresholds selecionam o próximo experimento, não uma arquitetura vencedora.

## Execução e resultado

Workflow run: `33764109640`.

Head exato: `8e6ceaa1105d7a0b0bc598ea8fc2f1e5d3f51d00`.

Artifact id: `9896729215`.

SHA-256: `2fb82dbef676a831c3b5e63675b98337b2cd803e7ab04990400d1ee89cc11848`.

Resultados:
- mudanças: 13;
- monorepo mínimo PR/merge: 13;
- split simulado mínimo PR/merge: 26;
- transações adicionais: 13 (+100% estrutural);
- monorepo mínimo revert: 13;
- split simulado mínimo revert: 26;
- invocações de workflow full: 338;
- invocações de workflow nas duas partições: 387;
- adicionais: 49 (+14,50%);
- invocações duplicadas entre partições: 103;
- mudanças com shared/control-plane: 13/13 (100%);
- shared paths: 46;
- contract sync candidates: 12/13 (92,31%);
- workflows PR na configuração congelada: 28.

## Interpretação

O threshold de expansão de workflows (20%) **não** disparou: 14,50% nesta simulação de configuração.

O threshold de sincronização de contrato disparou: 92,31% >=25%. O próximo protótipo multi-repo deve medir mecanismo de compatibilidade/versionamento e ordem de deploy.

O threshold de shared/control-plane disparou: 100% >=50%. O próximo protótipo deve declarar e medir ownership/duplicação/externalização desses assets.

A duplicação de transações de PR/revert é uma propriedade estrutural da simulação de dois repositórios para uma mudança lógica cross-boundary, não uma medida de esforço humano.

## Limitações

- duas PRs mínimas por mudança não medem tempo humano;
- path filters atuais poderiam ser redesenhados em repos separados;
- workflow count não equivale a minutos de CI;
- contract signal é heurístico por path;
- shared paths podem ir a backend, frontend, terceiro repo, package ou duplicação;
- não houve deploy/rollback real;
- o matcher de paths usa `fnmatch` como aproximação. Inspeção da configuração congelada não encontrou padrões negativos; os padrões são majoritariamente exatos ou `/**`, com uma família simples `SavedSearchEmailDelivery*.cs`. A métrica de workflow é tratada apenas como simulação bounded, não emulação exata do GitHub.

## Artefatos

- `scripts/simulate-split-coordination.py`;
- `.github/workflows/split-coordination-simulation.yml`;
- artifact `split-coordination-simulation.json`;
- `docs/audits/2026-09-03-split-coordination-simulation.md`.

## Critérios de aceite

- protocolo antes dos resultados: PASS;
- 13/13 commits analisados: PASS;
- artifact produzido: PASS;
- thresholds preservados: PASS;
- produto inalterado: PASS;
- checks/review: verificação final do PR #188.

## Decision log

- 2026-09-03: todos os 13 casos foram usados para evitar seleção subjetiva de amostra.
- 2026-09-03: evidência seleciona como próximo estágio um protótipo de boundary multi-repo com contract compatibility/deploy ordering e ownership de shared/control-plane; não seleciona arquitetura final.

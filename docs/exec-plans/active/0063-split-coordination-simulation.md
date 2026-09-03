# Plan 0063 — Split coordination simulation

Status: **ATIVO**

## Objetivo / outcome

Simular a separação frontend/backend para **todas as 13 mudanças cross-boundary** identificadas no baseline 0062 e medir a coordenação mecânica que surgiria em duas linhas de integração independentes.

Este estudo não cria dois repositórios reais e não mede produtividade humana. O objetivo é quantificar transações mínimas de integração, duplicação de gates declarados, paths shared sem ownership único e sinais observáveis de sincronização de contrato.

## Contexto congelado

- baseline histórico: `53be795b6205ef57c03f1118e0c0287dc0f2873c`;
- baseline de acoplamento: `docs/audits/2026-09-03-monorepo-coupling-baseline.md`;
- conjunto de estudo: os 13 commits classificados `cross_boundary` pelo instrumento 0062;
- arquitetura simulada: repo/backend contém `main/**`, `modules/**`, `tests/**`; repo/frontend contém `public-web/**`; demais paths são `shared/control-plane` e permanecem explicitamente sem atribuição automática.

## Perguntas de pesquisa

RQ1. Quantas transações mínimas de PR/merge e revert seriam necessárias para representar as mesmas 13 mudanças em dois repositórios?

RQ2. Quantas execuções de workflows declarados seriam disparadas ao particionar cada mudança em backend e frontend, comparadas ao conjunto de workflows acionado pela mudança cross-boundary original?

RQ3. Quantas mudanças carregam paths shared/control-plane que exigiriam uma decisão adicional de ownership após o split?

RQ4. Quantas mudanças exibem simultaneamente alteração de contrato/API backend e alteração de cliente/API frontend, sinalizando necessidade explícita de sincronização de contrato?

## Classificação pré-declarada

Backend:
- `main/**`
- `modules/**`
- `tests/**`

Frontend:
- `public-web/**`

Shared/control-plane:
- todo path restante.

Sinal de contrato backend:
- path contendo `.Contracts/`;
- ou `main/BomPraTi/Controllers/`.

Sinal de cliente/API frontend:
- `public-web/lib/**`;
- ou `public-web/app/api/**`.

`contract_sync_candidate = true` somente quando a mesma mudança cross-boundary contém pelo menos um sinal backend e um sinal frontend.

## Workload

Todos os 13 commits cross-boundary do baseline 0062. Não há sampling posterior ao resultado.

Para cada commit:
1. recuperar paths alterados contra o primeiro pai;
2. particionar backend/frontend/shared;
3. calcular workflows `pull_request.paths` acionados pelo conjunto completo;
4. calcular workflows acionados pela partição backend;
5. calcular workflows acionados pela partição frontend;
6. registrar interseção backend/frontend como workflows que seriam executados em ambas as PRs na simulação;
7. classificar `contract_sync_candidate` e quantidade de paths shared.

## Métricas pré-declaradas

- `changes_n`;
- `monorepo_min_pr_transactions = changes_n`;
- `split_min_pr_transactions = changes_n * 2`;
- `extra_pr_transactions_n` e razão;
- `monorepo_min_revert_transactions = changes_n`;
- `split_min_revert_transactions = changes_n * 2`;
- `full_workflow_invocations_total`;
- `split_workflow_invocations_total = backend + frontend`;
- `extra_workflow_invocations_n` e razão;
- `duplicated_workflow_invocations_n` (interseções somadas);
- `changes_with_shared_paths_n` e razão;
- `shared_paths_total_n`;
- `contract_sync_candidates_n` e razão;
- resultados por commit.

## Regra de decisão deste estágio

Este estágio também não seleciona arquitetura final.

- Se `extra_workflow_invocations_ratio >= 0.20`, um protótipo multi-repo posterior deve medir custo real de CI antes de qualquer recomendação de split.
- Se `contract_sync_candidates_ratio >= 0.25`, um protótipo multi-repo posterior deve incluir versionamento/compatibilidade de contrato e ordem de deploy.
- Se `changes_with_shared_paths_ratio >= 0.50`, um protótipo multi-repo posterior deve declarar e medir uma estratégia de ownership para shared/control-plane.
- Se nenhuma condição acima ocorrer, o próximo experimento pode priorizar build/test isolation e lead-time de CI.

Os valores são thresholds para selecionar o **próximo experimento**, não para declarar monorepo ou split superior.

## Ambiente e reprodução

- GitHub Actions `ubuntu-24.04`;
- checkout `fetch-depth: 0`;
- Python 3 + git;
- history ref congelado em `53be795...`;
- instrumento versionado em `scripts/simulate-split-coordination.py`;
- workflow `BPT2 Split Coordination Simulation`;
- artifact JSON com resultados completos.

## Limitações / ameaças à validade

- duas PRs mínimas por mudança é propriedade estrutural da simulação, não medida de esforço humano;
- path filters atuais pertencem ao monorepo e podem ser redesenhados em repos separados;
- workflow invocation count não equivale a minutos de CI;
- sinais de contrato são heurísticos por path, não prova de incompatibilidade semântica;
- paths shared poderiam ser duplicados, extraídos ou atribuídos a um terceiro repo; este estudo apenas quantifica a decisão pendente;
- não há deploy ou rollback real em dois repositórios.

## Não escopo

- criar repositórios reais;
- migrar código;
- adotar Nx/Turborepo;
- medir produtividade de pessoas;
- concluir arquitetura final.

## Critérios de aceite

- protocolo registrado antes dos resultados;
- todos os 13 commits do baseline analisados;
- artifact JSON produzido no runner;
- thresholds aplicados sem alteração pós-resultado;
- produto inalterado;
- checks aplicáveis verdes e sem review threads abertas.

## Progress log

- 2026-09-03: protocolo aberto a partir do outcome do Plan 0062, antes da execução.

## Decision log

- 2026-09-03: usar todos os 13 commits cross-boundary elimina seleção subjetiva de amostra neste estágio.

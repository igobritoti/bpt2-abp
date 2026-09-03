# Plan 0062 — Monorepo coupling baseline

Status: **CONCLUÍDO**

## Objetivo / outcome

Medir o estado unificado atual do BPT2 antes de qualquer recomendação sobre manter o repositório único, separar frontend/backend, ou introduzir tooling de monorepo.

O outcome é um baseline reproduzível de acoplamento estrutural e histórico. Este estudo, sozinho, **não** prova que monorepo ou múltiplos repositórios são superiores.

## Contexto congelado

- baseline commit: `53be795b6205ef57c03f1118e0c0287dc0f2873c`;
- repositório: `tihotm/bpt2-abp`;
- backend: modular monolith ABP 10.6 / .NET 10 sob `main/`, `modules/` e testes associados;
- frontend público: Next.js sob `public-web/`;
- o estado atual já contém backend e frontend no mesmo repositório;
- não existe neste repositório um controle contemporâneo equivalente de dois repositórios separados para comparação causal direta.

## Perguntas e hipóteses

RQ1. Qual fração das mudanças recentes cruza a boundary backend/frontend?

RQ2. Qual fração permanece confinada a backend ou frontend?

RQ3. Existem dependências diretas de arquivo/import cruzando essa boundary?

RQ4. Os workflows atuais selecionam CI por paths de backend/frontend?

H1. Baixa frequência cross-boundary manteria split como alternativa material a testar, sem preferência automática.

H2. Alta frequência cross-boundary fornece evidência de necessidade de coordenação atômica, sem provar redução de custo por monorepo.

H3. Dependências diretas de arquivo implicariam trabalho adicional de desacoplamento antes de um split.

## Workload e classificação pré-declarados

- 100 commits de primeiro pai encerrando no baseline commit congelado;
- somente commits com mudança em backend ou frontend entram no denominador de produto;
- backend: `main/**`, `modules/**`, `tests/**`;
- frontend: `public-web/**`;
- `.github/**`, `docs/**`, raiz e scripts não atribuíveis ficam como shared/control-plane;
- `cross-boundary` exige ao menos um path backend e um frontend no mesmo commit;
- todos os workflows `pull_request` em `.github/workflows/*.yml` entram na análise de scoping.

## Métricas pré-declaradas

1. `product_commits_n`;
2. `backend_only_n` e proporção;
3. `frontend_only_n` e proporção;
4. `cross_boundary_n` e proporção;
5. `direct_cross_boundary_reference_count`;
6. `pr_workflows_n`;
7. `frontend_scoped_workflows_n`;
8. `backend_scoped_workflows_n`;
9. `dual_scoped_workflows_n`;
10. workflows PR sem `paths`.

## Regra de decisão pré-declarada

- `product_commits_n < 30`: ampliar evidência antes de inferir frequência;
- referência direta > 0: medir/remover dependência antes de experimento de split;
- `cross_boundary_ratio >= 0.25`: próximo estudo deve medir custo de coordenação/atomicidade cross-repo;
- `cross_boundary_ratio <= 0.10`: próximo estudo deve medir custo de isolamento e CI independente;
- entre 0.10 e 0.25: nenhuma direção recebe preferência por esta métrica.

Os thresholds selecionam **o próximo experimento**, não a arquitetura vencedora.

## Ambiente e artefatos

- GitHub Actions `ubuntu-24.04`;
- checkout de histórico completo;
- Python 3 e git do runner;
- `scripts/measure-monorepo-coupling.py`;
- `.github/workflows/monorepo-coupling-baseline.yml`;
- artifact JSON `monorepo-coupling-baseline.json`;
- `docs/audits/2026-09-03-monorepo-coupling-baseline.md`.

## Resultado aceito

Execução: workflow run `33763243292`.

Tree head medido: `a74e835838b40f432bf332f448622eb7f88d068d`.

History ref/SHA congelado: `53be795b6205ef57c03f1118e0c0287dc0f2873c`.

- 100 commits first-parent examinados;
- 49 commits de produto;
- backend-only: 25 (51,02%);
- frontend-only: 11 (22,45%);
- cross-boundary: 13 (26,53%);
- referências diretas de arquivo/path frontend ↔ backend: 0;
- workflows PR: 28;
- frontend-scoped: 11;
- backend-scoped: 24;
- dual-scoped: 10;
- workflows PR sem `paths`: 0.

Artifact id `9896377668`, SHA-256 `246d3c6c61331b550b7a8b3d25561bcf5d9dd18c91a25fc7f8447c1a053f39f4`.

## Interpretação

A amostra mínima (`>=30`) foi atendida. Nenhuma dependência direta de arquivo/import foi encontrada pela análise estática. A proporção cross-boundary de **26,53%** ultrapassa o threshold pré-declarado de 25%; portanto o próximo estudo deve medir explicitamente custo de coordenação e atomicidade de uma separação em múltiplos repositórios.

Isto **não** seleciona monorepo, split, Nx, Turborepo ou qualquer outra arquitetura como superior.

## Limitações / ameaças à validade

- não há controle causal multi-repo equivalente;
- a janela pode refletir uma fase específica do MVP;
- commit count não equivale a esforço, lead time ou custo;
- co-change não equivale a dependência semântica;
- a análise textual não cobre acoplamento via API/contrato;
- path filters não medem duração/custo total de CI.

## Correções metodológicas registradas

- A primeira execução foi descartada porque o checkout padrão do PR usou o merge-ref sintético.
- A segunda usou o PR head, mas revelou que os commits de instrumentação deslocavam a janela móvel de 100 commits.
- Como o baseline commit já estava congelado antes dos resultados, o instrumento final passou a usar `53be795...` como history ref e o head corrente apenas para árvore/workflows. Nenhum threshold ou hipótese foi alterado.

## Critérios de aceite

- protocolo antes do resultado: PASS;
- artifact JSON reproduzível: PASS;
- código de produto inalterado: PASS;
- conclusão limitada à evidência: PASS;
- checks/review: verificação final do PR #187.

## Decision log

- 2026-09-03: preferência arquitetural não é critério; o baseline apenas seleciona o próximo experimento.
- 2026-09-03: resultado aceito seleciona estudo controlado de coordenação/atomicidade cross-repo.

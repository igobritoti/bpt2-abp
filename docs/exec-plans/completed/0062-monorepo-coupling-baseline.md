# Plan 0062 — Monorepo coupling baseline

Status: **CONCLUÍDO**

## Objetivo / outcome

Medir o estado unificado atual do BPT2 antes de qualquer recomendação sobre manter o repositório único, separar frontend/backend, ou introduzir tooling de monorepo.

O outcome deste plano é um baseline reproduzível de acoplamento estrutural e histórico. Este estudo, sozinho, **não** prova que monorepo ou múltiplos repositórios são superiores.

## Contexto congelado

- baseline commit: `53be795b6205ef57c03f1118e0c0287dc0f2873c`;
- repositório observado: `tihotm/bpt2-abp`;
- backend: modular monolith ABP 10.6 / .NET 10 sob `main/`, `modules/` e testes associados;
- frontend público: Next.js sob `public-web/`;
- o estado atual já contém backend e frontend no mesmo repositório;
- o histórico registra trabalho "post-unified", portanto não existe neste repositório um controle contemporâneo de dois repositórios separados para comparação causal direta.

## Perguntas de pesquisa

RQ1. Qual fração das mudanças recentes cruza simultaneamente a boundary backend/frontend?

RQ2. Qual fração das mudanças recentes permanece confinada a backend ou frontend?

RQ3. O código fonte possui dependências de arquivo/import diretas cruzando a boundary backend/frontend, ou a integração observável ocorre por contratos HTTP/configuração?

RQ4. Os workflows atuais conseguem selecionar CI por paths de backend/frontend, ou mudanças de uma boundary acionam sistematicamente gates da outra?

## Hipóteses

H1. Se mudanças cross-boundary forem raras e as boundaries forem estruturalmente independentes, separar repositórios permanece uma alternativa material a ser testada; o baseline não determina que ela seja preferível.

H2. Se mudanças cross-boundary forem frequentes, isso fornece evidência de coordenação atômica no estado atual, mas ainda não prova que monorepo reduz custo total de manutenção.

H3. Se houver dependências diretas de arquivo/import entre frontend e backend, uma separação exigiria trabalho de desacoplamento adicional mensurável.

## Objetos de estudo / workload

- árvore do commit do PR;
- últimos **100 commits de primeiro pai** anteriores/incluindo o head do estudo, excluindo commits cuja mudança esteja limitada a `docs/` para a métrica de acoplamento de produto;
- todos os workflows `pull_request` em `.github/workflows/*.yml`;
- arquivos de fonte/configuração sob `public-web/`, `main/`, `modules/`, `tests/` e `scripts/`.

A janela de 100 commits foi pré-declarada para limitar custo e manter o estudo reproduzível. Resultados não são generalizados para toda a vida do projeto.

## Classificação de paths

Backend/product backend:
- `main/**`
- `modules/**`
- `tests/**` quando o teste referencia backend/.NET
- scripts explicitamente usados por gates backend

Frontend:
- `public-web/**`

Shared/control-plane:
- `.github/**`, `docs/**`, arquivos raiz, `scripts/**` não atribuíveis exclusivamente a uma boundary

Um commit é `cross-boundary` somente quando contém ao menos um path backend e ao menos um path frontend. Mudanças somente shared/control-plane não contam como cross-boundary.

## Métricas pré-declaradas

1. `product_commits_n`: commits na janela com pelo menos uma mudança backend ou frontend.
2. `backend_only_n` e proporção.
3. `frontend_only_n` e proporção.
4. `cross_boundary_n` e proporção.
5. `direct_cross_boundary_reference_count`: referências textuais/imports com paths relativos que cruzem `public-web` ↔ backend.
6. `pr_workflows_n`.
7. `frontend_scoped_workflows_n`: workflows cuja lista `pull_request.paths` contém `public-web/**`.
8. `backend_scoped_workflows_n`: workflows cuja lista `pull_request.paths` contém `main/**` ou `modules/**`.
9. `dual_scoped_workflows_n`: workflows cuja lista de paths contém frontend e backend.
10. lista nominal de workflows sem `pull_request.paths` quando aplicável.

## Regra de decisão deste estágio

Este estágio não seleciona arquitetura final.

- Se `product_commits_n < 30`, o histórico é considerado insuficiente para inferência de frequência e a próxima etapa deve ampliar a janela ou usar outro método.
- Se houver `direct_cross_boundary_reference_count > 0`, qualquer experimento de split deve primeiro medir/remover essas dependências.
- Se `cross_boundary_n / product_commits_n >= 0.25`, a próxima comparação deve incluir explicitamente custo de coordenação/atomicidade de mudanças cross-repo.
- Se `cross_boundary_n / product_commits_n <= 0.10`, a próxima comparação deve incluir explicitamente custo de isolamento e CI independente.
- Entre 0.10 e 0.25, nenhuma direção arquitetural recebe preferência por esta métrica.

Esses thresholds servem apenas para escolher **qual experimento fazer depois**; não são thresholds de superioridade de arquitetura.

## Ambiente / versões materiais

- GitHub Actions `ubuntu-24.04`;
- checkout com histórico completo (`fetch-depth: 0`);
- Python 3 disponível no runner;
- `git` do runner;
- análise estática da árvore e histórico do próprio PR.

## Artefatos para reprodução

- `scripts/measure-monorepo-coupling.py`;
- `.github/workflows/monorepo-coupling-baseline.yml`;
- artifact JSON `monorepo-coupling-baseline.json` produzido pelo workflow;
- `docs/audits/2026-09-03-monorepo-coupling-baseline.md`.

## Resultado final

Execução exata no head `8a98ca748647f91f50e018c7e0c63bd44e64b430`, workflow run `33762990004`:

- 100 commits first-parent examinados;
- 45 commits de produto no denominador;
- backend-only: 25 (55,56%);
- frontend-only: 8 (17,78%);
- cross-boundary: 12 (26,67%);
- referências diretas de arquivo/path frontend ↔ backend: 0;
- workflows PR: 28;
- frontend-scoped: 11;
- backend-scoped: 24;
- dual-scoped: 10;
- workflows PR sem `paths`: 0.

O artifact id `9896272092` foi produzido com digest SHA-256 `4799ff71c09b68aeb3a4e51da0d073f8a2a9ab7002e816932de7b37eb256577d`.

## Interpretação conforme regra pré-declarada

`product_commits_n >= 30`, portanto a condição mínima de amostra deste baseline foi atendida.

`direct_cross_boundary_reference_count = 0`, então nenhuma dependência direta de arquivo/import foi encontrada por esta análise estática.

`cross_boundary_ratio = 26,67% >= 25%`, portanto o próximo estudo deve incluir explicitamente o custo de coordenação/atomicidade de mudanças cross-repo. Isso seleciona a próxima pergunta experimental; não seleciona monorepo como arquitetura superior.

## Limitações / ameaças à validade

- um único repositório atual não fornece controle causal contra uma arquitetura multi-repo equivalente;
- histórico recente pode refletir a fase específica do MVP;
- contagem de commits não equivale a esforço humano, lead time ou custo operacional;
- path co-change pode refletir documentação/testes e não dependência semântica;
- análise textual de referências detecta dependências explícitas de path, não acoplamento via API/contrato;
- filtros de workflow medem configuração declarada, não duração/custo total de CI.

## Escopo

Incluiu protocolo, script, workflow e evidência bruta.

Não incluiu migração, split do repositório, adoção de Nx/Turborepo, alteração de arquitetura de produto ou recomendação final.

## Critérios de aceite

- protocolo registrado antes do resultado: PASS;
- workflow executado no head exato do PR: PASS;
- artifact JSON produzido: PASS;
- métricas calculadas sem alterar código de produto: PASS;
- conclusão limitada ao que as métricas suportam: PASS;
- checks aplicáveis verdes e nenhuma review thread não resolvida: verificação final do PR.

## Checkpoints

1. protocolo e instrumento de medição: concluído;
2. execução remota: concluído;
3. interpretação conforme regra pré-declarada: concluído;
4. registrar conclusão e mover plano para `completed/`: concluído.

## Decision log

- 2026-09-03: não usar preferência arquitetural como critério; este estágio mede apenas o estado atual e seleciona o próximo experimento conforme thresholds pré-declarados.
- 2026-09-03: primeira execução mostrou 27,08% cross-boundary, mas foi descartada como evidência final porque o checkout padrão usou o merge-ref do PR.
- 2026-09-03: workflow corrigido para checkout explícito do PR head SHA; repetição exata mostrou 26,67% cross-boundary e selecionou o experimento de coordenação/atomicidade cross-repo.

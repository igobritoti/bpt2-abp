# Planos de execução

## Por que versionar planos

Trabalho complexo acumula decisões, descobertas e mudanças de direção. Se isso vive apenas em chat, memória ou comentário solto, o próximo agente/colaborador perde contexto e repete investigação.

Planos relevantes são artefatos do repositório.

## Quando criar execution plan

Criar plano versionado quando a tarefa:

- atravessa vários módulos ou camadas;
- deve durar mais de uma mudança pequena;
- possui decisões ainda abertas que serão resolvidas durante execução;
- envolve migration, rollout, segurança, integrações ou refatoração material;
- precisa de critérios de aceite e checkpoints explícitos.

Mudança local trivial não precisa gerar burocracia; pode usar plano efêmero da ferramenta/agente.

## Estrutura

- `exec-plans/active/` — planos em execução.
- `exec-plans/completed/` — planos concluídos preservados como histórico quando existirem.

## Conteúdo mínimo de um plano

1. **Objetivo** — resultado observável.
2. **Contexto** — decisões já congeladas que limitam o trabalho.
3. **Escopo** — o que entra.
4. **Não escopo** — o que não será puxado por conveniência.
5. **Critérios de aceite** — como saber que terminou.
6. **Etapas/checkpoints** — sequência revisável.
7. **Decisões abertas** — apenas as necessárias para o plano.
8. **Progress log** — estado factual, não narrativa longa.
9. **Decision log** — decisões tomadas durante execução com link para ADR/MDV quando material.
10. **Resultado** — ao concluir, o que mudou e quais pendências sobraram.

## Regras

- Planos descrevem **execução**, não substituem ADR nem `PRODUCT.md`.
- Se uma hipótese do plano for invalidada, atualizar o plano em vez de continuar por sunk cost.
- Não congelar tecnologia apenas porque apareceu como passo de um plano.
- Ao concluir, mover para `completed/` quando o histórico tiver valor; atualizar fontes canônicas antes de considerar o plano encerrado.

## Plano ativo

- `exec-plans/active/0001-product-baseline.md` — transformar a fundação validada pelo Gate 01 em primeiro baseline funcional do produto.

## Fundamentação

A OpenAI descreve planos como artefatos de primeira classe em seu fluxo agent-first, mantendo planos ativos, concluídos e dívida técnica no repositório para evitar dependência de contexto externo. O BPT2 adota o princípio, não necessariamente a estrutura exata usada internamente pela OpenAI.

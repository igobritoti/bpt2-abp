# Execution plans

Planos são artefatos versionados para trabalho complexo. Este documento define **a política**; o estado corrente fica em `agent/CURRENT-WORK.md`.

## Quando usar

Crie execution plan quando a tarefa atravessa vários módulos/camadas, tem checkpoints ou decisões abertas, envolve migration/segurança/integração/refatoração material, ou precisa sobreviver a mais de uma sessão.

Mudança local trivial pode usar plano efêmero.

## Estrutura

- `exec-plans/active/` — trabalho em execução.
- `exec-plans/completed/` — histórico concluído.
- `exec-plans/tech-debt-tracker.md` — dívida conhecida que precisa permanecer visível.

## Conteúdo mínimo

Um plano ativo contém:

1. objetivo/outcome;
2. contexto congelado;
3. escopo e não escopo;
4. critérios de aceite;
5. checkpoints;
6. decisões abertas necessárias;
7. `Progress log` factual;
8. `Decision log`.

Ao concluir, registrar resultado e evidência final, marcar `Status: **CONCLUÍDO**` e mover para `completed/`.

## Regras

- Plano não substitui `PRODUCT.md`, `ARCHITECTURE.md`, ADR ou `MDV.md`.
- Hipótese invalidada deve atualizar o plano; não continuar por sunk cost.
- Não usar plano como diário infinito.
- `agent/CURRENT-WORK.md` aponta para o plano ativo relevante; não replica o progress log.
- Não manter uma lista manual de “planos ativos” aqui; a árvore `exec-plans/active/` e `CURRENT-WORK` são as fontes.

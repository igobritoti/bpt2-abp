# Current work

Last verified: **2026-08-26**

Este arquivo é um snapshot curto do trabalho corrente. Não é histórico, changelog nem inventário de CI.

## Active outcome

Testar a persistência/UoW do detector de Favorite price-drop após o PR #77 provar que a primeira queda esperada para uma Listing publicada já favoritada deixa o ledger vazio.

A hipótese corrente é estreita: o detector rejeitado persistia por `MarketplaceDbContext` injetado diretamente enquanto o fluxo de comando usa repositórios ABP. O slice troca somente essa boundary e mantém o mesmo smoke como falsificador.

## Active plan

[`../exec-plans/active/0051-favorite-price-drop-uow-probe.md`](../exec-plans/active/0051-favorite-price-drop-uow-probe.md)

## Acceptance target

- Draft decrease sem ledger;
- Favorite existente antes da queda recebe exatamente um match;
- Favorite tardio sem retroativo;
- replay idempotente;
- aumento ignorado;
- unfavorite impede apenas quedas futuras;
- Fresh Migration + Buyer Favorites HTTP verdes no head exato.

Se a troca para repositórios ABP não resolver o primeiro match, fechar o slice sem correção adicional e voltar ao sweep de blockers.

## Source of runtime truth

- Estado de branch/PR/checks: Git e GitHub Actions do commit corrente.
- Produto: [`../PRODUCT.md`](../PRODUCT.md).
- Fatos derivados: [`../generated/repository-facts.md`](../generated/repository-facts.md).
- Decisões: [`../MDV.md`](../MDV.md) e [`../adr/`](../adr/).
- Plano ativo: [`../exec-plans/active/0051-favorite-price-drop-uow-probe.md`](../exec-plans/active/0051-favorite-price-drop-uow-probe.md).
- Roadmap concluído: [`../exec-plans/completed/0049-post-mvp-capability-completion.md`](../exec-plans/completed/0049-post-mvp-capability-completion.md).
- Checkpoint anterior: [`../audits/2026-08-26-post-plan0050-trigger-sweep.md`](../audits/2026-08-26-post-plan0050-trigger-sweep.md).

## Open blockers

- Favorite price-drop: sob probe de persistência/UoW no Plan 0051.
- Comparator: enrichment técnico publicado suficiente do Podium.
- Saved Search runner: sem distributed-lock provider/configuração e sem deployment contract cross-instance.
- Discovery avançado: sem corpus/baseline/métrica.
- Inteligência de mercado: sem dataset/licença/metodologia/provenance.
- Carros na Web: inventário público atual ainda não reproduzível; acesso direto continua falhando.

## Update rule

Atualize este snapshot somente quando mudar outcome, plano, acceptance target ou blocker real.

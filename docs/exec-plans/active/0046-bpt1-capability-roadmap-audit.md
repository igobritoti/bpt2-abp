# Plan 0046 — BPT1 capability roadmap audit

Status: **CONCLUÍDO**

Data de conclusão: 2026-08-25

## Outcome

O BPT1 foi auditado como donor de capacidades, nunca como chassis técnico. O trabalho produziu inventário funcional, matriz BPT1 ↔ BPT2, benchmark externo atual, testes falsificáveis, recomendações proativas de adição/edição/exclusão/substituição e uma única próxima capability promovida.

## Checkpoints

- [x] CP1 — inventário funcional BPT1 completo o suficiente para evitar cherry-picking.
- [x] CP2 — matriz BPT1 ↔ BPT2 consolidada.
- [x] CP3 — benchmark atual consolidado com Webmotors e OLX verificados, iCarros como terceiro portal verificável e Carros na Web explicitamente sem conclusão por indisponibilidade reproduzível.
- [x] CP4 — testes/experimentos definidos para candidatos fortes.
- [x] CP5 — matriz final de decisão.
- [x] CP6 — próximo slice escolhido por evidência.

## Evidência principal

Os detalhes auditáveis estão em `docs/audits/`:

- `2026-08-25-bpt1-bpt2-capability-delta-matrix.md`;
- `2026-08-25-comparator-prerequisite-test.md`;
- `2026-08-25-comparator-cardinality-contract.md`;
- `2026-08-25-vehicle-enrichment-source-authority.md`;
- `2026-08-25-pbev-reconciliation-granularity-test.md`;
- `2026-08-25-minimum-vehicle-enrichment-contract.md`;
- `2026-08-25-saved-search-contract-test.md`;
- `2026-08-25-crm-minimum-lifecycle-test.md`;
- `2026-08-25-minimum-product-instrumentation-test.md`;
- `2026-08-25-promotions-ranking-separation-test.md`;
- `2026-08-25-external-market-benchmark-checkpoint.md`;
- `2026-08-25-proactive-market-feature-recommendations.md`;
- `2026-08-25-research-driven-product-recommendation-policy.md`;
- `2026-08-25-capability-final-decision-matrix.md`.

## Decisões finais deste plano

### Próximo slice promovido

**CRM — fechamento mínimo de Lead.**

Acceptance criterion resumido:

- preservar `MarkContacted` idempotente;
- Seller só altera Leads dos próprios Listings;
- permitir fechar Lead com outcome `Won` ou `Lost`;
- repetir o mesmo fechamento sem duplicar efeito;
- outcome conflitante não sobrescreve silenciosamente histórico;
- histórico permanece consultável após Pause/Archive;
- nenhuma attribution, notes, dashboard, `NEGOCIACAO` ou pipeline de cinco estados neste slice.

### Decisões materialmente alteradas pela auditoria

- Comparador permanece candidato, agora com cardinalidade escolhida pelo usuário de **2 até 4 Vehicles**, mas implementação está bloqueada até enrichment canônico suficiente.
- PBEV/Inmetro é fonte forte para primeiro enrichment de consumo/eficiência, mas reconciliação automática direta para `Vehicle` foi reprovada porque a linha observada não fornece `ModelYear`.
- Primeiro enrichment deve começar somente por campos com fonte estruturada defensável; potência/torque/dimensões/equipamentos aguardam fonte primária adequada.
- Pipeline CRM BPT1 de cinco estados foi reprovado como primeiro desenho; testar lifecycle mínimo com fechamento/outcome.
- Analytics/dashboard amplo do donor foi substituído por instrumentação mínima orientada a perguntas de produto.
- `HighlightScore` BPT1 foi descartado; Promotions deve manter pago separado de orgânico, confiança e qualidade.
- Saved Search / alerts foi promovido a candidato forte de teste, como capability nova, não simples transplante do donor.
- Vehicle Trust Signals e market-price context entraram como novas linhas de pesquisa; ambas continuam dependentes de contratos/dados próprios.
- Planner e Argus Core foram excluídos como features de produto; Credits e Payments continuam adiados.

## Regra preservada

`TRAZER` nunca significa portar código/arquitetura do BPT1. Cada capability promovida recebe execution plan próprio, menor slice falsificável e checks proporcionais ao risco.

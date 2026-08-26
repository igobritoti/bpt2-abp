# Current work

Last verified: **2026-08-26**

Este arquivo é um snapshot curto do trabalho corrente. Não é histórico, changelog nem inventário de CI.

## Active outcome

Concluir progressivamente as capabilities restantes do Bom Pra Ti pelo Plan 0049.

O **contrato mínimo de detecção de nova oferta compatível está comprovado**: opt-in é explícito, matching reutiliza a semântica pública, Draft/private não entra, `(SavedSearchId, ListingId)` deduplica reprocessamento e detecção permanece separada de delivery.

A próxima boundary é provar o **gatilho confiável da detecção quando uma Listing se torna pública**, sem varrer todas as buscas salvas dentro de `PublishAsync`, sem chamar provider externo no request e sem escolher scheduler/event bus/outbox antes do teste de atomicidade/retry exigir.

O prerequisite de enrichment do Comparador permanece no bounded context Podium 7 e não bloqueia esta trilha de retenção Buyer.

A meta estratégica adicional continua sendo atingir pelo menos **90% das capabilities úteis/elegíveis do Carros na Web**, mirando 100% quando custo, dados, licenças, risco e valor justificarem.

## Active plan

[`../exec-plans/active/0049-post-mvp-capability-completion.md`](../exec-plans/active/0049-post-mvp-capability-completion.md)

## Acceptance target

Antes de integrar automaticamente a detecção ao lifecycle de publicação, o próximo slice deve provar/decidir:

- qual boundary observa com confiabilidade a transição para estado público;
- como evitar o gap "Listing publicada, match nunca materializado" se houver falha intermediária;
- como retry/replay preserva a unicidade `(SavedSearchId, ListingId)`;
- que `PublishAsync` não ganha latência proporcional ao número de Saved Searches;
- que nenhuma entrega externa participa da transação de publicação;
- se evento local + UoW é suficiente ou se outbox/background job é realmente exigido pelo caso de falha;
- scheduler/polling continuam reprovados como default enquanto um gatilho por transição puder resolver o problema;
- provider/canal permanecem não decididos até o trigger/delivery contract estar fechado.

Não implementar price-drop, Comparator, Promotions ou outro bloco em paralelo enquanto esse slice estiver ativo.

## Source of runtime truth

- Estado de branch/PR/checks: Git e GitHub Actions do commit corrente.
- Produto e escopo consolidado: [`../PRODUCT.md`](../PRODUCT.md).
- Fatos estruturais/versões/counters derivados: [`../generated/repository-facts.md`](../generated/repository-facts.md).
- Decisões congeladas: [`../MDV.md`](../MDV.md) e [`../adr/`](../adr/).
- Plano ativo: [`../exec-plans/active/0049-post-mvp-capability-completion.md`](../exec-plans/active/0049-post-mvp-capability-completion.md).
- Contrato Saved Search auditado: [`../audits/2026-08-25-saved-search-contract-test.md`](../audits/2026-08-25-saved-search-contract-test.md).
- Contrato de detecção de nova oferta: [`../audits/2026-08-25-new-listing-alert-contract-test.md`](../audits/2026-08-25-new-listing-alert-contract-test.md).
- Meta Carros na Web: [`../strategy/2026-08-25-carros-na-web-functional-coverage-goal.md`](../strategy/2026-08-25-carros-na-web-functional-coverage-goal.md).
- Boundary Podium 7: [`../adr/0011-podium7-catalog-integration-boundary.md`](../adr/0011-podium7-catalog-integration-boundary.md).

Não copie SHAs, número de testes/checks ou “runtime ready” para este arquivo; consulte as fontes executáveis quando a tarefa depender deles.

## Open blockers

Comparator continua bloqueado somente por enrichment técnico publicado suficiente do Podium. Isso não bloqueia o teste do gatilho de alertas sobre Saved Search.

A pesquisa pública do Carros na Web ainda não forneceu inventário atual reproduzível suficiente; isso bloqueia apenas o cálculo de cobertura do benchmark, não o desenvolvimento normal do BPT2.

## Update rule

Atualize este snapshot somente quando mudar o outcome ativo, plano ativo, próximo acceptance target ou blocker real. História vai para execution plan concluído/ADR, não para baixo deste arquivo.

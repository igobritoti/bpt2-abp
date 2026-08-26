# Current work

Last verified: **2026-08-25**

Este arquivo é um snapshot curto do trabalho corrente. Não é histórico, changelog nem inventário de CI.

## Active outcome

Concluir progressivamente as capabilities restantes do Bom Pra Ti pelo Plan 0049.

O **Saved Search baseline está concluído**. A próxima boundary independente do BPT2 é testar o contrato mínimo de **alerta de nova oferta compatível** usando a intenção persistida do Saved Search, sem presumir scheduler, provider ou canal de entrega. O prerequisite de enrichment do Comparador permanece no bounded context Podium 7 e não deve bloquear esta trilha de retenção Buyer.

A meta estratégica adicional continua sendo atingir pelo menos **90% das capabilities úteis/elegíveis do Carros na Web**, mirando 100% quando custo, dados, licenças, risco e valor justificarem.

## Active plan

[`../exec-plans/active/0049-post-mvp-capability-completion.md`](../exec-plans/active/0049-post-mvp-capability-completion.md)

## Acceptance target

Antes de implementar alerta de nova oferta compatível, o próximo slice deve provar/decidir:

- qual evento/estado representa uma oferta tornando-se publicamente elegível para matching;
- que matching reutiliza critérios semânticos do Saved Search e nunca inclui Draft/private;
- como evitar reprocessamento/notificação duplicada da mesma oferta para a mesma intenção;
- onde ficam opt-in, desativação/unsubscribe e estado mínimo do alerta;
- separação entre detectar match e entregar notificação;
- se existe necessidade real de background job/scheduler e qual frequência decorre do requisito, em vez de escolher infraestrutura primeiro;
- provider/canal de entrega permanecem não decididos até haver contrato e requisito suficiente.

Não implementar price-drop, Comparator, Promotions ou outro bloco em paralelo enquanto esse slice estiver ativo.

## Source of runtime truth

- Estado de branch/PR/checks: Git e GitHub Actions do commit corrente.
- Produto e escopo consolidado: [`../PRODUCT.md`](../PRODUCT.md).
- Fatos estruturais/versões/counters derivados: [`../generated/repository-facts.md`](../generated/repository-facts.md).
- Decisões congeladas: [`../MDV.md`](../MDV.md) e [`../adr/`](../adr/).
- Plano ativo: [`../exec-plans/active/0049-post-mvp-capability-completion.md`](../exec-plans/active/0049-post-mvp-capability-completion.md).
- Contrato Saved Search auditado: [`../audits/2026-08-25-saved-search-contract-test.md`](../audits/2026-08-25-saved-search-contract-test.md).
- Meta Carros na Web: [`../strategy/2026-08-25-carros-na-web-functional-coverage-goal.md`](../strategy/2026-08-25-carros-na-web-functional-coverage-goal.md).
- Boundary Podium 7: [`../adr/0011-podium7-catalog-integration-boundary.md`](../adr/0011-podium7-catalog-integration-boundary.md).

Não copie SHAs, número de testes/checks ou “runtime ready” para este arquivo; consulte as fontes executáveis quando a tarefa depender deles.

## Open blockers

Comparator continua bloqueado somente por enrichment técnico publicado suficiente do Podium. Isso não bloqueia o teste/implementação de alertas sobre Saved Search.

A pesquisa pública do Carros na Web ainda não forneceu inventário atual reproduzível suficiente; isso bloqueia apenas o cálculo de cobertura do benchmark, não o desenvolvimento normal do BPT2.

## Update rule

Atualize este snapshot somente quando mudar o outcome ativo, plano ativo, próximo acceptance target ou blocker real. História vai para execution plan concluído/ADR, não para baixo deste arquivo.

# Current work

Last verified: **2026-08-29**

Este arquivo é um snapshot curto do trabalho corrente. Não é histórico, changelog nem inventário de CI.

## Active outcome

Issue #111 está em implementação no PR #126: projetar `powertrain`, `transmission` e `body_style` do Podium Catalog JSON `2.0` para o `Vehicle` canônico e Vehicle Hub, preservando `null` como desconhecido atual e sem abrir filtros públicos.

A medição producer-side que antes bloqueava esses três campos foi concluída no Podium. Ela não autoriza enrichment técnico amplo nem Comparator.

## Active plan

Nenhum execution plan separado foi aberto; o boundary executável é a issue #111 / PR #126.

Último plano concluído antes deste slice: [`../exec-plans/completed/0061-enforce-ephemeral-migration-authority.md`](../exec-plans/completed/0061-enforce-ephemeral-migration-authority.md).

## Próximos gatilhos independentes

- concluir #111 com fixture Podium, Fresh Migration, Public Vehicle Hub/Public Web e Architecture/Harness verdes;
- delivery externo de Saved Search somente após consentimento por canal, destinatário verificável e estado durável/recovery do side effect;
- delivery externo de Favorite price-drop somente após canal/consentimento/destinatário verificável e durable delivery contract;
- deployment/locking reproduzível para claim/retry/restart do runner de Saved Search;
- filtros públicos ou Saved Search por `powertrain`/`transmission`/`body_style` continuam não autorizados até hipótese e benchmark próprios;
- executar o consumer/comparability benchmark #122 antes de Comparator, mesmo com o contrato separado `podium7.quantitative-enrichment.v1` já existente;
- corpus + baseline + métrica para fuzzy/facets/relevance/recommendations;
- dataset/licença/metodologia/provenance para inteligência de mercado;
- evidência operacional suficiente para trust/moderação avançada;
- tese comercial/parceria concreta para complementares.

## Source of runtime truth

- Estado de branch/PR/checks: Git e GitHub Actions do commit corrente.
- Produto: [`../PRODUCT.md`](../PRODUCT.md).
- Fatos derivados: [`../generated/repository-facts.md`](../generated/repository-facts.md).
- Decisões: [`../MDV.md`](../MDV.md) e [`../adr/`](../adr/).
- Cobertura funcional: [`../audits/2026-08-27-unified-functional-coverage-matrix.md`](../audits/2026-08-27-unified-functional-coverage-matrix.md).
- Consumer contract técnico: [`../audits/2026-08-27-vehicle-technical-sheet-consumer-contract.md`](../audits/2026-08-27-vehicle-technical-sheet-consumer-contract.md).
- CI/migration authority: [`../audits/2026-08-28-ci-smoke-and-migration-authority.md`](../audits/2026-08-28-ci-smoke-and-migration-authority.md).

## Open blockers

- Saved Search runner: deployment contract cross-instance ainda não fechado; PostgreSQL-coordinated claim é o primeiro baseline experimental definido em #117.
- Saved Search external delivery: primeiro experimento definido como e-mail/fake provider, mas produção continua dependente de canal, destinatário verificável, cadence e provider contract (#118).
- Favorite price-drop external delivery: sem opt-in externo específico + provider/canal + durable delivery/recovery contract.
- Comparator/ficha técnica ampla: o contrato quantitativo Podium existe, mas o consumer/comparability benchmark BPT2 #122 ainda precisa ser executado; isso é separado da projeção categórica #111.
- Discovery avançado além da ordenação canônica já entregue: benchmark #112 definido, baseline ainda não executado.
- Inteligência de mercado: sem quantidade/provider/licença/metodologia/provenance concretos (#114).
- Trust/histórico: depende de autorização/contrato/purpose/privacy específicos (#115).
- True radius: depende de autoridade para o ponto físico da Listing e privacy; municipality-code baseline é separado (#116).
- Carros na Web: inventário público atual ainda não reproduzível; acesso direto continua falhando.

## Update rule

Atualize este snapshot somente quando mudar outcome, plano, acceptance target ou blocker real.

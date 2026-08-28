# Current work

Last verified: **2026-08-28**

Este arquivo é um snapshot curto do trabalho corrente. Não é histórico, changelog nem inventário de CI.

## Active outcome

Aposentar o workflow histórico `migration-import.yml` que ainda apontava para `bpt2/` e `bpt2-vertical-slice.yml` já removidos, e fechar a auditoria de smokes HTTP/migration authority.

A auditoria confirmou que todos os `scripts/*-http-smoke.sh` da raiz são executados por gates ativos. Também confirmou que a migration versionada do host pertence à infraestrutura ABP/Identity/OpenIddict, enquanto os cinco módulos de negócio usam migrations efêmeras geradas pelo Fresh Migration Gate.

## Active plan

[`../exec-plans/active/0059-retire-legacy-migration-import.md`](../exec-plans/active/0059-retire-legacy-migration-import.md)

Acceptance: workflow legado removido, fatos em 19 workflows, audit durável, Harness verde e review/base refresh limpos.

## Próximos gatilhos independentes

- delivery externo de Saved Search somente após consentimento por canal, destinatário verificável e estado durável/recovery do side effect;
- delivery externo de Favorite price-drop somente após canal/consentimento/destinatário verificável e durable delivery contract;
- deployment/locking reproduzível para claim/retry/restart do runner de Saved Search;
- medição executável de `powertrain`/`transmission`/`body_style` no Podium para decidir projeção BPT2;
- enrichment técnico publicado suficiente para Comparator;
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

## Open blockers

- Saved Search runner: sem distributed-lock provider/configuração e sem deployment contract cross-instance.
- Saved Search external delivery: sem consentimento de canal comprovado + destinatário verificável + durable delivery/recovery contract.
- Favorite price-drop external delivery: sem provider/canal/consentimento + durable delivery/recovery contract.
- Comparator/ficha técnica ampla: enrichment técnico publicado suficiente do Podium ainda não existe como consumer contract estável.
- Discovery avançado além da ordenação canônica já entregue: sem corpus/baseline/métrica.
- Inteligência de mercado: sem dataset/licença/metodologia/provenance.
- Carros na Web: inventário público atual ainda não reproduzível; acesso direto continua falhando.

## Update rule

Atualize este snapshot somente quando mudar outcome, plano, acceptance target ou blocker real.

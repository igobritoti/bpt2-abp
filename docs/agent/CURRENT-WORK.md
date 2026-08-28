# Current work

Last verified: **2026-08-28**

Este arquivo é um snapshot curto do trabalho corrente. Não é histórico, changelog nem inventário de CI.

## Active outcome

Nenhum execution plan funcional está ativo.

O Plan 0058 removeu o subtree histórico `bpt2/` e aposentou o workflow transitório `bpt2-vertical-slice.yml`. A árvore canônica executável ficou concentrada na raiz atual (`main/`, `modules/`, `public-web/`, `scripts/` e `.github/workflows/`).

O attempt #105 detectou o acoplamento residual do CI; o PR #106 o removeu e provou bootstrap/build/Fresh Migration na raiz antes da remoção definitiva.

## Active plan

Nenhum.

Último concluído: [`../exec-plans/completed/0058-remove-legacy-bpt2-subtree.md`](../exec-plans/completed/0058-remove-legacy-bpt2-subtree.md).

## Próximos gatilhos independentes

- auditar todos os `scripts/*-http-smoke.sh` contra os workflows ativos para localizar provas órfãs de CI;
- auditar a autoridade das migrations versionadas do host/módulos versus o Fresh Migration Gate;
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

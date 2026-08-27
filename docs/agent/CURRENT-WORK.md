# Current work

Last verified: **2026-08-27**

Este arquivo é um snapshot curto do trabalho corrente. Não é histórico, changelog nem inventário de CI.

## Active outcome

Nenhum execution plan funcional está ativo.

O Plan 0053 fechou o gap de seleção guiada de veículo na descoberta pública usando o `VehicleId` canônico já suportado pelo marketplace. O Catalog paginado agora aceita consulta textual por Brand/Model/Generation/Version com a semântica existente, e o public web oferece combobox canônico sem carregar o catálogo inteiro no browser nem duplicar taxonomia automotiva.

O closeout preservou o contrato de metadata do Vehicle Hub: `vehicleRefLabel` continua com sua semântica anterior e a UX enriquecida do seletor usa `vehicleSelectorLabel` próprio. No head funcional `df3df6742a7859423bc8623296b8aaa0d21cae0d`, 17/17 workflows aplicáveis ficaram verdes, incluindo Public Discovery, Public Web, Public Buyer/Vehicle Hub, Harness, Architecture e Fresh Migration.

## Active plan

**Nenhum.**

## Próximos gatilhos independentes

- definir o consumer contract mínimo da ficha técnica/enrichment antes de alterar schema/UI do BPT2 ou solicitar evolução correspondente no Podium;
- deployment/locking reproduzível para claim/retry/restart do runner de Saved Search;
- enrichment técnico publicado do Podium suficiente para Comparator;
- corpus + baseline + métrica para discovery avançado;
- dataset/licença/metodologia/provenance para inteligência de mercado;
- evidência operacional suficiente para trust/moderação avançada;
- tese comercial/parceria concreta para complementares;
- inventário atual reproduzível do Carros na Web.

## Source of runtime truth

- Estado de branch/PR/checks: Git e GitHub Actions do commit corrente.
- Produto: [`../PRODUCT.md`](../PRODUCT.md).
- Fatos derivados: [`../generated/repository-facts.md`](../generated/repository-facts.md).
- Decisões: [`../MDV.md`](../MDV.md) e [`../adr/`](../adr/).
- Seleção canônica concluída: [`../exec-plans/completed/0053-public-canonical-vehicle-selector.md`](../exec-plans/completed/0053-public-canonical-vehicle-selector.md).
- Podium feed concluído: [`../exec-plans/completed/0052-podium-catalog-feed-v1.md`](../exec-plans/completed/0052-podium-catalog-feed-v1.md).
- Roadmap concluído: [`../exec-plans/completed/0049-post-mvp-capability-completion.md`](../exec-plans/completed/0049-post-mvp-capability-completion.md).
- Price-drop concluído: [`../exec-plans/completed/0051-favorite-price-drop-repository-boundary.md`](../exec-plans/completed/0051-favorite-price-drop-repository-boundary.md).
- Cobertura funcional: [`../audits/2026-08-27-unified-functional-coverage-matrix.md`](../audits/2026-08-27-unified-functional-coverage-matrix.md).

## Open blockers

- Saved Search runner: sem distributed-lock provider/configuração e sem deployment contract cross-instance.
- Comparator/ficha técnica ampla: enrichment técnico publicado suficiente do Podium ainda não existe como consumer contract estável.
- Discovery avançado além da seleção canônica: sem corpus/baseline/métrica.
- Inteligência de mercado: sem dataset/licença/metodologia/provenance.
- Carros na Web: inventário público atual ainda não reproduzível; acesso direto continua falhando.

## Update rule

Atualize este snapshot somente quando mudar outcome, plano, acceptance target ou blocker real.

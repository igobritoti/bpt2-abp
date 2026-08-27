# Current work

Last verified: **2026-08-27**

Este arquivo é um snapshot curto do trabalho corrente. Não é histórico, changelog nem inventário de CI.

## Active outcome

Fechar o gap de seleção guiada de veículo na descoberta pública usando o `VehicleId` canônico já suportado pelo marketplace, sem carregar catálogo inteiro no browser e sem duplicar taxonomia automotiva no frontend.

O slice reaproveita o Catalog público existente: `VehicleRefDto` já expõe Brand/Model/Generation/Version/ModelYear e o reader já possuía busca textual pela identidade canônica. A mudança somente torna essa semântica disponível no endpoint paginado e a conecta a um combobox público que submete `vehicleId`.

## Active plan

[`../exec-plans/active/0053-public-canonical-vehicle-selector.md`](../exec-plans/active/0053-public-canonical-vehicle-selector.md)

## Acceptance target

- busca paginada do Catalog por Brand/Model/Generation/Version com a semântica textual já existente;
- seletor público escalável que grava apenas `VehicleId` como valor semântico;
- refresh/paginação preservam a seleção canônica;
- build público + smoke HTTP focado + regressões materialmente acionadas verdes no head exato.

## Próximos gatilhos independentes

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
- Podium feed concluído: [`../exec-plans/completed/0052-podium-catalog-feed-v1.md`](../exec-plans/completed/0052-podium-catalog-feed-v1.md).
- Roadmap concluído: [`../exec-plans/completed/0049-post-mvp-capability-completion.md`](../exec-plans/completed/0049-post-mvp-capability-completion.md).
- Price-drop concluído: [`../exec-plans/completed/0051-favorite-price-drop-repository-boundary.md`](../exec-plans/completed/0051-favorite-price-drop-repository-boundary.md).

## Open blockers

- Saved Search runner: sem distributed-lock provider/configuração e sem deployment contract cross-instance.
- Comparator: enrichment técnico publicado suficiente do Podium.
- Discovery avançado além desta seleção canônica: sem corpus/baseline/métrica.
- Inteligência de mercado: sem dataset/licença/metodologia/provenance.
- Carros na Web: inventário público atual ainda não reproduzível; acesso direto continua falhando.

## Update rule

Atualize este snapshot somente quando mudar outcome, plano, acceptance target ou blocker real.

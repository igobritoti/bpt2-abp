# Current work

Last verified: **2026-08-27**

Este arquivo é um snapshot curto do trabalho corrente. Não é histórico, changelog nem inventário de CI.

## Active outcome

Nenhum execution plan funcional está ativo.

O Plan 0052 fechou o primeiro slice estrutural `Podium 7 -> BPT2 Catalog` usando o contrato Catalog JSON `2.0`. O BPT2 agora possui adapter no Ingestion boundary que preserva `podium7/entity.id` como identidade externa, converge `redirectsFrom` para o mesmo `VehicleId`, mantém replay idempotente e falha explicitamente quando o contrato não pode ser representado sem perda semântica.

`variant = null` permanece não projetável no V1 porque `Vehicle.VersionId` é obrigatório. Model-year range real permanece não projetável porque `Vehicle.ModelYear?` é escalar. Nenhum placeholder ou limite arbitrário é inventado. Comparator continua bloqueado por enrichment técnico publicado insuficiente e não foi ampliado por este slice.

## Active plan

**Nenhum.**

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
- Checkpoint anterior: [`../audits/2026-08-27-post-plan0051-trigger-sweep.md`](../audits/2026-08-27-post-plan0051-trigger-sweep.md).

## Open blockers

- Saved Search runner: sem distributed-lock provider/configuração e sem deployment contract cross-instance.
- Comparator: enrichment técnico publicado suficiente do Podium.
- Discovery avançado: sem corpus/baseline/métrica.
- Inteligência de mercado: sem dataset/licença/metodologia/provenance.
- Carros na Web: inventário público atual ainda não reproduzível; acesso direto continua falhando.

## Update rule

Atualize este snapshot somente quando mudar outcome, plano, acceptance target ou blocker real.

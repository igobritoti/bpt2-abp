# Current work

Last verified: **2026-08-27**

Este arquivo é um snapshot curto do trabalho corrente. Não é histórico, changelog nem inventário de CI.

## Active outcome

Entregar o primeiro slice vertical de integração estrutural `Podium 7 -> BPT2 Catalog` usando somente o contrato Podium Catalog JSON `2.0`, preservando identidade externa estável e sem colocar Podium no request path público.

A nova evidência externa em 2026-08-27 mostrou que o Podium 7 atingiu `PASS` no MVP técnico privado e possui contrato Catalog JSON `2.0` congelado. Isso satisfaz um gatilho que não estava disponível no sweep pós-Plan 0051: integração estrutural do feed de catálogo. Comparator continua bloqueado por enrichment técnico insuficiente e não faz parte deste slice.

## Active plan

[`../exec-plans/active/0052-podium-catalog-feed-v1.md`](../exec-plans/active/0052-podium-catalog-feed-v1.md)

Acceptance target corrente: congelar o adapter `2.0`, resolver fail-closed as incompatibilidades `variant = null` e model-year range, persistir o vínculo `podium7/entity.id -> VehicleId` sem matching por labels e comprovar replay idempotente + redirects históricos.

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
- Plano ativo: [`../exec-plans/active/0052-podium-catalog-feed-v1.md`](../exec-plans/active/0052-podium-catalog-feed-v1.md).
- Roadmap concluído: [`../exec-plans/completed/0049-post-mvp-capability-completion.md`](../exec-plans/completed/0049-post-mvp-capability-completion.md).
- Price-drop concluído: [`../exec-plans/completed/0051-favorite-price-drop-repository-boundary.md`](../exec-plans/completed/0051-favorite-price-drop-repository-boundary.md).
- Checkpoint anterior: [`../audits/2026-08-27-post-plan0051-trigger-sweep.md`](../audits/2026-08-27-post-plan0051-trigger-sweep.md).

## Open blockers

- Plan 0052: `Vehicle.VersionId` é obrigatório enquanto `Podium entity.variant` é nullable; precisa de regra comprovada, não label inventada.
- Plan 0052: Podium publica intervalos de model year, enquanto `Vehicle.ModelYear?` é escalar; não colapsar range arbitrariamente.
- Saved Search runner: sem distributed-lock provider/configuração e sem deployment contract cross-instance.
- Comparator: enrichment técnico publicado suficiente do Podium.
- Discovery avançado: sem corpus/baseline/métrica.
- Inteligência de mercado: sem dataset/licença/metodologia/provenance.
- Carros na Web: inventário público atual ainda não reproduzível; acesso direto continua falhando.

## Update rule

Atualize este snapshot somente quando mudar outcome, plano, acceptance target ou blocker real.

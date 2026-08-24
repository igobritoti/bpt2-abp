# Current work

Last verified: **2026-08-24**

Este arquivo é um snapshot curto do trabalho corrente. Não é histórico, changelog nem inventário de CI.

## Active outcome

Execution Plan 0026 ativo. O menor gap comprovado é adicionar faixa de quilometragem à descoberta pública usando somente `Listing.MileageKm`, já persistido e já projetado no DTO público:

`MileageKm existente → MinMileageKm/MaxMileageKm → home SSR → resultados públicos filtrados`

O slice não decide cor, ranking, facets, engine externa ou qualquer semântica nova de catálogo/geografia.

Próximo acceptance target: provar por HTTP real range inclusivo de quilometragem, range invertido vazio, Draft privado e preservação do filtro na paginação.

## Active plan

[`../exec-plans/active/0026-public-discovery-mileage-filters.md`](../exec-plans/active/0026-public-discovery-mileage-filters.md)

## Source of runtime truth

- Estado de branch/PR/checks: Git e GitHub Actions do commit corrente.
- Fatos estruturais/versões/counters derivados: [`../generated/repository-facts.md`](../generated/repository-facts.md).
- Decisões congeladas: [`../MDV.md`](../MDV.md) e [`../adr/`](../adr/).
- Histórico da metadata social da home: [`../exec-plans/completed/0025-public-home-share-metadata.md`](../exec-plans/completed/0025-public-home-share-metadata.md).

Não copie SHAs, número de testes/checks ou “runtime ready” para este arquivo; consulte as fontes executáveis quando a tarefa depender deles.

## Open blockers

Nenhum blocker de repositório conhecido.

## Update rule

Atualize este snapshot somente quando mudar o outcome ativo, plano ativo, próximo acceptance target ou blocker real. História vai para execution plan concluído/ADR, não para baixo deste arquivo.

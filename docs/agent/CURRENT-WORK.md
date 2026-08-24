# Current work

Last verified: **2026-08-24**

Este arquivo é um snapshot curto do trabalho corrente. Não é histórico, changelog nem inventário de CI.

## Active outcome

Execution Plan 0019 ativo. Fechar a metadata social mínima do Vehicle Hub público:

`Vehicle canônico → /veiculos/{id} → metadata social SSR → link compartilhável coerente`

A mudança deve reutilizar `generateMetadata`, identidade canônica do Catalog e canonical já existentes. Não deve buscar Listing/foto extra, criar imagem social paralela, backend, contrato, schema ou migration.

Próximo acceptance target: provar Open Graph/Twitter coerentes no Vehicle Hub existente e preservar 404/noindex para Vehicle inexistente.

## Active plan

[`../exec-plans/active/0019-public-vehicle-hub-share-metadata.md`](../exec-plans/active/0019-public-vehicle-hub-share-metadata.md)

## Source of runtime truth

- Estado de branch/PR/checks: Git e GitHub Actions do commit corrente.
- Fatos estruturais/versões/counters derivados: [`../generated/repository-facts.md`](../generated/repository-facts.md).
- Decisões congeladas: [`../MDV.md`](../MDV.md) e [`../adr/`](../adr/).
- Histórico de Ingestion Admin Surface: [`../exec-plans/completed/0018-ingestion-admin-surface.md`](../exec-plans/completed/0018-ingestion-admin-surface.md).
- Histórico de Moderation Admin Surface: [`../exec-plans/completed/0017-moderation-admin-surface.md`](../exec-plans/completed/0017-moderation-admin-surface.md).
- Histórico de Listing share metadata: [`../exec-plans/completed/0016-public-listing-share-metadata.md`](../exec-plans/completed/0016-public-listing-share-metadata.md).
- Histórico do Vehicle Hub: [`../exec-plans/completed/0015-public-vehicle-hub.md`](../exec-plans/completed/0015-public-vehicle-hub.md).

Não copie SHAs, número de testes/checks ou “runtime ready” para este arquivo; consulte as fontes executáveis quando a tarefa depender deles.

## Open blockers

Nenhum blocker de repositório conhecido.

## Update rule

Atualize este snapshot somente quando mudar o outcome ativo, plano ativo, próximo acceptance target ou blocker real. História vai para execution plan concluído/ADR, não para baixo deste arquivo.

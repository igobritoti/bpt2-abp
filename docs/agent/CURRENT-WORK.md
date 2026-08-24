# Current work

Last verified: **2026-08-24**

Este arquivo é um snapshot curto do trabalho corrente. Não é histórico, changelog nem inventário de CI.

## Active outcome

Execution Plan 0024 ativo. O menor gap público selecionado fecha a descoberta por sitemap do Seller Hub já entregue:

`Listing público → seller projetado → sitemap.xml → /vendedores/{sellerId}`

O boundary reutiliza somente a varredura pública já existente do sitemap e `sellerId` já projetado em cada Listing público. Não cria endpoint, contrato, backend, schema, migration, slug ou regra de ranking.

Próximo acceptance target: provar por HTTP real que Draft não cria URL de Seller, Publish inclui uma URL deduplicada e Pause da última oferta a remove.

## Active plan

[`../exec-plans/active/0024-public-seller-hub-sitemap.md`](../exec-plans/active/0024-public-seller-hub-sitemap.md)

## Source of runtime truth

- Estado de branch/PR/checks: Git e GitHub Actions do commit corrente.
- Fatos estruturais/versões/counters derivados: [`../generated/repository-facts.md`](../generated/repository-facts.md).
- Decisões congeladas: [`../MDV.md`](../MDV.md) e [`../adr/`](../adr/).
- Histórico da metadata social do Seller Hub: [`../exec-plans/completed/0023-public-seller-hub-share-metadata.md`](../exec-plans/completed/0023-public-seller-hub-share-metadata.md).
- Histórico do Public Seller Hub: [`../exec-plans/completed/0022-public-seller-hub.md`](../exec-plans/completed/0022-public-seller-hub.md).
- Histórico de Vehicle Hub share metadata: [`../exec-plans/completed/0019-public-vehicle-hub-share-metadata.md`](../exec-plans/completed/0019-public-vehicle-hub-share-metadata.md).

Não copie SHAs, número de testes/checks ou “runtime ready” para este arquivo; consulte as fontes executáveis quando a tarefa depender deles.

## Open blockers

Nenhum blocker de repositório conhecido.

## Update rule

Atualize este snapshot somente quando mudar o outcome ativo, plano ativo, próximo acceptance target ou blocker real. História vai para execution plan concluído/ADR, não para baixo deste arquivo.

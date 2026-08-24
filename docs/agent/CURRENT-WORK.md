# Current work

Last verified: **2026-08-24**

Este arquivo é um snapshot curto do trabalho corrente. Não é histórico, changelog nem inventário de CI.

## Active outcome

Execution Plan 0023 ativo. O menor gap público selecionado completa a metadata social do Seller Hub já entregue:

`Seller com oferta pública → /vendedores/{sellerId} → metadata social SSR → link compartilhável coerente`

O boundary reutiliza o `generateMetadata` e a identidade já derivada de Listings públicos. Não cria perfil público paralelo, asset social, schema, migration, contrato, reputação, endereço ou WhatsApp genérico.

Próximo acceptance target: provar por HTTP real que Open Graph/Twitter reutilizam title/description/canonical do Seller Hub e não inventam imagem.

## Active plan

[`../exec-plans/active/0023-public-seller-hub-share-metadata.md`](../exec-plans/active/0023-public-seller-hub-share-metadata.md)

## Source of runtime truth

- Estado de branch/PR/checks: Git e GitHub Actions do commit corrente.
- Fatos estruturais/versões/counters derivados: [`../generated/repository-facts.md`](../generated/repository-facts.md).
- Decisões congeladas: [`../MDV.md`](../MDV.md) e [`../adr/`](../adr/).
- Histórico do Public Seller Hub: [`../exec-plans/completed/0022-public-seller-hub.md`](../exec-plans/completed/0022-public-seller-hub.md).
- Histórico dos filtros públicos de localização: [`../exec-plans/completed/0021-public-discovery-location-filters.md`](../exec-plans/completed/0021-public-discovery-location-filters.md).
- Histórico de Vehicle Hub share metadata: [`../exec-plans/completed/0019-public-vehicle-hub-share-metadata.md`](../exec-plans/completed/0019-public-vehicle-hub-share-metadata.md).

Não copie SHAs, número de testes/checks ou “runtime ready” para este arquivo; consulte as fontes executáveis quando a tarefa depender deles.

## Open blockers

Nenhum blocker de repositório conhecido.

## Update rule

Atualize este snapshot somente quando mudar o outcome ativo, plano ativo, próximo acceptance target ou blocker real. História vai para execution plan concluído/ADR, não para baixo deste arquivo.

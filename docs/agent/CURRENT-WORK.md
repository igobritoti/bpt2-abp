# Current work

Last verified: **2026-08-24**

Este arquivo é um snapshot curto do trabalho corrente. Não é histórico, changelog nem inventário de CI.

## Active outcome

Execution Plan 0023 concluído. O Seller Hub público agora reutiliza sua metadata normal para compartilhamento social:

`Seller com oferta pública → /vendedores/{sellerId} → metadata social SSR → link compartilhável coerente`

Open Graph/Twitter derivam somente de `displayName`, description e canonical já existentes. Sem asset canônico próprio, não há imagem social inventada. Nenhum backend, schema, migration, contrato ou perfil público paralelo foi criado.

Próximo acceptance target: auditar novamente o menor gap real de produto antes de abrir novo execution plan.

## Active plan

Nenhum execution plan ativo.

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

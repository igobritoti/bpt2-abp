# Current work

Last verified: **2026-08-24**

Este arquivo é um snapshot curto do trabalho corrente. Não é histórico, changelog nem inventário de CI.

## Active outcome

Execution Plan 0025 concluído. A home pública agora possui metadata social mínima e explicitamente escopada à rota `/`:

`/ → title/description existentes → Open Graph/Twitter → link compartilhável coerente`

A implementação usa a URL pública já existente, não declara imagem sem asset canônico e não promove metadata social ao root layout. O smoke real prova também ausência de vazamento para `/favoritos`.

Próximo acceptance target: auditar novamente o menor gap real de produto antes de abrir novo execution plan.

## Active plan

Nenhum execution plan ativo.

## Source of runtime truth

- Estado de branch/PR/checks: Git e GitHub Actions do commit corrente.
- Fatos estruturais/versões/counters derivados: [`../generated/repository-facts.md`](../generated/repository-facts.md).
- Decisões congeladas: [`../MDV.md`](../MDV.md) e [`../adr/`](../adr/).
- Histórico da metadata social da home: [`../exec-plans/completed/0025-public-home-share-metadata.md`](../exec-plans/completed/0025-public-home-share-metadata.md).
- Histórico do sitemap do Seller Hub: [`../exec-plans/completed/0024-public-seller-hub-sitemap.md`](../exec-plans/completed/0024-public-seller-hub-sitemap.md).
- Histórico da metadata social do Seller Hub: [`../exec-plans/completed/0023-public-seller-hub-share-metadata.md`](../exec-plans/completed/0023-public-seller-hub-share-metadata.md).

Não copie SHAs, número de testes/checks ou “runtime ready” para este arquivo; consulte as fontes executáveis quando a tarefa depender deles.

## Open blockers

Nenhum blocker de repositório conhecido.

## Update rule

Atualize este snapshot somente quando mudar o outcome ativo, plano ativo, próximo acceptance target ou blocker real. História vai para execution plan concluído/ADR, não para baixo deste arquivo.

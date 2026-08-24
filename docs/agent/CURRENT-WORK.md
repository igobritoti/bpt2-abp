# Current work

Last verified: **2026-08-24**

Este arquivo é um snapshot curto do trabalho corrente. Não é histórico, changelog nem inventário de CI.

## Active outcome

Execution Plan 0025 ativo para fechar metadata social mínima da home pública:

`/ → title/description atuais → Open Graph/Twitter → link compartilhável coerente`

O boundary reutiliza somente metadata e URL pública já existentes, sem imagem social inventada, JSON-LD, ranking, backend, contrato, schema, migration ou endpoint novo.

Próximo acceptance target: provar no HTML real da home Open Graph/Twitter coerentes e ausência de imagem social dedicada, preservando os demais smokes SEO.

## Active plan

[`../exec-plans/active/0025-public-home-share-metadata.md`](../exec-plans/active/0025-public-home-share-metadata.md)

## Source of runtime truth

- Estado de branch/PR/checks: Git e GitHub Actions do commit corrente.
- Fatos estruturais/versões/counters derivados: [`../generated/repository-facts.md`](../generated/repository-facts.md).
- Decisões congeladas: [`../MDV.md`](../MDV.md) e [`../adr/`](../adr/).
- Histórico do sitemap do Seller Hub: [`../exec-plans/completed/0024-public-seller-hub-sitemap.md`](../exec-plans/completed/0024-public-seller-hub-sitemap.md).
- Histórico da metadata social do Seller Hub: [`../exec-plans/completed/0023-public-seller-hub-share-metadata.md`](../exec-plans/completed/0023-public-seller-hub-share-metadata.md).

Não copie SHAs, número de testes/checks ou “runtime ready” para este arquivo; consulte as fontes executáveis quando a tarefa depender deles.

## Open blockers

Nenhum blocker de repositório conhecido.

## Update rule

Atualize este snapshot somente quando mudar o outcome ativo, plano ativo, próximo acceptance target ou blocker real. História vai para execution plan concluído/ADR, não para baixo deste arquivo.

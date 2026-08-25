# Current work

Last verified: **2026-08-25**

Este arquivo é um snapshot curto do trabalho corrente. Não é histórico, changelog nem inventário de CI.

## Active outcome

Os blockers funcionais do MVP identificados no Plan 0027 estão fechados. O primeiro slice pós-MVP priorizado por evidência é melhorar a capacidade central de descoberta sem introduzir ranking subjetivo ou infraestrutura nova.

Plan 0030: adicionar ordenação pública explícita por preço sobre a busca/filtros já existentes, preservando paginação determinística e estado em query string.

Próximo acceptance target: provar por HTTP/SSR que o comprador escolhe menor/maior preço, a API ordena antes da paginação com desempate estável e os links de paginação preservam `sort` junto com os filtros.

## Active plan

[`../exec-plans/active/0030-public-price-sort.md`](../exec-plans/active/0030-public-price-sort.md)

## Source of runtime truth

- Estado de branch/PR/checks: Git e GitHub Actions do commit corrente.
- Fatos estruturais/versões/counters derivados: [`../generated/repository-facts.md`](../generated/repository-facts.md).
- Decisões congeladas: [`../MDV.md`](../MDV.md) e [`../adr/`](../adr/).
- Auditoria de prontidão do MVP: [`../exec-plans/completed/0027-mvp-readiness-audit.md`](../exec-plans/completed/0027-mvp-readiness-audit.md).
- Catálogo canônico operacional: [`../exec-plans/completed/0028-admin-canonical-catalog.md`](../exec-plans/completed/0028-admin-canonical-catalog.md).
- Autoridade mínima de moderação: [`../exec-plans/completed/0029-moderation-listing-authority.md`](../exec-plans/completed/0029-moderation-listing-authority.md).

Não copie SHAs, número de testes/checks ou “runtime ready” para este arquivo; consulte as fontes executáveis quando a tarefa depender deles.

## Open blockers

Nenhum blocker funcional aberto da auditoria MVP 0027. O Plan 0030 é pós-MVP.

## Update rule

Atualize este snapshot somente quando mudar o outcome ativo, plano ativo, próximo acceptance target ou blocker real. História vai para execution plan concluído/ADR, não para baixo deste arquivo.

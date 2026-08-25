# Current work

Last verified: **2026-08-25**

Este arquivo é um snapshot curto do trabalho corrente. Não é histórico, changelog nem inventário de CI.

## Active outcome

Os blockers funcionais do MVP identificados no Plan 0027 continuam fechados. O Plan 0043 está fechando o gap administrativo pós-MVP de navegação global: o usuário `admin` deve alcançar o hub `/admin` pelo menu principal nativo do host ABP/LeptonXLite, sem customizar layout nem criar permission nova.

Próximo acceptance target: `admin autenticado → menu principal → Operações → /admin`, mantendo usuário autenticado sem role `admin` sem esse item e preservando a autorização server-side atual.

## Active plan

[`../exec-plans/active/0043-admin-global-navigation.md`](../exec-plans/active/0043-admin-global-navigation.md)

## Source of runtime truth

- Estado de branch/PR/checks: Git e GitHub Actions do commit corrente.
- Fatos estruturais/versões/counters derivados: [`../generated/repository-facts.md`](../generated/repository-facts.md).
- Decisões congeladas: [`../MDV.md`](../MDV.md) e [`../adr/`](../adr/).
- Auditoria de prontidão do MVP: [`../exec-plans/completed/0027-mvp-readiness-audit.md`](../exec-plans/completed/0027-mvp-readiness-audit.md).
- Catálogo canônico operacional: [`../exec-plans/completed/0028-admin-canonical-catalog.md`](../exec-plans/completed/0028-admin-canonical-catalog.md).
- Autoridade mínima de moderação: [`../exec-plans/completed/0029-moderation-listing-authority.md`](../exec-plans/completed/0029-moderation-listing-authority.md).
- Ordenação pública por preço: [`../exec-plans/completed/0030-public-price-sort.md`](../exec-plans/completed/0030-public-price-sort.md).
- Structured data do Listing: [`../exec-plans/completed/0031-public-listing-structured-data.md`](../exec-plans/completed/0031-public-listing-structured-data.md).
- Sitemap completo de Vehicle Hubs: [`../exec-plans/completed/0032-vehicle-hub-sitemap-pagination.md`](../exec-plans/completed/0032-vehicle-hub-sitemap-pagination.md).
- Structured data do Vehicle Hub: [`../exec-plans/completed/0033-vehicle-hub-structured-data.md`](../exec-plans/completed/0033-vehicle-hub-structured-data.md).
- Busca pública por identidade canônica: [`../exec-plans/completed/0034-public-vehicle-text-search.md`](../exec-plans/completed/0034-public-vehicle-text-search.md).
- Auditoria de qualidade da busca pública: [`../exec-plans/completed/0035-public-search-quality-audit.md`](../exec-plans/completed/0035-public-search-quality-audit.md).
- Prova HTTP de self-registration: [`../exec-plans/completed/0036-self-registration-http-proof.md`](../exec-plans/completed/0036-self-registration-http-proof.md).
- Seller Shell com usuário auto-cadastrado: [`../exec-plans/completed/0037-self-registered-seller-shell.md`](../exec-plans/completed/0037-self-registered-seller-shell.md).
- Buyer Favorites com usuários auto-cadastrados: [`../exec-plans/completed/0038-self-registered-buyer-favorites.md`](../exec-plans/completed/0038-self-registered-buyer-favorites.md).
- Buyer Listing Reports com usuários auto-cadastrados: [`../exec-plans/completed/0039-self-registered-buyer-reports.md`](../exec-plans/completed/0039-self-registered-buyer-reports.md).
- Lead autenticado com UserId real: [`../exec-plans/completed/0040-authenticated-lead-userid-proof.md`](../exec-plans/completed/0040-authenticated-lead-userid-proof.md).
- Lookup de Vehicle canônico na Ingestion: [`../exec-plans/completed/0041-ingestion-vehicle-lookup.md`](../exec-plans/completed/0041-ingestion-vehicle-lookup.md).
- Resumo operacional administrativo: [`../exec-plans/completed/0042-admin-operations-summary.md`](../exec-plans/completed/0042-admin-operations-summary.md).

Não copie SHAs, número de testes/checks ou “runtime ready” para este arquivo; consulte as fontes executáveis quando a tarefa depender deles.

## Open blockers

Nenhum blocker funcional aberto da auditoria MVP 0027. O Plan 0043 é pós-MVP e altera somente descoberta/navegação do host.

## Update rule

Atualize este snapshot somente quando mudar o outcome ativo, plano ativo, próximo acceptance target ou blocker real. História vai para execution plan concluído/ADR, não para baixo deste arquivo.

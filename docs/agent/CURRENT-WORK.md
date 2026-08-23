# Current work

Last verified: **2026-08-23**

Este arquivo é um snapshot curto do trabalho corrente. Não é histórico, changelog nem inventário de CI.

## Active outcome

Execution Plan 0005 ativo. O objetivo corrente é transformar a listagem pública já comprovada em uma experiência mínima de descoberta do Buyer:

`Public Listings → busca/filtros → paginação → detalhe → WhatsApp`

A auditoria de `main` confirmou que o backend já implementa `VehicleId`, `Brand`, `Model`, `MinModelYear`, `MaxModelYear`, `MinPrice`, `MaxPrice`, `Query`, `Skip` e `Take` sob `ListingVisibility.PublicOnly`. O gap é de consumidor: a home Next atual fixa `Skip=0`/`Take=24` e não oferece busca, filtros ou navegação de páginas.

Próximo acceptance target: ligar o contrato existente à query string SSR da home, preservar filtros na paginação e provar o fluxo contra API + Next reais sem adicionar filtro ou infraestrutura nova.

## Active plan

[`../exec-plans/active/0005-public-discovery.md`](../exec-plans/active/0005-public-discovery.md)

## Source of runtime truth

- Estado de branch/PR/checks: Git e GitHub Actions do commit corrente.
- Fatos estruturais/versões/counters derivados: [`../generated/repository-facts.md`](../generated/repository-facts.md).
- Decisões congeladas: [`../MDV.md`](../MDV.md) e [`../adr/`](../adr/).
- Histórico do Seller Self-Service: [`../exec-plans/completed/0004-seller-self-service.md`](../exec-plans/completed/0004-seller-self-service.md).

Não copie SHAs, número de testes/checks ou “runtime ready” para este arquivo; consulte as fontes executáveis quando a tarefa depender deles.

## Open blockers

Nenhum blocker de repositório conhecido. O Plan 0005 não depende de novo backend nem de donor externo para começar.

## Update rule

Atualize este snapshot somente quando mudar o outcome ativo, plano ativo, próximo acceptance target ou blocker real. História vai para execution plan concluído/ADR, não para baixo deste arquivo.

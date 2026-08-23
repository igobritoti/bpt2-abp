# Current work

Last verified: **2026-08-23**

Este arquivo é um snapshot curto do trabalho corrente. Não é histórico, changelog nem inventário de CI.

## Active outcome

Execution Plan 0005 concluído. A experiência pública do Buyer agora consome o contrato de discovery existente sem ampliar o backend:

`Public Listings → busca/filtros → paginação → detalhe → WhatsApp`

A home Next usa query string como estado canônico, mantém SSR/URLs compartilháveis e expõe Query, Brand, Model, faixas de ano/preço e paginação anterior/próxima. O Public Discovery HTTP Gate comprovou em PostgreSQL fresco + host ABP + Next de produção: dois Listings publicados e um Draft, filtros de Query/preço/catálogo, paginação preservando estado, range invertido retornando vazio e Draft permanecendo oculto.

O princípio transversal ADR-0010 também já está integrado em `main`: nova capacidade de infraestrutura exige primeiro necessidade comprovada e avaliação de soluções maduras aplicáveis; adoção ou construção deve deixar decisão durável documentada.

Próximo acceptance target: selecionar por evidência o menor gap real de produto antes de abrir novo execution plan. Nenhum Plan 0006 é presumido apenas porque o Plan 0005 terminou.

## Active plan

Nenhum execution plan ativo.

## Source of runtime truth

- Estado de branch/PR/checks: Git e GitHub Actions do commit corrente.
- Fatos estruturais/versões/counters derivados: [`../generated/repository-facts.md`](../generated/repository-facts.md).
- Decisões congeladas: [`../MDV.md`](../MDV.md) e [`../adr/`](../adr/).
- Histórico do Public Discovery: [`../exec-plans/completed/0005-public-discovery.md`](../exec-plans/completed/0005-public-discovery.md).
- Histórico do Seller Self-Service: [`../exec-plans/completed/0004-seller-self-service.md`](../exec-plans/completed/0004-seller-self-service.md).

Não copie SHAs, número de testes/checks ou “runtime ready” para este arquivo; consulte as fontes executáveis quando a tarefa depender deles.

## Open blockers

Nenhum blocker de repositório conhecido. Decisões futuras de infraestrutura continuam adiadas até necessidade real e passam a seguir ADR-0010 quando forem abertas.

## Update rule

Atualize este snapshot somente quando mudar o outcome ativo, plano ativo, próximo acceptance target ou blocker real. História vai para execution plan concluído/ADR, não para baixo deste arquivo.

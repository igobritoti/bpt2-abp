# Current work

Last verified: **2026-08-24**

Este arquivo é um snapshot curto do trabalho corrente. Não é histórico, changelog nem inventário de CI.

## Active outcome

Execution Plan 0013 concluído. A primeira fatia explícita de SEO técnico público está fechada:

`Listing público → sitemap/robots → crawler descobre URL → detalhe publica canonical`

O public web reutiliza a API pública como autoridade de indexabilidade: Draft/private não entra no sitemap, Publish inclui e Pause remove. `robots.txt` bloqueia superfícies utilitárias/autenticadas e o detalhe público publica canonical absoluto configurado por `BPT_PUBLIC_BASE_URL`.

Próximo acceptance target: auditar novamente o menor gap real de produto antes de abrir novo execution plan.

## Active plan

Nenhum execution plan ativo.

## Source of runtime truth

- Estado de branch/PR/checks: Git e GitHub Actions do commit corrente.
- Fatos estruturais/versões/counters derivados: [`../generated/repository-facts.md`](../generated/repository-facts.md).
- Decisões congeladas: [`../MDV.md`](../MDV.md) e [`../adr/`](../adr/).
- Histórico de SEO técnico: [`../exec-plans/completed/0013-public-seo-discovery.md`](../exec-plans/completed/0013-public-seo-discovery.md).
- Histórico da Moderation Report Inbox: [`../exec-plans/completed/0012-moderation-report-inbox.md`](../exec-plans/completed/0012-moderation-report-inbox.md).

Não copie SHAs, número de testes/checks ou “runtime ready” para este arquivo; consulte as fontes executáveis quando a tarefa depender deles.

## Open blockers

Nenhum blocker de repositório conhecido. JSON-LD, Open Graph, landing pages e estratégia de conteúdo permanecem abertos até evidência suficiente.

## Update rule

Atualize este snapshot somente quando mudar o outcome ativo, plano ativo, próximo acceptance target ou blocker real. História vai para execution plan concluído/ADR, não para baixo deste arquivo.

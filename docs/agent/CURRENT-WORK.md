# Current work

Last verified: **2026-08-24**

Este arquivo é um snapshot curto do trabalho corrente. Não é histórico, changelog nem inventário de CI.

## Active outcome

Execution Plan 0013 aberto para fechar a primeira fatia explícita de SEO técnico público:

`Listing público → sitemap/robots → crawler descobre URL → detalhe publica canonical`

O slice reutiliza exclusivamente a API pública já existente como autoridade de visibilidade. Draft/private não deve entrar no sitemap; Pause deve removê-lo da superfície indexável sem alterar domínio/histórico. Nenhuma regra nova de ranking, conteúdo ou backend será criada.

Próximo acceptance target: provar por HTTP real `robots.txt`, sitemap dinâmico e canonical absoluto usando `BPT_PUBLIC_BASE_URL`.

## Active plan

[`../exec-plans/active/0013-public-seo-discovery.md`](../exec-plans/active/0013-public-seo-discovery.md)

## Source of runtime truth

- Estado de branch/PR/checks: Git e GitHub Actions do commit corrente.
- Fatos estruturais/versões/counters derivados: [`../generated/repository-facts.md`](../generated/repository-facts.md).
- Decisões congeladas: [`../MDV.md`](../MDV.md) e [`../adr/`](../adr/).
- Histórico da Moderation Report Inbox: [`../exec-plans/completed/0012-moderation-report-inbox.md`](../exec-plans/completed/0012-moderation-report-inbox.md).

Não copie SHAs, número de testes/checks ou “runtime ready” para este arquivo; consulte as fontes executáveis quando a tarefa depender deles.

## Open blockers

Nenhum blocker de repositório conhecido.

## Update rule

Atualize este snapshot somente quando mudar o outcome ativo, plano ativo, próximo acceptance target ou blocker real. História vai para execution plan concluído/ADR, não para baixo deste arquivo.

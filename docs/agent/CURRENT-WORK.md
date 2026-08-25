# Current work

Last verified: **2026-08-24**

Este arquivo é um snapshot curto do trabalho corrente. Não é histórico, changelog nem inventário de CI.

## Active outcome

A auditoria de prontidão do MVP foi concluída no Execution Plan 0027. O ciclo funcional já comprovado cobre Seller → Listing → descoberta pública → contato/Lead, Buyer favorites/report e superfícies operacionais existentes, mas restam dois blockers funcionais antes de considerar o núcleo do MVP operacionalmente fechado:

1. **carga operacional do catálogo canônico** — os gates criam `Brand → Model → Generation → Version → Vehicle` por fixture de teste; não existe superfície suportada do produto para popular um ambiente novo;
2. **ação mínima de moderação** — Buyer reporta e admin consulta a fila, mas o operador ainda não possui autoridade de produto para retirar/restaurar a visibilidade do Listing denunciado.

Os demais gaps auditados foram classificados como pós-MVP até nova evidência alterar sua necessidade.

Próximo acceptance target: fechar o primeiro blocker com uma superfície admin mínima que consiga criar identidade automotiva canônica usando os aggregates atuais, sem connector/importador, automação ou nova infraestrutura.

## Active plan

Nenhum execution plan ativo.

## Source of runtime truth

- Estado de branch/PR/checks: Git e GitHub Actions do commit corrente.
- Fatos estruturais/versões/counters derivados: [`../generated/repository-facts.md`](../generated/repository-facts.md).
- Decisões congeladas: [`../MDV.md`](../MDV.md) e [`../adr/`](../adr/).
- Auditoria de prontidão do MVP: [`../exec-plans/completed/0027-mvp-readiness-audit.md`](../exec-plans/completed/0027-mvp-readiness-audit.md).
- Histórico da descoberta por quilometragem: [`../exec-plans/completed/0026-public-discovery-mileage-filters.md`](../exec-plans/completed/0026-public-discovery-mileage-filters.md).

Não copie SHAs, número de testes/checks ou “runtime ready” para este arquivo; consulte as fontes executáveis quando a tarefa depender deles.

## Open blockers

- **MVP-01 — catálogo canônico:** ambiente novo não possui caminho operacional suportado para criar o Vehicle canônico exigido por Listing.
- **MVP-02 — moderação:** operador lê denúncias, mas ainda não consegue retirar/restaurar Listing por autoridade administrativa do produto.

## Update rule

Atualize este snapshot somente quando mudar o outcome ativo, plano ativo, próximo acceptance target ou blocker real. História vai para execution plan concluído/ADR, não para baixo deste arquivo.

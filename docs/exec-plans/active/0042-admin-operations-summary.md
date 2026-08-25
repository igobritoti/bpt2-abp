# Execution Plan 0042 — Admin Operations Summary

Status: **ATIVO**

## Objetivo

Fechar a primeira fatia do dashboard/métricas administrativas explicitamente deixada aberta no Plan 0020, sem criar domínio, política ou endpoint de métricas: o hub `/admin` deve resumir o estado operacional já disponível nos módulos existentes.

Vertical proof:

`admin login → /admin → Vehicles canônicos / reports recebidos / candidates pendentes → links operacionais existentes`

## Contexto

Base remota verificada: `17125f30d0a0196def61f1516a9ddb8f360d147e`, após o merge do Plan 0041.

Evidência atual:

- o Plan 0020 deixou explicitamente `dashboard/métricas` fora do primeiro hub administrativo;
- `/admin` hoje é somente um conjunto de links e seu PageModel não consulta nenhum dado;
- `IVehicleCatalogReader.GetAllIdsAsync` já expõe os Vehicles canônicos existentes;
- `IModerationListingReportQuery.GetAsync` já expõe a fila/histórico read-only de reports sem PII Buyer;
- `IIngestionCandidateAppService.GetPendingAsync` já expõe somente candidates ainda não reconciliados;
- `/catalogo`, `/moderacao` e `/ingestao` continuam as superfícies operacionais autoritativas; o hub deve apenas resumir e navegar.

## Escopo

- fazer `/admin` carregar dados somente pelos contracts existentes de Catalog, Marketplace e Ingestion;
- exibir total de Vehicles canônicos;
- exibir total histórico de reports recebidos, sem chamar esse número de “pendente” ou “aberto”;
- exibir total de candidates de Ingestion pendentes;
- manter os links atuais para `/catalogo`, `/moderacao` e `/ingestao`;
- estender o smoke existente do Admin Operations Hub para provar que as contagens são derivadas do runtime;
- reutilizar o Product API Gate existente.

## Fora de escopo

- estado/resolução de report;
- SLA, alertas, gráficos ou séries temporais;
- analytics de negócio;
- permissões granulares;
- endpoint dedicado de métricas/count;
- cache ou materialização de métricas;
- migration/schema/infra;
- novo workflow.

## Critérios de aceite

1. [ ] `/admin` continua restrito à role `admin`.
2. [ ] hub exibe total de Vehicles canônicos existente no Catalog.
3. [ ] hub exibe total histórico de reports recebidos sem inventar estado de resolução.
4. [ ] hub exibe total de candidates pendentes de Ingestion.
5. [ ] adicionar um candidate pendente altera dinamicamente a contagem exibida.
6. [ ] links para Catálogo, Moderação e Ingestão continuam presentes e alcançáveis.
7. [ ] nenhuma regra de domínio, schema, endpoint de métrica ou infraestrutura é adicionada.

## Decision log

- **DECIDIDO por evidência:** dashboard/métricas é gap explicitamente documentado no Plan 0020.
- **DECIDIDO:** primeira versão usa apenas contracts read-only existentes; não criar APIs de contagem sem evidência de escala.
- **DECIDIDO:** reports são contados como histórico recebido, porque o produto ainda não possui estado de resolução.
- **DECIDIDO:** o hub continua sem autoridade de escrita; ações permanecem nas superfícies específicas.

## Progress log

- 2026-08-25: `main` remoto confirmado em `17125f30d0a0196def61f1516a9ddb8f360d147e`.
- 2026-08-25: `/admin` confirmado como hub estático sem consulta de dados.
- 2026-08-25: contracts existentes confirmados para Catalog, Moderation reports e Ingestion pending.

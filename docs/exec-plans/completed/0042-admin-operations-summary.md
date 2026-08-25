# Execution Plan 0042 — Admin Operations Summary

Status: **CONCLUÍDO**

## Objetivo

Fechar a primeira fatia do dashboard/métricas administrativas explicitamente deixada aberta no Plan 0020, sem criar domínio, política ou endpoint de métricas: o hub `/admin` resume o estado operacional já disponível nos módulos existentes.

Vertical proof:

`admin login → /admin → Vehicles canônicos / reports recebidos / candidates pendentes → links operacionais existentes`

## Contexto

Base remota verificada: `17125f30d0a0196def61f1516a9ddb8f360d147e`, após o merge do Plan 0041.

Evidência:

- o Plan 0020 deixou explicitamente `dashboard/métricas` fora do primeiro hub administrativo;
- `/admin` era somente um conjunto de links e seu PageModel não consultava dados;
- `IVehicleCatalogReader.FindIdsAsync` com `VehicleCatalogSearchInput` sem filtros retorna todos os `VehicleId` canônicos existentes;
- `IModerationListingReportQuery.GetAsync` expõe o histórico read-only de reports sem PII Buyer;
- `IIngestionCandidateAppService.GetPendingAsync` expõe somente candidates ainda não reconciliados;
- `/catalogo`, `/moderacao` e `/ingestao` permanecem as superfícies operacionais autoritativas.

## Implementação

- `/admin` passou a carregar dados exclusivamente por contracts existentes de Catalog, Marketplace e Ingestion;
- exibe total de Vehicles canônicos;
- exibe total histórico de reports como `Reports recebidos`, sem inventar estado aberto/resolvido;
- exibe total de candidates pendentes de Ingestion;
- preserva os links para Catálogo, Moderação e Ingestão;
- smoke focal prova as contagens de runtime e que adicionar um candidate aumenta a contagem pendente exatamente em 1;
- nenhuma migration, schema, endpoint de métricas, cache ou infraestrutura foi adicionada.

## Fora de escopo preservado

- estado/resolução de report;
- SLA, alertas, gráficos ou séries temporais;
- analytics de negócio;
- permissões granulares;
- endpoint dedicado de métricas/count;
- cache ou materialização de métricas;
- migration/schema/infra;
- novo workflow.

## Critérios de aceite

1. [x] `/admin` continua restrito à role `admin`.
2. [x] hub exibe total de Vehicles canônicos existente no Catalog.
3. [x] hub exibe total histórico de reports recebidos sem inventar estado de resolução.
4. [x] hub exibe total de candidates pendentes de Ingestion.
5. [x] adicionar um candidate pendente altera dinamicamente a contagem exibida.
6. [x] links para Catálogo, Moderação e Ingestão continuam presentes e alcançáveis.
7. [x] nenhuma regra de domínio, schema, endpoint de métrica ou infraestrutura foi adicionada.

## Decision log

- **DECIDIDO por evidência:** dashboard/métricas era gap explicitamente documentado no Plan 0020.
- **DECIDIDO:** primeira versão usa apenas contracts read-only existentes; não criar APIs de contagem sem evidência de escala.
- **DECIDIDO:** reports são contados como histórico recebido, porque o produto ainda não possui estado de resolução.
- **DECIDIDO:** o hub continua sem autoridade de escrita; ações permanecem nas superfícies específicas.
- **CORRIGIDO por execução:** a primeira implementação tentou usar `IVehicleCatalogReader.GetAllIdsAsync`, método inexistente, produzindo `CS1061` no build. A implementação foi corrigida para `FindIdsAsync` com filtro vazio, comportamento confirmado no `VehicleCatalogReader` atual.

## Evidência de execução

- primeira rodada: Harness passou e os demais gates que compilam host falharam pelo mesmo `CS1061`, isolando uma causa comum;
- após a correção: Host Gate passou `Build host and modules`;
- Product API Gate passou fresh migration, seed, APIs existentes, Ingestion reconcile, Ingestion Vehicle lookup, admin hub e o smoke focal `Exercise admin operations summary`;
- smoke focal comprovou que o resumo lê valores reais do runtime e reage à criação de candidate pendente.

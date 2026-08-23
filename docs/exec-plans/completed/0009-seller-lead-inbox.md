# Execution Plan 0009 — Seller Lead Inbox

Status: **COMPLETO**

## Objetivo

Fechar o menor gap vertical restante depois da ativação e atribuição de Leads:

`WhatsApp Lead persistido → Seller autenticado → ver Leads dos próprios anúncios`

## Evidência de partida

- Plans 0007/0008 já persistem Leads reais no Marketplace.
- `Lead` já contém `ListingId`, `UserId?`, `Channel` e `CreatedAtUtc`; nenhuma migration é necessária.
- `Listing.SellerId` e `ICurrentUser` já sustentam ownership Seller no Marketplace.
- O shell Seller já usa HTTP/OIDC e não possuía leitura de Leads.
- Seller inbox era explicitamente uma decisão aberta em `PRODUCT.md`.

## Escopo concluído

- query autenticada mínima para Leads pertencentes aos Listings do Seller corrente;
- DTO suficiente para exibir Listing, canal, instante e BuyerUserId opcional;
- painel de Leads no shell `/vender`;
- gate HTTP provando ownership e integração sem migration/infra nova;
- documentação canônica.

## Fora de escopo

- CRM, scoring, status de atendimento, notas, exportação;
- resolução de PII/perfil Buyer;
- agregados/analytics;
- deduplicação/rate limiting;
- filas, jobs ou infraestrutura nova.

## Critérios de aceite

1. [x] Seller autenticado vê Leads apenas dos próprios Listings.
2. [x] Segundo Seller não vê Lead do primeiro.
3. [x] Lead anônimo continua representável com `BuyerUserId = null`.
4. [x] Shell Seller mostra a lista sem depender de estado público do Listing.
5. [x] Nenhuma migration ou infraestrutura nova.
6. [x] Gates afetados e regressões permanecem verdes.

## Progress log

- 2026-08-23: `main` refetchado em `49e6bdea9e4c11c84a53380a87319adf70724645`, já contendo o Plan 0008 via PR #27.
- 2026-08-23: auditoria de PRODUCT, LeadAppService, SellerListingQuery e shell `/vender` selecionou Seller Lead Inbox como menor gap vertical real.
- 2026-08-23: primeiro run mostrou que a nova interface não herdava `IApplicationService`; o contrato foi alinhado ao padrão já usado por `ISellerListingQuery`, e a rota convencional passou a aparecer no Swagger.
- 2026-08-23: um run seguinte encontrou somente um erro de fixture Bash em declaração `local` sob `set -u`; o script foi corrigido sem alteração de produto.
- 2026-08-23: o primeiro erro funcional real foi um 500 do EF Core. O log executado mostrou que `OrderBy` após a projeção em `SellerLeadDto` não era traduzível. A query foi reescrita para ordenar as colunas de `Lead` antes da projeção, mantendo o mesmo JOIN/filtro de ownership.
- 2026-08-23: no head funcional `2a0dc550086bb2716a4f28dbdcc8b31f88d363f5`, `SELLER_LEADS_ROUTE`, `SELLER_LEADS_ANONYMOUS_BLOCKED`, `SELLER_LEADS_OWNER_VISIBLE`, `SELLER_LEADS_OWNERSHIP`, `SELLER_LEADS_HISTORY_PRESERVED` e `SELLER LEADS HTTP` passaram.
- 2026-08-23: os 16 workflows aplicáveis passaram no mesmo head funcional; nenhuma migration, workflow novo ou infraestrutura foi adicionada.

## Decision log

- Ownership é derivado por `Lead JOIN Listing WHERE Listing.SellerId == ICurrentUser.Id`; nenhum SellerId entra pelo cliente.
- A inbox retorna somente metadados já existentes do Lead e título do Listing; não cria perfil/PII Buyer.
- Leads permanecem visíveis ao Seller mesmo se o Listing depois for Pause/Archive, pois são histórico de contato já ocorrido.
- A rota usa conventional controller do ABP via `IApplicationService`; não foi criado controller customizado.
- Ordenação é executada antes da projeção DTO para permanecer traduzível pelo EF Core/Npgsql; isso é detalhe de implementação observado em runtime, não mudança de regra de domínio.

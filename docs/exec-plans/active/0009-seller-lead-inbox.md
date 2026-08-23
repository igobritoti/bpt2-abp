# Execution Plan 0009 — Seller Lead Inbox

Status: **ATIVO**

## Objetivo

Fechar o menor gap vertical restante depois da ativação e atribuição de Leads:

`WhatsApp Lead persistido → Seller autenticado → ver Leads dos próprios anúncios`

## Evidência de partida

- Plans 0007/0008 já persistem Leads reais no Marketplace.
- `Lead` já contém `ListingId`, `UserId?`, `Channel` e `CreatedAtUtc`; nenhuma migration é necessária.
- `Listing.SellerId` e `ICurrentUser` já sustentam ownership Seller no Marketplace.
- O shell Seller já usa HTTP/OIDC e não possui leitura de Leads.
- Seller inbox é explicitamente uma decisão aberta em `PRODUCT.md`.

## Escopo

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

1. [ ] Seller autenticado vê Leads apenas dos próprios Listings.
2. [ ] Segundo Seller não vê Lead do primeiro.
3. [ ] Lead anônimo continua representável com `BuyerUserId = null`.
4. [ ] Shell Seller mostra a lista sem depender de estado público do Listing.
5. [ ] Nenhuma migration ou infraestrutura nova.
6. [ ] Gates afetados e regressões permanecem verdes.

## Progress log

- 2026-08-23: `main` refetchado em `49e6bdea9e4c11c84a53380a87319adf70724645`, já contendo o Plan 0008 via PR #27.
- 2026-08-23: auditoria de PRODUCT, LeadAppService, SellerListingQuery e shell `/vender` selecionou Seller Lead Inbox como menor gap vertical real.

## Decision log

- Ownership será derivado por `Lead JOIN Listing WHERE Listing.SellerId == ICurrentUser.Id`; nenhum SellerId entra pelo cliente.
- A inbox retorna somente metadados já existentes do Lead e título do Listing; não cria perfil/PII Buyer.
- Leads permanecem visíveis ao Seller mesmo se o Listing depois for Pause/Archive, pois são histórico de contato já ocorrido.

# Execution Plan 0007 — WhatsApp Lead Capture

Status: **CONCLUÍDO**

## Objetivo

Fechar o menor gap vertical real restante aproveitando a estrutura `Lead` já existente:

`Public Detail → WhatsApp CTA → persist Lead → abrir conversa`

## Evidência de partida

- `Lead` já existia no domínio Marketplace com `ListingId`, `UserId?`, `Channel` e `CreatedAtUtc`.
- `MarketplaceDbContext` já mapeava `MarketplaceLeads`; nenhuma migration nova era necessária.
- O detalhe público já possuía CTA WhatsApp e `SellerPublicContactDto` já fornecia o número canônico.
- O fluxo anterior abria `wa.me` diretamente e não registrava Lead.
- Leads e contato/WhatsApp são capacidade central do produto; analytics/CRM permanecem fora deste slice.

Classificação final:

- **PASSA / DECIDIDO:** contato WhatsApp público persiste Lead mínimo.
- **PASSA / DECIDIDO:** somente Listing atualmente público pode gerar novo Lead.
- **PASSA / DECIDIDO:** canal persistido neste slice é `WhatsApp`.
- **PASSA / DECIDIDO:** `UserId` é opcional; contato anônimo continua permitido.
- **NÃO DECIDIDO:** deduplicação, scoring, CRM, atribuição, analytics agregados e Seller inbox.

## Escopo entregue

- contrato/app service público mínimo para registrar contato WhatsApp;
- validação server-side de visibilidade pública antes da persistência;
- CTA público passa pelo registro antes de abrir `wa.me`;
- gate HTTP focado com PostgreSQL fresco, host real e Next.js de produção;
- documentação canônica e MDV.

## Fora de escopo

- CRM;
- dashboard/analytics de Lead;
- Seller inbox;
- deduplicação/rate limiting além das proteções já existentes da aplicação;
- novos providers, filas ou background jobs;
- migration ou infraestrutura nova.

## Critérios de aceite

1. [x] Draft/private não gera Lead.
2. [x] Listing público aceita registro de contato WhatsApp.
3. [x] Lead persistido referencia o Listing e canal `WhatsApp`.
4. [x] `UserId` permanece opcional para contato público anônimo.
5. [x] CTA no detalhe público registra contato e continua abrindo o WhatsApp canônico do Seller.
6. [x] Pause/Archive voltam a bloquear novo registro de Lead.
7. [x] Gates diretamente afetados permanecem verdes.
8. [x] Nenhuma migration ou infraestrutura nova é adicionada.

## Checkpoints

- [x] Auditar domínio, DbContext, CTA público e gap documental.
- [x] Implementar contrato e backend.
- [x] Integrar o CTA público.
- [x] Provar comportamento real e regressões.
- [x] Atualizar documentação e arquivar o plano.

## Evidência executada

Head funcional provado: `052313bacde57adc68dad1fb0736b7aff198b2c9`.

O Public Buyer HTTP Gate executou PostgreSQL 17 fresco, host ABP real e Next.js 16.2.12 de produção e registrou:

- `PUBLIC_LEAD_ROUTE: PASS`
- `PUBLIC_LEAD_DRAFT_BLOCKED: PASS`
- `PUBLIC_WEB_DRAFT_PRIVATE: PASS`
- `PUBLIC_LEAD_PERSISTED: PASS`
- `PUBLIC_WEB_LIST: PASS`
- `PUBLIC_WEB_DETAIL: PASS`
- `PUBLIC_WEB_METADATA: PASS`
- `PUBLIC_WEB_WHATSAPP_LEAD: PASS`
- `PUBLIC_WEB_PHOTO: PASS`
- `PUBLIC_LEAD_PAUSED_BLOCKED: PASS`
- `PUBLIC_LEAD_ARCHIVED_BLOCKED: PASS`
- `PUBLIC BUYER HTTP FLOW: PASSED`

Nesse head passaram **16/16 workflows aplicáveis**: Architecture, Harness, Host, Fresh Migration, Gate 01, Product API, Listing Lifecycle, Listing Photo, Public Web, Public Buyer, Public Discovery, Buyer Favorites e todos os gates Seller.

## Progress log

- 2026-08-23: `main` foi refetchado em `fceecd089818f5482a354c206f4f583bb0b1ca45`; PR #25 já havia fechado a prova de isolamento de Favorites e não foi reaberto.
- 2026-08-23: auditoria de `PRODUCT.md`, `MDV.md`, `Lead`, `MarketplaceDbContext` e detalhe público selecionou Lead capture como menor gap vertical real.
- 2026-08-23: contrato/app service de Lead e integração Next foram implementados sem migration, controller customizado ou infraestrutura nova.
- 2026-08-23: o gate público foi ampliado para observar a rota pelo Swagger, bloquear Draft/Pause/Archive, validar o Lead anônimo persistido e provar o redirect ao WhatsApp canônico.
- 2026-08-23: primeiro Harness Gate de um head intermediário falhou somente porque o plano ainda não tinha `Progress log`/`Decision log` e os fatos gerados ainda diziam zero planos ativos; ambos foram corrigidos no head seguinte, que passou.
- 2026-08-23: um Public Buyer run intermediário provou rota, bloqueio de Draft, persistência e redirect 303 canônico, mas falhou por uma regex do próprio gate que tratava CRLF do header `Location` incorretamente. A asserção foi corrigida sem alteração de produto.
- 2026-08-23: head `052313bacde57adc68dad1fb0736b7aff198b2c9` passou 16/16 workflows e fechou a evidência funcional.

## Decision log

- Usar a estrutura `Lead` já existente em Marketplace em vez de introduzir novo aggregate ou módulo.
- Reutilizar `IPublicListingQuery` como autoridade de visibilidade: só Listing atualmente público pode gerar novo Lead.
- Fixar o canal deste slice como `WhatsApp` e preservar `UserId` opcional para contato anônimo.
- Usar a convenção HTTP gerada pelo ABP e validar a rota real no Swagger; não criar controller/rota artificial.
- Fazer o public web registrar o Lead por POST antes de redirecionar para o `wa.me` canônico, sem confiar em número informado pelo browser.
- Manter CRM, analytics agregados, deduplicação, scoring, Seller inbox, filas e background jobs fora do slice até necessidade comprovada.

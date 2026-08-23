# Execution Plan 0007 — WhatsApp Lead Capture

Status: **ATIVO**

## Objetivo

Fechar o menor gap vertical real restante aproveitando a estrutura `Lead` já existente:

`Public Detail → WhatsApp CTA → persist Lead → abrir conversa`

## Evidência de partida

- `Lead` já existe no domínio Marketplace com `ListingId`, `UserId?`, `Channel` e `CreatedAtUtc`.
- `MarketplaceDbContext` já mapeia `MarketplaceLeads`; nenhuma migration nova é necessária.
- O detalhe público já possui CTA WhatsApp e `SellerPublicContactDto` já fornece o número canônico.
- O fluxo atual abre `wa.me` diretamente e explicitamente não registra Lead/analytics/CRM.
- Leads e contato/WhatsApp são capacidade central do produto; analytics/CRM continuam opcionais e fora deste slice.

Classificação inicial:

- **PASSA:** domínio e persistência de Lead já existem.
- **NÃO PASSA:** clique público no WhatsApp ainda não registra Lead.
- **DECIDIDO:** registrar somente quando o Listing estiver publicável no momento da chamada.
- **DECIDIDO:** canal persistido neste slice é `WhatsApp`.
- **DECIDIDO:** `UserId` é opcional; contato anônimo continua permitido.
- **NÃO DECIDIDO:** deduplicação, scoring, CRM, atribuição, analytics agregados e Seller inbox.

## Escopo

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

1. [ ] Draft/private não gera Lead.
2. [ ] Listing público aceita registro de contato WhatsApp.
3. [ ] Lead persistido referencia o Listing e canal `WhatsApp`.
4. [ ] `UserId` permanece opcional para contato público anônimo.
5. [ ] CTA no detalhe público registra contato e continua abrindo o WhatsApp canônico do Seller.
6. [ ] Pause/Archive voltam a bloquear novo registro de Lead.
7. [ ] Gates diretamente afetados permanecem verdes.
8. [ ] Nenhuma migration ou infraestrutura nova é adicionada.

## Checkpoints

- [x] Auditar domínio, DbContext, CTA público e gap documental.
- [ ] Implementar contrato e backend.
- [ ] Integrar o CTA público.
- [ ] Provar comportamento real e regressões.
- [ ] Atualizar documentação e arquivar o plano.

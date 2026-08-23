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
- [x] Implementar contrato e backend.
- [x] Integrar o CTA público.
- [ ] Provar comportamento real e regressões.
- [ ] Atualizar documentação e arquivar o plano.

## Progress log

- 2026-08-23: `main` foi refetchado em `fceecd089818f5482a354c206f4f583bb0b1ca45`; PR #25 já havia fechado a prova de isolamento de Favorites e não foi reaberto.
- 2026-08-23: auditoria de `PRODUCT.md`, `MDV.md`, `Lead`, `MarketplaceDbContext` e detalhe público selecionou Lead capture como menor gap vertical real.
- 2026-08-23: contrato/app service de Lead e integração Next foram implementados sem migration, controller customizado ou infraestrutura nova.
- 2026-08-23: o gate público foi ampliado para observar a rota pelo Swagger, bloquear Draft/Pause/Archive, validar o Lead anônimo persistido e provar o redirect ao WhatsApp canônico.
- 2026-08-23: primeiro Harness Gate de um head intermediário falhou somente porque este plano ainda não tinha `Progress log`/`Decision log` e os fatos gerados ainda diziam zero planos ativos; ambos foram corrigidos no head seguinte.

## Decision log

- Usar a estrutura `Lead` já existente em Marketplace em vez de introduzir novo aggregate ou módulo.
- Reutilizar `IPublicListingQuery` como autoridade de visibilidade: só Listing atualmente público pode gerar novo Lead.
- Fixar o canal deste slice como `WhatsApp` e preservar `UserId` opcional para contato anônimo.
- Usar a convenção HTTP gerada pelo ABP e validar a rota real no Swagger; não criar controller/rota artificial.
- Fazer o public web registrar o Lead por POST antes de redirecionar para o `wa.me` canônico, sem confiar em número informado pelo browser.
- Manter CRM, analytics agregados, deduplicação, scoring, Seller inbox, filas e background jobs fora do slice até necessidade comprovada.

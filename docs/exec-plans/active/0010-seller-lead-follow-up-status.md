# Execution Plan 0010 — Seller Lead Follow-up Status

Status: **ATIVO**

## Objetivo

Fechar o menor gap operacional restante depois da Seller Lead Inbox:

`Lead novo → Seller owner marca contato como atendido → inbox preserva o instante`

## Evidência de partida

- Plan 0009 entrega Leads ownership-safe no shell Seller.
- `Lead` ainda contém somente identidade, canal e instante de criação; não há estado mínimo de atendimento.
- `PRODUCT.md` mantém status/notas de atendimento como decisão aberta.
- O primeiro incremento não precisa de CRM, notas, pipeline, scoring ou novo módulo.

## Escopo

- `ContactedAtUtc?` no aggregate `Lead` como estado mínimo e auditável;
- command autenticado que deriva Seller de `ICurrentUser` e só altera Lead de Listing próprio;
- inbox Seller exibe Novo/Atendido e permite marcar como atendido;
- gate HTTP prova autenticação, ownership e persistência;
- nenhuma infraestrutura nova.

## Fora de escopo

- notas, responsável, etapas comerciais, reabertura, scoring, CRM, exportação;
- perfil/PII Buyer;
- jobs, filas ou notificações.

## Critérios de aceite

1. [ ] Lead novo retorna `ContactedAtUtc = null`.
2. [ ] Anônimo não pode marcar Lead como atendido.
3. [ ] Segundo Seller não pode marcar Lead de outro Seller.
4. [ ] Seller owner pode marcar como atendido.
5. [ ] Inbox posterior retorna `ContactedAtUtc` persistido.
6. [ ] UI Seller oferece a ação sem expor SellerId no cliente.
7. [ ] Fresh migration e regressões aplicáveis permanecem verdes.

## Progress log

- 2026-08-23: `main` refetchado em `270716958100e8346c3c0514298118b5eb2bb7d6`, já contendo Plan 0009 via PR #28.
- 2026-08-23: auditoria de `PRODUCT.md`, `Lead`, `MarketplaceDbContext` e inbox Seller selecionou follow-up mínimo como próximo gap vertical.

## Decision log

- O estado mínimo será `ContactedAtUtc?`, não enum/pipeline: `null` significa novo; timestamp UTC significa atendido.
- A autorização usa `Lead JOIN Listing WHERE Listing.SellerId == ICurrentUser.Id`; `SellerId` não entra pelo cliente.
- A ação é monotônica/idempotente: chamadas repetidas preservam o primeiro instante de atendimento.

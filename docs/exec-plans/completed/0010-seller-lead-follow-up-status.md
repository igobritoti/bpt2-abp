# Execution Plan 0010 — Seller Lead Follow-up Status

Status: **CONCLUÍDO**

## Objetivo

Fechar o menor gap operacional restante depois da Seller Lead Inbox:

`Lead novo → Seller owner marca contato como atendido → inbox preserva o instante`

## Evidência de partida

- Plan 0009 entrega Leads ownership-safe no shell Seller.
- `Lead` continha somente identidade, canal e instante de criação; não havia estado mínimo de atendimento.
- `PRODUCT.md` mantinha status/notas de atendimento como decisão aberta.
- O primeiro incremento não exigia CRM, notas, pipeline, scoring ou novo módulo.

## Escopo concluído

- `ContactedAtUtc?` no aggregate `Lead` como estado mínimo e auditável;
- command autenticado que deriva Seller de `ICurrentUser` e só altera Lead de Listing próprio;
- inbox Seller exibe Novo/Atendido e permite marcar como atendido;
- gate HTTP prova autenticação, ownership, persistência e idempotência;
- nenhuma infraestrutura nova.

## Fora de escopo

- notas, responsável, etapas comerciais, reabertura, scoring, CRM, exportação;
- resolução de PII/perfil Buyer;
- jobs, filas ou notificações.

## Critérios de aceite

1. [x] Lead novo retorna `ContactedAtUtc = null`.
2. [x] Anônimo não pode marcar Lead como atendido.
3. [x] Segundo Seller não pode marcar Lead de outro Seller.
4. [x] Seller owner pode marcar como atendido.
5. [x] Inbox posterior retorna `ContactedAtUtc` persistido.
6. [x] UI Seller oferece a ação sem expor SellerId no cliente.
7. [x] Fresh migration e regressões aplicáveis permanecem verdes.

## Evidência executada

Head funcional: `c3c811cbb0f1811e3348990fa80a27c11a351558`.

- 16/16 workflows aplicáveis verdes.
- `SELLER_LEADS_FOLLOW_UP_ROUTE: PASS`
- `SELLER_LEADS_NEW_STATUS: PASS`
- `SELLER_LEADS_FOLLOW_UP_ANONYMOUS_BLOCKED: PASS`
- `SELLER_LEADS_FOLLOW_UP_OWNERSHIP: PASS`
- `SELLER_LEADS_FOLLOW_UP_PERSISTED: PASS`
- `SELLER_LEADS_FOLLOW_UP_IDEMPOTENT: PASS`
- `SELLER_LEADS_HISTORY_PRESERVED: PASS`
- `SELLER LEADS HTTP: PASSED`
- `FRESH MIGRATION GATE: PASSED`
- Public Web/Seller Shell e fluxo Seller anterior permaneceram verdes.

Classe: **B — comportamento observado/reproduzido no CI do BPT2**.

## Progress log

- 2026-08-23: `main` refetchado em `270716958100e8346c3c0514298118b5eb2bb7d6`, já contendo Plan 0009 via PR #28.
- 2026-08-23: auditoria de `PRODUCT.md`, `Lead`, `MarketplaceDbContext` e inbox Seller selecionou follow-up mínimo como próximo gap vertical.
- 2026-08-23: implementação adicionou somente `ContactedAtUtc?`, command ownership-safe e ação no shell Seller.
- 2026-08-23: head funcional `c3c811cbb0f1811e3348990fa80a27c11a351558` fechou 16/16 workflows verdes; gate focal comprovou ownership, persistência, idempotência e histórico após Pause.

## Decision log

- O estado mínimo é `ContactedAtUtc?`, não enum/pipeline: `null` significa novo; timestamp UTC significa atendido.
- A autorização usa `Lead JOIN Listing WHERE Listing.SellerId == ICurrentUser.Id`; nenhum `SellerId` entra pelo cliente.
- A ação é monotônica/idempotente: chamadas repetidas preservam o primeiro instante de atendimento.
- Notas, múltiplas etapas, reabertura e CRM continuam não decididos até necessidade real.

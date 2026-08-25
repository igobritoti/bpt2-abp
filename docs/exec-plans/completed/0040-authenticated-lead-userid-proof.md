# Execution Plan 0040 — Authenticated Lead UserId proof

Status: **CONCLUÍDO**

## Objetivo

Provar em runtime real que um Buyer comum auto-cadastrado cria um Lead autenticado cujo `UserId` persistido corresponde à identidade corrente, sem alterar regra de produto.

Vertical proof:

`fresh DB → self-registration → Buyer token → Published Listing → Lead → persisted UserId`

## Contexto

Base remota de início: `350c2909b4db57864521c8b1ddac8dabcd6de63c`, após o merge do Plan 0039.

Evidência inicial:

- `LeadAppService` cria `Lead(..., _currentUser.Id, ...)`;
- o Public Buyer smoke provava Lead real anônimo com `userId == null`;
- o WhatsApp forwarding smoke provava Authorization apenas contra backend mockado com token sintético;
- não havia prova executada ligando self-registration real a `LeadDto.UserId` real.

## Implementação

- adicionado `scripts/authenticated-lead-http-smoke.sh`;
- o smoke cria Seller/Listing fixture com `admin`, publica a Listing, auto-cadastra um Buyer, obtém token real e cria Lead autenticado;
- a resposta é validada contra o id retornado pelo próprio self-registration;
- o smoke foi conectado ao Public Buyer HTTP Gate existente, incluindo syntax check e execução focal;
- nenhuma regra de `LeadAppService`, entidade, schema, migration ou frontend foi alterada.

## Fora de escopo preservado

- perfil/role Buyer;
- mudança de frontend WhatsApp;
- analytics/attribution adicional;
- migration/schema/infra;
- novo workflow.

## Critérios de aceite

1. [x] Buyer é criado por self-registration em banco fresco.
2. [x] Buyer obtém token real sem privilégio administrativo.
3. [x] Lead autenticado em Listing publicada retorna sucesso.
4. [x] `LeadDto.UserId` é não nulo e igual ao id do Buyer registrado.
5. [x] `listingId`, `channel`, `id` e `createdAtUtc` permanecem corretos.
6. [x] Lead anônimo e forwarding autenticado existentes continuam verdes no gate compartilhado.
7. [x] nenhuma regra de produto, schema ou infraestrutura é alterada.

## Evidência executada

Public Buyer HTTP Gate, em PostgreSQL fresco, passou com:

- `AUTHENTICATED_LEAD_SELF_REGISTRATION: PASS`
- `AUTHENTICATED_LEAD_TOKEN: PASS`
- `AUTHENTICATED_LEAD_USER_ID: PASS`
- `AUTHENTICATED LEAD HTTP: PASSED`
- `AUTHENTICATED_LEAD_FORWARDING: PASS`

Os smokes agregados de Public Buyer, Seller Hub, Vehicle Hub, SEO e Listing structured data também permaneceram verdes.

## Decision log

- **DECIDIDO por evidência:** existia gap de prova entre `_currentUser.Id` no backend e forwarding autenticado mockado no frontend.
- **DECIDIDO:** smoke dedicado no Public Buyer Gate evita inflar o smoke público principal.
- **DECIDIDO:** `admin` permanece apenas como Seller/Listing fixture.
- **NÃO PROMOVIDO:** role/perfil Buyer, analytics ou mudança de domínio.

## Progress log

- 2026-08-25: `main` remoto confirmado em `350c2909b4db57864521c8b1ddac8dabcd6de63c`.
- 2026-08-25: gap confirmado por leitura de `LeadAppService`, `public-buyer-http-smoke.sh` e `whatsapp-auth-forwarding-smoke.sh`.
- 2026-08-25: smoke dedicado e wiring no Public Buyer Gate adicionados.
- 2026-08-25: Harness passou no head funcional.
- 2026-08-25: Public Buyer HTTP Gate passou integralmente, incluindo authenticated Lead UserId e forwarding.

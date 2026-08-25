# Execution Plan 0040 — Authenticated Lead UserId proof

Status: **ATIVO**

## Objetivo

Provar em runtime real que um Buyer comum auto-cadastrado cria um Lead autenticado cujo `UserId` persistido corresponde à identidade corrente, sem alterar regra de produto.

Vertical proof:

`fresh DB → self-registration → Buyer token → Published Listing → Lead → persisted UserId`

## Contexto

Base remota verificada: `350c2909b4db57864521c8b1ddac8dabcd6de63c`, após o merge do Plan 0039.

Evidência atual:

- `LeadAppService` instancia `Lead(..., _currentUser.Id, ...)`, portanto suporta associação opcional de identidade;
- `scripts/public-buyer-http-smoke.sh` prova Lead real anônimo e exige `userId == null`;
- `scripts/whatsapp-auth-forwarding-smoke.sh` prova forwarding do header Authorization, mas usa `buyer-token-proof` contra backend mockado;
- não existe prova executada ligando self-registration real a um Lead persistido com `UserId` real.

## Escopo

- adicionar um smoke dedicado de authenticated Lead;
- reutilizar o Public Buyer HTTP Gate existente;
- criar Seller/Listing fixture com `admin`;
- criar Buyer por `POST /api/account/register`;
- obter token real do Buyer pelo cliente de teste existente;
- criar Lead autenticado em Listing publicada;
- verificar `listingId`, `channel`, `id`, `createdAtUtc` e `userId` igual ao id retornado pelo self-registration.

## Fora de escopo

- alterar `LeadAppService` ou entidade Lead;
- criar perfil/role Buyer;
- mudar frontend de WhatsApp;
- analytics/attribution adicional;
- migration/schema/infra;
- novo workflow.

## Critérios de aceite

1. [ ] Buyer é criado por self-registration em banco fresco.
2. [ ] Buyer obtém token real sem privilégio administrativo.
3. [ ] Lead autenticado em Listing publicada retorna sucesso.
4. [ ] `LeadDto.UserId` é não nulo e igual ao id do Buyer registrado.
5. [ ] `listingId`, `channel`, `id` e `createdAtUtc` permanecem corretos.
6. [ ] Lead anônimo e forwarding autenticado existentes continuam verdes no gate compartilhado.
7. [ ] nenhuma regra de produto, schema ou infraestrutura é alterada.

## Decision log

- **DECIDIDO por evidência:** há gap de prova entre suporte de `_currentUser.Id` no backend e forwarding autenticado mockado no frontend.
- **DECIDIDO:** usar smoke dedicado no Public Buyer Gate para evitar inflar o smoke público existente.
- **DECIDIDO:** manter `admin` apenas como Seller/Listing fixture.

## Progress log

- 2026-08-25: `main` remoto confirmado em `350c2909b4db57864521c8b1ddac8dabcd6de63c`.
- 2026-08-25: gap confirmado por leitura de `LeadAppService`, `public-buyer-http-smoke.sh` e `whatsapp-auth-forwarding-smoke.sh`.

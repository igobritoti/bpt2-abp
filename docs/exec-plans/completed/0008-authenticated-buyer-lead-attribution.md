# Execution Plan 0008 — Authenticated Buyer Lead Attribution

Status: **CONCLUÍDO**

## Objetivo

Fechar o menor gap após o Plan 0007 sem ampliar domínio:

`Buyer autenticado → WhatsApp CTA → Lead.UserId atribuível → abrir conversa`

## Evidência de partida

- `LeadAppService` já deriva `UserId` de `ICurrentUser` e contato anônimo continua permitido.
- `BomPraTi_BuyerWeb` já autentica Buyer no browser por Authorization Code + PKCE e mantém `access_token` no `UserManager` do cliente.
- O CTA do Plan 0007 chamava um route handler Next server-side sem propagar o bearer Buyer; assim, o backend recebia contato anônimo mesmo quando o browser já possuía identidade Buyer.

## Classificação final

- **PASSA / DECIDIDO:** contato anônimo permanece disponível.
- **PASSA / DECIDIDO:** sessão Buyer existente é reutilizada sem iniciar novo login.
- **PASSA / DECIDIDO:** Bearer é enviado apenas ao route handler same-origin e encaminhado somente ao Lead API.
- **PASSA / DECIDIDO:** URL WhatsApp continua derivado server-side do Listing público.
- **NÃO DECIDIDO:** perfil Buyer, CRM, scoring, deduplicação, atribuição de marketing e analytics agregados.

## Escopo entregue

- componente cliente mínimo para recuperar sessão Buyer já existente;
- progressive enhancement preservando formulário/303 anônimo;
- route handler com bearer opcional e forwarding ao Lead API;
- resposta JSON same-origin para o componente abrir o `wa.me` calculado no servidor;
- smoke focado de forwarding mais regressões Buyer/Public/Seller existentes.

## Fora de escopo

- login obrigatório no contato;
- novo endpoint backend;
- migration, role Buyer ou perfil Buyer;
- CRM/analytics/deduplicação/scoring;
- storage, fila ou background job.

## Critérios de aceite

1. [x] Buyer anônimo continua conseguindo contato WhatsApp.
2. [x] Sessão Buyer existente é usada sem novo login no código do CTA.
3. [x] Bearer não é enviado pelo browser a domínio externo; somente ao route handler same-origin, que o encaminha ao Lead API.
4. [x] Número WhatsApp continua calculado server-side a partir do Listing público.
5. [x] Build/typecheck e gates Buyer/Public permanecem verdes.
6. [x] Nenhuma migration ou mudança de domínio/backend foi adicionada.

## Evidência executada

Head funcional: `d684db735f448381c340356d090880988e561eb2`.

Nesse head passaram **9/9 workflows disparados pelo diff**:

- BPT2 Harness Gate;
- BPT2 Public Web Gate;
- BPT2 Public Buyer HTTP Gate;
- BPT2 Buyer Favorites HTTP Gate;
- BPT2 Public Discovery HTTP Gate;
- BPT2 Seller Auth HTTP Gate;
- BPT2 Seller Shell HTTP Gate;
- BPT2 Seller Draft Edit HTTP Gate;
- BPT2 Seller Photos Publish HTTP Gate.

O Public Buyer HTTP Gate manteve a prova real do Plan 0007 em PostgreSQL fresco, host ABP real e Next.js de produção:

- `PUBLIC_LEAD_ROUTE: PASS`
- `PUBLIC_LEAD_DRAFT_BLOCKED: PASS`
- `PUBLIC_WEB_DRAFT_PRIVATE: PASS`
- `PUBLIC_LEAD_PERSISTED: PASS`
- `PUBLIC_WEB_WHATSAPP_LEAD: PASS`
- `PUBLIC_LEAD_PAUSED_BLOCKED: PASS`
- `PUBLIC_LEAD_ARCHIVED_BLOCKED: PASS`
- `PUBLIC BUYER HTTP FLOW: PASSED`

No step adicional do mesmo workflow:

- `AUTHENTICATED_LEAD_FORWARDING: PASS`

Esse step usa um upstream controlado para observar que `Authorization: Bearer ...` recebido pelo route handler é encaminhado ao POST de Lead e que a resposta ao cliente contém apenas o URL WhatsApp canônico calculado server-side.

O Buyer Favorites HTTP Gate, separadamente no mesmo head, permaneceu verde e continua sendo a prova real de Authorization Code + PKCE/access token para `BomPraTi_BuyerWeb`.

**Limite epistemológico:** não foi executado um único teste end-to-end em que o token obtido pelo fluxo PKCE real fosse usado pelo CTA e chegasse ao Lead API real. Os três boundaries relevantes foram executados separadamente: Buyer OIDC real, Lead real/anônimo e forwarding autenticado controlado. Portanto B vale para cada comportamento observado; a composição entre eles é C.

## Progress log

- 2026-08-23: `main` refetchado após merge do PR #26 em `15149769b630e49d38b7769a6ee3f81c698a9945`.
- 2026-08-23: auditoria de `buyer-auth.ts`, CTA do detalhe e route handler confirmou que a sessão Buyer existente não era propagada ao Lead API.
- 2026-08-23: implementação inicial trocou o formulário por botão client-side; revisão estática detectou que isso quebraria a prova/fallback HTML do Plan 0007 antes de o CI chegar à asserção.
- 2026-08-23: correção mínima restaurou o `<form>` como progressive enhancement e interceptou apenas o submit com JavaScript; o head resultante passou todos os 9 workflows disparados.

## Decision log

- Reutilizar `getCurrentBuyerUser()` e o `access_token` já mantido pelo OIDC client; não introduzir cookie/session backend paralela.
- Não iniciar autenticação no CTA: Buyer anônimo continua permitido.
- Encaminhar Authorization apenas same-origin → Lead API; o token nunca compõe `wa.me` nem payload de contato.
- Preservar o `<form>`/303 do Plan 0007 para fallback sem JavaScript e regressão explícita do fluxo anônimo.
- Manter perfil Buyer, CRM, analytics agregados, deduplicação, scoring e atribuição de marketing fora do slice até necessidade comprovada.

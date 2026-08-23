# Execution Plan 0008 — Authenticated Buyer Lead Attribution

Status: **ATIVO**

## Objetivo

Fechar o menor gap após o Plan 0007 sem ampliar domínio:

`Buyer autenticado → WhatsApp CTA → Lead.UserId atribuído → abrir conversa`

## Evidência de partida

- `LeadAppService` já deriva `UserId` de `ICurrentUser` e contato anônimo continua permitido.
- `BomPraTi_BuyerWeb` já autentica Buyer no browser por Authorization Code + PKCE e mantém `access_token` no `UserManager` do cliente.
- O CTA do Plan 0007 chama um route handler Next server-side, mas o formulário HTML não envia o bearer Buyer; assim, o backend recebe contato anônimo mesmo quando o browser já possui identidade Buyer.

Classificação inicial:

- **PASSA:** backend já suporta atribuição opcional por identidade corrente.
- **NÃO PASSA:** CTA público atual não propaga a identidade Buyer existente.
- **DECIDIDO:** Buyer não será obrigado a autenticar para contatar Seller.
- **DECIDIDO:** quando existir `BomPraTi_BuyerWeb` válido, o bearer será encaminhado somente ao endpoint de Lead; o número WhatsApp continuará vindo do servidor.
- **NÃO DECIDIDO:** perfil Buyer, CRM, scoring, deduplicação e analytics agregados.

## Escopo

- componente cliente mínimo para o CTA recuperar sessão Buyer existente sem iniciar login;
- route handler aceita bearer opcional e o encaminha ao Lead API;
- resposta JSON same-origin para o componente abrir o `wa.me` calculado no servidor;
- preservar fallback anônimo/redirect do Plan 0007;
- gate focado de forwarding e regressões existentes.

## Fora de escopo

- login obrigatório no contato;
- novo endpoint backend;
- migration, role Buyer ou perfil Buyer;
- CRM/analytics/deduplicação/scoring;
- storage, fila ou background job.

## Critérios de aceite

1. [ ] Buyer anônimo continua conseguindo contato WhatsApp.
2. [ ] Sessão Buyer existente é usada sem novo login.
3. [ ] Bearer não é enviado pelo browser a domínio externo; só ao route handler same-origin, que o encaminha ao Lead API.
4. [ ] Número WhatsApp continua calculado server-side a partir do Listing público.
5. [ ] Build/typecheck e gates Buyer/Public permanecem verdes.
6. [ ] Nenhuma migration ou mudança de domínio/backend é adicionada.

## Progress log

- 2026-08-23: `main` refetchado após merge do PR #26 em `15149769b630e49d38b7769a6ee3f81c698a9945`.
- 2026-08-23: auditoria de `buyer-auth.ts`, CTA do detalhe e route handler confirmou que a sessão Buyer existente não era propagada ao Lead API.

## Decision log

- Reutilizar `getCurrentBuyerUser()` e o `access_token` já mantido pelo OIDC client; não introduzir cookie/session backend paralela.
- Encaminhar Authorization apenas same-origin → Lead API; o token nunca compõe `wa.me` nem payload de contato.
- Preservar contato anônimo e o redirect 303 existente para submissões sem JSON.

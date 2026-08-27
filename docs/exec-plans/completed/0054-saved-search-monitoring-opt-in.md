# Plan 0054 — Saved Search monitoring opt-in

Status: **CONCLUÍDO**

## Objetivo

Fechar o gap entre o opt-in de monitoramento já persistido no backend de Saved Search e a experiência pública: o Buyer deve conseguir habilitar/desabilitar explicitamente o monitoramento de novas ofertas para uma busca salva.

## Evidência de base

- `SavedSearch` já persiste `AlertEnabled` e `AlertEnabledAtUtc`.
- `SavedSearchAppService.SetAlertEnabledAsync` já expõe operação ownership-safe para alterar esse estado.
- `SavedSearchDto` já devolve o estado de alerta.
- antes deste slice, o public web não tipava `AlertEnabled`/`AlertEnabledAtUtc`, não chamava `SetAlertEnabledAsync` e não mostrava qualquer controle de monitoramento;
- a detecção de nova oferta já reutilizava a semântica pública e gerava ledger idempotente quando `AlertEnabled` estava ativo;
- `AlertEnabled` não possui semântica comprovada de canal e não foi reinterpretado como consentimento de e-mail;
- delivery externo, canal, destinatário verificado e retry permanecem boundary separado.

## Boundary entregue

1. `alertEnabled` e `alertEnabledAtUtc` refletidos no tipo `SavedSearch` do public web, incluindo nullability real de `DateTime?`;
2. client call reutiliza o endpoint convencional de `SetAlertEnabledAsync`;
3. `/buscas-salvas` expõe controle explícito para habilitar/desabilitar **monitoramento de novas ofertas** por busca;
4. copy fala somente de monitoramento de novas ofertas, sem prometer e-mail/notificação externa;
5. estado local é atualizado com a resposta persistida do backend;
6. o smoke HTTP existente foi conectado ao Public Buyer HTTP Gate, provando rota, enable/disable e ownership;
7. delivery externo, consentimento por canal, provider, destinatário e scheduler permanecem fora deste slice.

## Não objetivos

- enviar e-mail ou outra notificação externa;
- reinterpretar `AlertEnabled` como consentimento de e-mail;
- escolher SMTP/SendGrid/SES/Resend ou outro provider;
- resolver/verificar endereço de e-mail do Buyer;
- adicionar runner automático ou distributed lock;
- delivery de price-drop de Favorite;
- criar enum/taxonomia de canais sem segundo canal comprovado.

## Decision log

- `AlertEnabled` governa monitoramento/detecção e não possui semântica de canal comprovada; portanto não é rotulado como e-mail.
- Opt-in de monitoramento e consentimento de delivery externo são boundaries diferentes.
- A UI expõe somente a capacidade que já existe: monitorar novas ofertas para aquela busca.
- Price-drop permanece fora porque não possui preferência/opt-in equivalente comprovado.
- Nenhuma migration foi necessária porque o estado `AlertEnabled` já existia.
- O smoke completo de Saved Search já continha os asserts necessários e foi ligado ao Public Buyer HTTP Gate em vez de duplicar teste.

## Critérios de aceite

- [x] Saved Search client model expõe `alertEnabled` e `alertEnabledAtUtc`;
- [x] Buyer autenticado consegue habilitar monitoramento em busca própria;
- [x] Buyer consegue desabilitar novamente;
- [x] resposta atualiza estado da tela sem reload obrigatório;
- [x] UI não afirma delivery externo/e-mail;
- [x] ownership server-side permanece autoridade;
- [x] prova focada e Public Web Gate passam no head funcional `b30e846cd04907d929e36a3a38d7a71628609f9f`;
- [x] documentação final distingue `MONITORING_OPT_IN = JÁ EXISTE` de `EXTERNAL_DELIVERY = PARCIAL`.

## Progress log

- 2026-08-27 — Plan aberto sobre `main` `4cf104c47856771ff8ac4beec1ca6ead8841e01e` após auditoria comprovar backend pronto e ausência total de opt-in na UI.
- 2026-08-27 — Boundary corrigido antes de implementação: `AlertEnabled` não foi reinterpretado como consentimento de e-mail; o slice expõe somente monitoramento de novas ofertas.
- 2026-08-27 — Client e UI passaram a refletir/trocar o estado persistido; nullability de `AlertEnabledAtUtc` alinhada ao `DateTime?` do DTO.
- 2026-08-27 — Detectado que `buyer-saved-search-http-smoke.sh` estava órfão de CI; o smoke existente foi conectado ao Public Buyer HTTP Gate sem duplicar teste.
- 2026-08-27 — No head `b30e846cd04907d929e36a3a38d7a71628609f9f`, Harness e Public Web ficaram verdes e a etapa `Exercise Saved Search monitoring over HTTP` passou, cobrindo enable/disable/ownership.

# Plan 0054 — Saved Search monitoring opt-in

Status: **ATIVO**

## Objetivo

Fechar o gap entre o opt-in de monitoramento já persistido no backend de Saved Search e a experiência pública: o Buyer deve conseguir habilitar/desabilitar explicitamente o monitoramento de novas ofertas para uma busca salva.

## Evidência de base

- `SavedSearch` já persiste `AlertEnabled` e `AlertEnabledAtUtc`.
- `SavedSearchAppService.SetAlertEnabledAsync` já expõe operação ownership-safe para alterar esse estado.
- `SavedSearchDto` já devolve o estado de alerta.
- o public web não tipa `AlertEnabled`/`AlertEnabledAtUtc`, não chama `SetAlertEnabledAsync` e não mostra qualquer controle de monitoramento;
- a detecção de nova oferta já reutiliza a semântica pública e gera ledger idempotente quando `AlertEnabled` está ativo;
- `AlertEnabled` não possui semântica comprovada de canal e não deve ser reinterpretado como consentimento de e-mail;
- delivery externo, canal, destinatário verificado e retry permanecem boundary separado.

## Boundary

1. refletir `alertEnabled` e `alertEnabledAtUtc` no tipo `SavedSearch` do public web;
2. adicionar client call para o endpoint convencional de `SetAlertEnabledAsync`;
3. exibir, em `/buscas-salvas`, controle explícito para habilitar/desabilitar **monitoramento de novas ofertas** por busca;
4. explicar que o monitoramento registra novos matches na conta, sem prometer e-mail/notificação externa;
5. atualizar estado local com a resposta do backend;
6. adicionar prova focada de que a preferência é ownership-safe, persiste e pode ser revertida;
7. manter delivery externo, consentimento por canal, provider, destinatário e scheduler fora deste slice.

## Não objetivos

- enviar e-mail ou outra notificação externa;
- reinterpretar `AlertEnabled` como consentimento de e-mail;
- escolher SMTP/SendGrid/SES/Resend ou outro provider;
- resolver/verificar endereço de e-mail do Buyer;
- adicionar runner automático ou distributed lock;
- delivery de price-drop de Favorite;
- criar enum/taxonomia de canais sem segundo canal comprovado.

## Decision log

- `AlertEnabled` governa monitoramento/detecção e não possui semântica de canal comprovada; portanto não será rotulado como e-mail.
- Opt-in de monitoramento e consentimento de delivery externo são boundaries diferentes.
- A UI deve expor somente a capacidade que já existe: monitorar novas ofertas para aquela busca.
- Price-drop permanece fora porque não possui preferência/opt-in equivalente comprovado.
- Nenhuma migration é necessária porque o estado `AlertEnabled` já existe.

## Critérios de aceite

- [ ] Saved Search client model expõe `alertEnabled` e `alertEnabledAtUtc`;
- [ ] Buyer autenticado consegue habilitar monitoramento em busca própria;
- [ ] Buyer consegue desabilitar novamente;
- [ ] resposta atualiza estado da tela sem reload obrigatório;
- [ ] UI não afirma delivery externo/e-mail;
- [ ] ownership server-side permanece autoridade;
- [ ] prova focada e Public Web Gate passam no head exato;
- [ ] documentação final distingue `MONITORING_OPT_IN = JÁ EXISTE` de `EXTERNAL_DELIVERY = PARCIAL`.

## Progress log

- 2026-08-27 — Plan aberto sobre `main` `4cf104c47856771ff8ac4beec1ca6ead8841e01e` após auditoria comprovar backend pronto e ausência total de opt-in na UI.
- 2026-08-27 — Boundary corrigido antes de implementação: `AlertEnabled` não será reinterpretado como consentimento de e-mail; o slice expõe somente monitoramento de novas ofertas.

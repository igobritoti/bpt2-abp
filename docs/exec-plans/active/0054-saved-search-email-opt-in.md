# Plan 0054 — Saved Search email opt-in

Status: **ATIVO**

## Objetivo

Fechar o gap entre o opt-in de alerta já persistido no backend de Saved Search e a experiência pública: o Buyer deve conseguir habilitar/desabilitar explicitamente **alertas por e-mail** para uma busca salva, sem afirmar que o delivery externo já está implementado.

## Evidência de base

- `SavedSearch` já persiste `AlertEnabled` e `AlertEnabledAtUtc`.
- `SavedSearchAppService.SetAlertEnabledAsync` já expõe operação ownership-safe para alterar esse estado.
- `SavedSearchDto` já devolve o estado de alerta.
- o public web não tipa `AlertEnabled`/`AlertEnabledAtUtc`, não chama `SetAlertEnabledAsync` e não mostra qualquer controle de alerta;
- a UI atual promete apenas “Salvar busca”, portanto não existe consentimento de produto comprovado para e-mail;
- o host BPT2 já usa `Volo.Abp.Emailing`/`IEmailSender`, mas delivery externo, destinatário verificado e retry permanecem boundary separado.

## Boundary

1. refletir `alertEnabled` e `alertEnabledAtUtc` no tipo `SavedSearch` do public web;
2. adicionar client call para o endpoint convencional de `SetAlertEnabledAsync`;
3. exibir, em `/buscas-salvas`, controle explícito para habilitar/desabilitar alertas por e-mail por busca;
4. deixar claro na copy que esta ação registra a preferência, sem afirmar envio já operacional;
5. atualizar estado local com a resposta do backend;
6. adicionar prova focada no gate público de que a preferência é ownership-safe, persiste e pode ser revertida;
7. manter delivery externo, provider, verificação de destinatário e scheduler fora deste slice.

## Não objetivos

- enviar e-mail;
- escolher SMTP/SendGrid/SES/Resend ou outro provider;
- resolver/verificar endereço de e-mail do Buyer;
- adicionar runner automático ou distributed lock;
- delivery de price-drop de Favorite;
- criar enum/taxonomia de canais sem segundo canal comprovado.

## Decision log

- O texto `AlertEnabled` do backend, sem controle público, é capacidade técnica e não consentimento de produto para e-mail.
- O primeiro canal a ser explicitado será e-mail porque o host já possui o boundary provider-neutral `IEmailSender`; isso não escolhe provider externo.
- Opt-in e delivery são boundaries diferentes: este Plan entrega somente a preferência explícita e persistida.
- Price-drop permanece fora porque não possui preferência/opt-in equivalente comprovado.
- Nenhuma migration é necessária porque o estado `AlertEnabled` já existe.

## Critérios de aceite

- [ ] Saved Search client model expõe `alertEnabled` e `alertEnabledAtUtc`;
- [ ] Buyer autenticado consegue habilitar alerta por e-mail em busca própria;
- [ ] Buyer consegue desabilitar novamente;
- [ ] resposta atualiza estado da tela sem reload obrigatório;
- [ ] UI não afirma que e-mail já foi enviado/entregue;
- [ ] ownership server-side permanece autoridade;
- [ ] prova focada e Public Web Gate passam no head exato;
- [ ] documentação final distingue `EMAIL_OPT_IN = JÁ EXISTE` de `EMAIL_DELIVERY = PARCIAL`.

## Progress log

- 2026-08-27 — Plan aberto sobre `main` `4cf104c47856771ff8ac4beec1ca6ead8841e01e` após auditoria comprovar backend pronto e ausência total de opt-in na UI.

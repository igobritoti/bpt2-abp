# Buyer alert delivery readiness audit — 2026-08-28

## Pergunta

O BPT2 atual já possui contrato suficiente para entregar externamente alertas de Saved Search e price-drop de Favorites sem escolher canal, destinatário ou infraestrutura por preferência?

## Resultado

**NÃO PASSA — DELIVERY EXTERNO CONTINUA PARCIAL/BLOQUEADO POR CONTRATO.**

A detecção e a visualização in-app estão entregues. O boundary externo ainda não possui informação suficiente para uma implementação correta.

## Evidência atual

### Saved Search

`SavedSearch.AlertEnabled` e `AlertEnabledAtUtc` registram opt-in para a capacidade de alerta/detecção, mas o agregado não registra:

- canal escolhido;
- endereço/destinatário de delivery;
- confirmação/verificação desse destinatário;
- frequência/digest versus evento imediato;
- política de retry/deduplicação do envio externo.

O opt-in atual não deve ser reinterpretado como consentimento específico para e-mail, SMS, WhatsApp ou push.

### Favorites / price-drop

`Favorite` registra apenas `UserId`, `ListingId` e `CreatedAtUtc`. Não existe opt-in específico de delivery de price-drop, canal, destinatário ou preferência de frequência.

Favoritar um Listing autoriza o detector interno já entregue, mas não deve ser transformado implicitamente em consentimento para mensagem externa.

### Provider e infraestrutura

`main/BomPraTi/appsettings.json` não configura SMTP/e-mail provider nem outro canal de notificação externo.

ADR-0003 exige coordenação durável, idempotência e retry para side effects externos. ADR-0010 exige avaliação de soluções maduras antes de adicionar infraestrutura/provider novo.

O runner automático de Saved Search também permanece bloqueado separadamente pelo contrato de deployment/locking documentado em `2026-08-28-saved-search-runner-readiness.md`.

## Decisões

`SAVED_SEARCH_EXTERNAL_DELIVERY = PARCIAL / NÃO AUTORIZADO PARA IMPLEMENTAÇÃO`

`FAVORITE_PRICE_DROP_EXTERNAL_DELIVERY = PARCIAL / NÃO AUTORIZADO PARA IMPLEMENTAÇÃO`

Detecção, histórico in-app e delivery externo são boundaries independentes.

## Gate mínimo para desbloquear

Antes de abrir execution plan de delivery externo, definir com evidência:

1. canal suportado e por quê;
2. destinatário canônico e como sua verificabilidade é comprovada;
3. consentimento específico por capability/canal e mecanismo de opt-out;
4. frequência: evento imediato, digest ou outra política explícita;
5. chave de idempotência/deduplicação de delivery;
6. retry, falha permanente, observabilidade e retenção mínima;
7. provider/infra escolhido conforme ADR-0010;
8. para Saved Search, runner/claim/locking já desbloqueado ou um boundary alternativo explicitamente decidido.

## Não autorizado por este audit

- escolher e-mail, SMS, WhatsApp ou push por preferência;
- usar o e-mail da conta sem prova de verificabilidade/consentimento do canal;
- tratar Favorite como opt-in de mensagem externa;
- introduzir SMTP/provider, broker, Redis, Hangfire/Quartz ou worker;
- adicionar schema de notification/delivery antes de o contrato acima existir.

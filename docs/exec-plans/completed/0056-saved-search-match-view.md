# Plan 0056 — Saved Search match view

Status: **CONCLUÍDO**

## Objetivo

Fechar o gap entre o ledger de novas ofertas já detectado/persistido no backend e a experiência Buyer: permitir que o dono de uma Saved Search consulte, sob demanda, as ofertas detectadas para aquela busca.

## Evidência de base

- `ISavedSearchAppService.GetMatchesAsync(id)` já existia e exige autenticação;
- `SavedSearchAppService.GetMatchesAsync` valida ownership pelo próprio Saved Search antes de consultar matches;
- matches são ordenados por `DetectedAtUtc` desc + `Id`;
- `buyer-saved-search-http-smoke.sh` já provava a rota `/api/app/saved-search/{id}/matches`, match correto, buscas incompatíveis/opt-out sem match e isolamento de ownership;
- antes deste slice, o public web não tipava/chamava `GetMatchesAsync` e `/buscas-salvas` não mostrava o ledger ao Buyer;
- external delivery/provider/canal continua boundary separado.

## Boundary entregue

1. `SavedSearchAlertMatch` tipado no client Buyer;
2. client call adicionada para o endpoint existente de matches;
3. matches carregados somente quando o Buyer pede por uma busca específica, evitando fan-out N+1 no carregamento inicial;
4. cada match mostra link para o detalhe público e instante de detecção;
5. zero matches é mostrado explicitamente;
6. o match permanece histórico mesmo se o anúncio já não estiver público; a disponibilidade atual continua autoridade do detalhe público;
7. nenhuma copy promete e-mail, push ou outra notificação externa.

## Não objetivos

- provider/canal de entrega;
- e-mail/push/SMS/WhatsApp de alerta;
- mark-as-read/unread;
- badge global/contador agregado;
- nova tabela/schema;
- novo endpoint ou regra de matching;
- buscar cada Listing para materializar snapshot enriquecido do match;
- apagar match histórico quando Listing deixa de ser público.

## Critérios de aceite

- [x] public web possui tipo/client call para `GetMatchesAsync`;
- [x] Buyer consegue abrir matches de uma busca própria sob demanda;
- [x] zero matches é mostrado explicitamente;
- [x] match mostra instante e link para `/anuncios/{listingId}`;
- [x] carregamento inicial de Saved Searches não dispara chamada de matches por item;
- [x] copy não promete delivery externo;
- [x] backend/matching permanecem inalterados;
- [x] Public Web Gate e Harness passaram no head funcional `b78dbe76009381b129f1a4f8869975e39dd7326e`;
- [x] Public Buyer HTTP Gate no mesmo head executou com sucesso a etapa `Exercise Saved Search monitoring over HTTP`, reutilizando o contrato ownership-safe já existente.

## Decision log

- `MATCH_LEDGER_VISIBILITY = BUYER IN-APP, SOB DEMANDA`
- `MATCH_HISTORY = PRESERVADO MESMO SE LISTING DEIXAR DE SER PÚBLICO`
- `CURRENT_LISTING_VISIBILITY = AUTORIDADE DO DETALHE PÚBLICO`
- `EXTERNAL_DELIVERY = FORA DE ESCOPO`
- `MATCH_READ_STATE = NÃO INVENTAR`

## Progress log

- 2026-08-28 — `main` confirmado no merge commit `688157b93f046c3850ddd169449b9b1fa94b1848` do Plan 0055.
- 2026-08-28 — audit confirmou backend/HTTP já prontos e ausência da superfície de matches no public web.
- 2026-08-28 — client e `/buscas-salvas` passaram a expor o ledger lazy, com zero-state, link/timestamp e boundary histórico explícito.
- 2026-08-28 — no head funcional `b78dbe76009381b129f1a4f8869975e39dd7326e`, Harness e Public Web ficaram verdes; o Public Buyer passou a etapa de Saved Search e as regressões anteriores executadas até o closeout permaneceram verdes.

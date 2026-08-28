# Plan 0056 — Saved Search match view

Status: **ATIVO**

## Objetivo

Fechar o gap entre o ledger de novas ofertas já detectado/persistido no backend e a experiência Buyer: permitir que o dono de uma Saved Search consulte, sob demanda, as ofertas detectadas para aquela busca.

## Evidência de base

- `ISavedSearchAppService.GetMatchesAsync(id)` já existe e exige autenticação;
- `SavedSearchAppService.GetMatchesAsync` valida ownership pelo próprio Saved Search antes de consultar matches;
- matches são ordenados por `DetectedAtUtc` desc + `Id`;
- `buyer-saved-search-http-smoke.sh` já prova a rota `/api/app/saved-search/{id}/matches`, match correto, buscas incompatíveis/opt-out sem match e isolamento de ownership;
- o public web atual não tipa/chama `GetMatchesAsync` e `/buscas-salvas` não mostra o ledger ao Buyer;
- external delivery/provider/canal continua boundary separado.

## Boundary entregue

1. tipar `SavedSearchAlertMatch` no client Buyer;
2. adicionar client call para o endpoint existente de matches;
3. carregar matches somente quando o Buyer pedir por uma busca específica, evitando fan-out N+1 no carregamento inicial;
4. mostrar ListingId como link para o detalhe público e o instante de detecção;
5. preservar o match histórico mesmo se o anúncio já não estiver público; a disponibilidade atual continua autoridade do detalhe público;
6. não prometer e-mail, push ou notificação externa.

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

- [ ] public web possui tipo/client call para `GetMatchesAsync`;
- [ ] Buyer consegue abrir matches de uma busca própria sob demanda;
- [ ] zero matches é mostrado explicitamente;
- [ ] match mostra instante e link para `/anuncios/{listingId}`;
- [ ] carregamento inicial de Saved Searches não dispara chamada de matches por item;
- [ ] copy não promete delivery externo;
- [ ] backend/matching permanecem inalterados;
- [ ] Public Web Gate e Harness passam no head funcional/final aplicável.

## Decision log

- `MATCH_LEDGER_VISIBILITY = BUYER IN-APP, SOB DEMANDA`
- `MATCH_HISTORY = PRESERVADO MESMO SE LISTING DEIXAR DE SER PÚBLICO`
- `CURRENT_LISTING_VISIBILITY = AUTORIDADE DO DETALHE PÚBLICO`
- `EXTERNAL_DELIVERY = FORA DE ESCOPO`
- `MATCH_READ_STATE = NÃO INVENTAR`

## Progress log

- 2026-08-28 — `main` confirmado no merge commit `688157b93f046c3850ddd169449b9b1fa94b1848` do Plan 0055.
- 2026-08-28 — audit confirmou backend/HTTP já prontos e ausência da superfície de matches no public web.

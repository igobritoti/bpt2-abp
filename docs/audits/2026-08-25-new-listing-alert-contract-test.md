# Teste de contrato — alerta de nova oferta compatível

Data: 2026-08-25
Plano: 0049
Status: **PASSA — contrato de detecção comprovado; gatilho/delivery permanecem separados**

## Pergunta

Qual é o menor contrato seguro para detectar que uma nova oferta pública corresponde a uma busca salva, sem decidir prematuramente scheduler, provider ou canal de entrega?

## Evidência observada no BPT2

### A — Saved Search

`SavedSearch` persiste a intenção semântica do Buyer: VehicleId, SellerId, Brand, Model, City, StateCode, faixas de ano/preço/quilometragem e Query. Paginação e ordenação não fazem parte da identidade semântica.

O experimento adicionou `AlertEnabled`, explicitamente desligado por padrão, sem transformar buscas existentes em alertas implicitamente.

### A — elegibilidade pública

`ListingVisibility.IsPublic` e `ListingVisibility.PublicOnly` consideram pública somente uma Listing com `Status == Published`.

### A — transição de publicação

`ListingCommandService.PublishAsync` valida ownership e Vehicle canônico, executa `listing.Publish()` e persiste a Listing. O caminho permanece sem provider externo e sem varredura síncrona de todas as buscas salvas.

### A — semântica da busca pública

`PublicListingQuery` passou a expor `MatchesAsync(listingId, criteria)` reutilizando o mesmo pipeline de filtros da busca pública. A detecção não mantém uma segunda taxonomia de matching.

### A — ledger de detecção

`SavedSearchAlertMatch` persiste a identidade `(SavedSearchId, ListingId)` com unicidade no banco. Reprocessamento e `Pause → Publish` da mesma Listing não criam um segundo match.

### A — separação detector/delivery

`SavedSearchAlertDetectionService` é uma boundary explícita para avaliar uma Listing pública e materializar matches pendentes. Ele não envia e-mail, push, WhatsApp nem chama provider externo.

### B — teste HTTP reproduzido

O smoke autenticado provou mecanicamente:

1. busca com alerta desligado não gera match;
2. Listing Draft não gera match mesmo com alerta ligado;
3. Saved Search incompatível não gera match;
4. Listing compatível publicada gera exatamente um match;
5. reprocessamento gera zero novos matches;
6. `Pause → Publish` não duplica o ledger;
7. outro Buyer não lê matches nem altera opt-in da busca alheia;
8. o matcher usa os critérios públicos atuais, incluindo identidade/localidade/faixas;
9. nenhum delivery externo é necessário para materializar o match.

O mesmo head funcional passou Fresh Migration, Architecture, Host, Product API, Public Discovery, Buyer Favorites/Saved Search e os demais workflows correntes.

## Resultado das hipóteses

- **H1 PASSA.** Somente Listing publicamente elegível pode gerar match.
- **H2 PASSA.** Matching reutiliza o pipeline da busca pública.
- **H3 PASSA.** `(SavedSearchId, ListingId)` é suficiente para idempotência do baseline.
- **H4 PASSA.** Detecção e entrega podem permanecer separadas.
- **H5 REPROVADA na forma ingênua.** Varrer buscas salvas/delivery dentro de `PublishAsync` criaria latência proporcional ao número de intenções e acoplamento indevido. O publish não foi alterado para fazer essa varredura.
- **H6 PASSA.** Opt-in é explícito e default false.

## Decisão

**PASSA** o contrato mínimo de detecção de nova oferta compatível.

Decidido:

- fonte de elegibilidade = `ListingVisibility`;
- semântica de matching = mesma da busca pública;
- opt-in explícito no Saved Search;
- ledger único por `(SavedSearchId, ListingId)`;
- detecção separada de delivery;
- reprocessamento/republish não renotifica por padrão no baseline.

Não decidido:

- mecanismo confiável que chama o detector quando a Listing entra/reentra em estado público;
- evento local/distribuído, outbox ou job;
- provider/canal de entrega;
- frequência, batching/digest e retries externos;
- template/conteúdo da mensagem;
- price-drop.

## Próxima boundary

Provar o menor **gatilho confiável de detecção** para uma Listing que se torna pública, sem chamar provider no request e sem exigir scan global/scheduler por hipótese. O teste deve cobrir atomicidade, retry/idempotência e falha entre persistir a publicação e materializar os matches antes de escolher event bus/outbox/background job.
# Teste de contrato — alerta de nova oferta compatível

Data: 2026-08-25
Plano: 0049
Status: **EM TESTE**

## Pergunta

Qual é o menor contrato seguro para detectar que uma nova oferta pública corresponde a uma busca salva, sem decidir prematuramente scheduler, provider ou canal de entrega?

## Evidência observada no BPT2

### A — Saved Search

`SavedSearch` persiste a intenção semântica do Buyer: VehicleId, SellerId, Brand, Model, City, StateCode, faixas de ano/preço/quilometragem e Query. Paginação e ordenação não fazem parte da identidade semântica.

### A — elegibilidade pública

`ListingVisibility.IsPublic` e `ListingVisibility.PublicOnly` consideram pública somente uma Listing com `Status == Published`.

### A — transição de publicação

`ListingCommandService.PublishAsync` valida ownership e Vehicle canônico, executa `listing.Publish()` e persiste a Listing. O caminho atual não publica evento de domínio/integração nem agenda background job.

### A — semântica da busca pública

`PublicListingQuery.SearchPageAsync` aplica a autoridade atual de matching público: VehicleId, SellerId, filtros canônicos Brand/Model/ano via Catalog, City, StateCode, preço, quilometragem e Query textual/identidade canônica, sempre começando de `ListingVisibility.PublicOnly`.

### A — infraestrutura assíncrona

Busca no repositório atual não encontrou uso explícito de `ILocalEventBus`, `IDistributedEventBus`, `IBackgroundJobManager`, Hangfire, Quartz ou outbox para esse fluxo.

## Hipóteses falsificáveis

H1. Uma oferta só pode gerar match enquanto for publicamente elegível pela mesma regra de `ListingVisibility`.

H2. O matcher de alerta deve produzir o mesmo resultado semântico da busca pública para os critérios persistidos no Saved Search; duplicar uma segunda taxonomia de filtros é reprovado.

H3. `(SavedSearchId, ListingId)` é a menor identidade suficiente de detecção para impedir duplicação quando a mesma Listing é reprocessada, pausada e republicada ou restaurada, salvo requisito futuro explícito de renotificação.

H4. Detecção e entrega são responsabilidades separadas: o slice pode provar um match persistido/pendente sem escolher e-mail, push, WhatsApp ou outro provider.

H5. O caminho síncrono de Publish pode ser usado como ponto de teste/integração inicial sem introduzir scheduler. Isso será rejeitado se acoplar delivery ao request, quebrar atomicidade ou exigir latência proporcional ao número de buscas salvas.

H6. Opt-in deve ser explícito. Uma busca salva existente não deve começar a alertar automaticamente apenas porque a capability foi adicionada.

## Casos mínimos de teste

1. Saved Search desativada para alerta + Listing compatível publicada → nenhum match de alerta.
2. Saved Search ativada + Listing Draft compatível → nenhum match.
3. Saved Search ativada + Listing incompatível publicada → nenhum match.
4. Saved Search ativada + Listing compatível publicada → exatamente um match pendente.
5. Reprocessar a mesma Listing para a mesma Saved Search → continua exatamente um match.
6. Pause → Publish da mesma Listing → não duplica o match anterior.
7. Outro Buyer não lê/controla o estado de alerta da busca alheia.
8. Matching de filtros de identidade/localidade/faixas/query deve ser equivalente ao resultado da busca pública para a Listing candidata.
9. Delivery externo não é necessário para o teste de detecção.

## Critério de decisão

**PASSA** para implementação mínima se for possível provar os casos 1–9 com estado determinístico, ownership server-side e sem divergência da busca pública.

**NÃO PASSA** se o desenho exigir copiar a lógica de filtros, enviar provider externo no request de Publish, tratar Draft/private como candidato, ou permitir duplicatas por reprocessamento.

## Decisão ainda não tomada

Não estão decididos neste checkpoint:

- scheduler/polling vs evento/transação;
- provider/canal de entrega;
- frequência de envio;
- batching/digest;
- retries externos;
- template/conteúdo da mensagem;
- price-drop.

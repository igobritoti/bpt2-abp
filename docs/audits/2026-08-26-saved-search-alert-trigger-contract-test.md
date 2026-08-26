# Teste de contrato — gatilho confiável de detecção de alerta

Data: 2026-08-26
Plano: 0049
Status: **PASSA**

## Pergunta

Qual é o menor mecanismo que garante que a primeira publicação pública de uma Listing deixe uma intenção durável de detecção de Saved Search, sem varrer todas as buscas nem chamar delivery/provider dentro do request de publicação?

## Evidência observada

### A — Unit of Work ABP

A documentação oficial atual do ABP define métodos de application service como boundaries convencionais de Unit of Work. Requests HTTP não-GET usam transação por padrão quando o provider suporta transações; operações de repositório participam do UoW ambiente.

`IListingCommandService` herda `IApplicationService`, portanto `PublishAsync` é uma boundary convencional de UoW do ABP.

### B — lifecycle BPT2

`PublishAsync` altera a Listing para `Published`, persiste pelo repositório ABP e garante uma única `SavedSearchAlertDetectionRequest` por `ListingId`. O trigger não varre Saved Searches e não chama provider externo.

O experimento refutou usar um `MarketplaceDbContext` injetado diretamente como boundary do trigger: o probe de rollback não conseguiu provar atomicidade por esse caminho. O trigger foi então movido para `IRepository<SavedSearchAlertDetectionRequest, Guid>`, alinhado ao UoW ambiente.

### B — rollback transacional

O fixture abre UoW transacional explícito, grava `Published` e a request com `autoSave`, confirma a request staged pelo mesmo repositório/UoW e executa `RollbackAsync`. Uma execução seguinte, com contexto novo, observa `Draft` e zero requests.

Isso prova mecanicamente que Listing + intenção durável fazem rollback juntas no boundary testado.

### B — processamento tardio e elegibilidade temporal

O smoke HTTP prova que:

- Draft não cria match;
- publish normal deixa exatamente uma request pendente;
- Saved Search habilitada antes do enqueue pode casar;
- Saved Search habilitada somente depois da publicação não recebe alerta retroativo;
- opt-out antes do processamento suprime o match;
- processor conclui a request somente após avaliação pública;
- replay e pause → publish não duplicam request nem match.

`AlertEnabledAtUtc` permanece nulo quando não há opt-in datado. Estado legado `AlertEnabled=true` sem timestamp não recebe data inventada; um novo opt-in explícito estabelece a data.

## Resultado das hipóteses

- T1 — **PASSA**: primeira publicação deixa intenção O(1) por `ListingId`.
- T2 — **PASSA**: rollback explícito restaura Draft e remove a intenção staged.
- T3 — **PASSA**: retry/re-publish preserva uma única request.
- T4 — **PASSA**: trigger não avalia Saved Searches nem chama provider.
- T5 — **PASSA**: processor pode rodar depois e marca request processada.
- T6 — **PASSA**: opt-in posterior à publicação não é retroativo.
- T7 — **PASSA**: opt-out anterior ao processamento é respeitado.
- T8 — **PASSA para este boundary**: outbox/distributed event bus não é necessário para garantir a intenção local transacional já comprovada.

## Decisão

**PASSA** o desenho mínimo:

`PublishAsync → SavedSearchAlertDetectionRequest(ListingId, EnqueuedAtUtc) [mesmo UoW via repositório ABP]`

Depois, fora do request de publicação:

`DetectionRequest pendente → detector → SavedSearchAlertMatch → request.ProcessedAtUtc`

A request é o boundary durável de trabalho; `(SavedSearchId, ListingId)` continua sendo o ledger idempotente de match.

## O que foi rejeitado

- scan de Saved Searches dentro de `PublishAsync`;
- delivery/provider dentro da transação de publicação;
- trigger baseado em `MarketplaceDbContext` direto quando a participação no UoW não foi mecanicamente sustentada pelo probe;
- backfill inventado de `AlertEnabledAtUtc`;
- promover outbox distribuído apenas por preferência arquitetural.

## Próxima boundary

O gap restante não é mais atomicidade de publicação. É a execução automática do processor em produção.

O próximo slice deve provar o menor runner que drena requests pendentes com:

- claim/concurrency sem processamento duplo;
- retry após falha;
- recuperação de request pendente após restart;
- idempotência do ledger já existente;
- custo operacional explícito.

Só depois desse contrato escolher `BackgroundWorker`, job/scheduler ou mecanismo equivalente. Provider/canal/template de delivery continuam separados.

## Ainda não decidido

- mecanismo concreto que executa o processor em produção;
- frequência/polling se realmente necessários;
- política de retry/backoff;
- provider/canal/template/digest de delivery;
- price-drop.

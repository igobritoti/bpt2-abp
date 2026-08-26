# Teste de contrato — gatilho confiável de detecção de alerta

Data: 2026-08-26
Plano: 0049
Status: **EM TESTE**

## Pergunta

Qual é o menor mecanismo que garante que a primeira publicação pública de uma Listing deixe uma intenção durável de detecção de Saved Search, sem varrer todas as buscas nem chamar delivery/provider dentro do request de publicação?

## Evidência observada

### A — Unit of Work ABP

A documentação oficial atual do ABP define métodos de application service como boundaries convencionais de Unit of Work. Requests HTTP não-GET usam transação por padrão quando o provider suporta transações; operações de repositório participam do UoW ambiente.

`IListingCommandService` herda `IApplicationService`, portanto `PublishAsync` é uma boundary convencional de UoW do ABP.

### A/B — lifecycle BPT2

`ListingCommandService.PublishAsync` hoje valida ownership/Vehicle, muda a Listing para `Published` e persiste pelo repositório.

`ModerationListingCommandService.RestoreAsync` também retorna a Listing a `Published`, mas isso é restauração/reentrada de uma oferta já publicada, não necessariamente uma nova oferta.

### B — detector existente

`SavedSearchAlertDetectionAppService.EvaluateAsync` carrega todas as Saved Searches com alerta habilitado e avalia o candidato contra o matcher público compartilhado. Esse custo é proporcional ao número de intenções habilitadas, portanto o detector não deve ser chamado diretamente dentro de `PublishAsync`.

O ledger `(SavedSearchId, ListingId)` já torna a materialização final idempotente.

## Hipóteses falsificáveis

T1. A primeira chamada de `PublishAsync` deve persistir, no mesmo UoW, uma intenção durável O(1) identificada por `ListingId`.

T2. Se o UoW falhar depois de gravar a mudança da Listing e a intenção de detecção, ambos devem fazer rollback; não pode existir `Published` sem intenção durável por falha intermediária.

T3. Retry/re-publish da mesma Listing não cria segunda intenção de nova oferta.

T4. O trigger não avalia Saved Searches, não chama provider externo e não depende de scheduler/polling.

T5. O processor pode executar depois da transação de publicação e deve marcar a intenção como processada somente quando puder avaliar uma Listing pública.

T6. Uma Saved Search criada ou habilitada somente depois do instante da primeira publicação não deve receber retroativamente um alerta de “nova oferta” apenas porque o processor rodou tarde.

T7. Desativação antes do processamento deve continuar suprimindo o match/delivery, preservando opt-out.

T8. Se uma intenção durável na mesma transação + processor idempotente resolver os casos acima, outbox/distributed event bus/background job permanecem não promovidos. Eles só ganham necessidade quando houver requisito de transporte/worker/retry que o estado local não satisfaça.

## Modelo experimental mínimo

Candidato:

`PublishAsync → SavedSearchAlertDetectionRequest(ListingId, EnqueuedAtUtc) [mesmo UoW]`

Depois, fora do request de publicação:

`DetectionRequest pendente → detector → SavedSearchAlertMatch → request.ProcessedAtUtc`

Invariantes propostas:

- uma única request por `ListingId`;
- `EnqueuedAtUtc` representa a primeira publicação observada pelo trigger;
- re-publish/restore não cria uma nova “nova oferta”;
- Saved Search precisa estar habilitada antes/de no instante de enqueue para ser candidata;
- request só é concluída após avaliação pública bem-sucedida;
- provider/delivery não participa do processamento deste slice.

## Casos mínimos de teste

1. Draft sem publish → nenhuma request.
2. Experimento de UoW que publica + enfileira e falha antes de `Complete` → Listing continua Draft e request não existe.
3. Publish normal → Listing Published e exatamente uma request pendente.
4. Repetir trigger/re-publish → continua uma request.
5. Saved Search habilitada antes do publish + Listing compatível → processor gera um match e conclui request.
6. Saved Search habilitada somente após publish, antes do processor → não recebe match retroativo.
7. Saved Search habilitada antes do publish, mas desabilitada antes do processor → não recebe match.
8. Processor repetido depois de concluído → zero novos matches.
9. Nenhum provider externo é chamado; publish não faz scan de Saved Searches.

## Critério de decisão

**PASSA** se os casos 1–9 forem reproduzidos com uma intenção local durável na mesma transação, custo O(1) no publish e processor idempotente.

**NÃO PASSA** se houver gap de commit entre Listing e intenção, se a publicação precisar escanear Saved Searches, se houver alerta retroativo por atraso do processor ou se retries criarem duplicatas.

## Ainda não decidido

- quem executará o processor em produção;
- background worker/job concreto;
- local event bus vs chamada direta ao trigger O(1);
- distributed event bus/outbox;
- frequência/retry operacional;
- provider/canal/template/digest de delivery;
- price-drop.

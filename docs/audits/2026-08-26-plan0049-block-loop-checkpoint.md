# Plan 0049 — checkpoint de execução em loop

Data: 2026-08-26

Status: checkpoint operacional por evidência. Um blocker não impede a avaliação do bloco seguinte.

## Regra

- `ENTREGUE`: comportamento já comprovado e mergeado.
- `JÁ EXISTE`: capability já está no BPT2 atual; não abrir slice redundante.
- `EM TESTE`: slice implementado em PR próprio, aguardando gate final.
- `BLOQUEADO`: falta uma decisão/evidência material para implementação segura.
- `ADIADO`: não há evidência suficiente para promover implementação agora.

## Resultado por bloco

| Bloco | Estado | Evidência / decisão operacional |
|---|---|---|
| A — knowledge/enrichment publicado | BLOQUEADO | Boundary Podium→BPT2, Contract V2, projection/replay/redirect e cardinalidade 0/1/N já foram provados; falta enrichment técnico publicado suficiente com semântica/unidade/source para promover ficha comparável. Não duplicar aquisição/resolution do Podium. |
| B — Comparador 2–4 | BLOQUEADO | Cardinalidade/UX do comparador está decidida, mas o prerequisite test reprova implementação enquanto o catálogo publicado não contém um grupo mínimo de enrichment confiável. |
| C2 — runner de alertas | BLOQUEADO | Request durável já existe e sobrevive restart; falta provar claim/concurrency/retry sem reimplementar uma segunda fila. Worker vs ABP Background Jobs continua não decidido. |
| C3 — histórico para price-drop | EM TESTE | PR #73 persiste transições somente quando a Listing já está Published; Draft não entra no histórico de mercado; nenhum delivery é escolhido. |
| C4 — opt-in/dedup/unsubscribe | JÁ EXISTE | `CriteriaKey` deduplica Saved Searches equivalentes; `SetAlertEnabledAsync` implementa opt-in/opt-out com `AlertEnabledAtUtc`; `DeleteAsync` remove Saved Search e matches. |
| D — Promotions | ENTREGUE | PR #72 mergeado: janela temporal explícita, `IsSponsored`, label visual e prova de que promoção não altera ordem orgânica default/price-asc/price-desc. |
| E — confiança/moderação avançada | ADIADO | Baseline report + hide/restore já existe. Taxonomia, evidência/anexo, SLA, notificação e trust signals exigem problema observado ou provider/source/privacy/legal; nenhuma dessas precondições está comprovada. |
| F — discovery avançado | ADIADO | Geo/radius exige autoridade geográfica; relevance/ranking exige corpus+baseline+métrica; similar/upgrade dependem de enrichment; autocomplete/facets não têm problema/métrica priorizados que justifiquem mudar a busca atual. |
| G — inteligência de mercado | BLOQUEADO | Contexto/tendência de preço exige dataset/licença/metodologia reproduzível. Listing prices internos ainda não formam amostra suficiente para declarar valor de mercado. |
| H — complementares | ADIADO | Compra Assistida, financiamento, seguros e payments continuam atrás de core discovery/confiança/comparação e exigem tese comercial/provider/fluxo concreto. |

## Decisões adicionais

### C4 não gera novo slice

O baseline já cobre o mínimo que o plano pedia além da detecção: ownership Buyer, dedup semântico, habilitação/desabilitação explícita e exclusão. Criar outra camada de preferências sem canal/provider decidido adicionaria estado sem decisão de produto associada.

### E não será ampliado por benchmark isolado

`ListingReport` atual representa o fato mínimo de denúncia e a autoridade de moderação já consegue ocultar/restaurar Listing. Adicionar motivos, anexos ou SLA agora seria desenho sem evidência de operação real.

### F não promove ranking/relevance sem métrica

A busca pública atual possui filtros e ordenação determinística. Não há corpus rotulado nem métrica de relevância. Portanto mudar ranking por preferência seria epistemicamente mais fraco que manter o baseline explícito.

### G não infere valor de mercado de preços anunciados

Preço de Listing é preço pedido, não preço de transação nem avaliação de mercado. Até existir dataset/metodologia adequados, nenhuma faixa de mercado será apresentada como fato.

### H não cria integrações comerciais sem tese

Nenhum provider de financiamento/seguro/pagamento foi selecionado e não há contrato comercial ou problema medido que torne a integração necessária ao core atual.

## Próximas reaberturas objetivas

- A/B: primeiro snapshot de enrichment publicado com campos comparáveis, provenance e unidade definidos.
- C2: primitive pequena e testável para claim concorrente/retry, ou evidência de que ABP Background Jobs reduz complexidade total.
- C3: CI fresco do PR #73; depois disso price-drop pode ganhar contrato de detecção separado de delivery.
- E: volume/erro/SLA real de moderação ou provider confiável de trust signal.
- F: corpus/métrica de relevance, autoridade geo ou hipótese mensurável de facet/autocomplete.
- G: dataset licenciado/autoridade/metodologia.
- H: tese comercial/provider/fluxo e critérios de sucesso.

## Resultado do loop

Nenhum blocker foi promovido a implementação por opinião. O único novo slice de produto promovido nesta rodada foi C3, porque o código atual permite mudança de preço em Listing publicada e não preservava a transição necessária para qualquer price-drop confiável.

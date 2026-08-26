# Plan 0049 — conclusão progressiva das capabilities BPT2

Status: **ATIVO**

## Objetivo

Continuar o desenvolvimento do Bom Pra Ti após os Plans 0046–0048, fechando os gaps restantes por valor/dependência/evidência e sem permitir que a decisão secundária de monorepo/linguagem do Podium 7 bloqueie o produto.

Este plano usa três entradas:

1. estado realmente entregue no BPT2;
2. matriz BPT1 → BPT2 concluída no Plan 0046;
3. meta estratégica de cobertura funcional do Carros na Web (>=90% das capabilities elegíveis; ambição 100%).

## Princípios de implementação

1. **Capability antes de tecnologia.** Definir problema/contrato/teste antes de stack/infra.
2. **Um slice vertical por vez.** Branch → draft PR → gates estritamente necessários → review/base refresh → merge somente verde.
3. **Não duplicar Podium.** Acquisition/evidence/reconciliation automotiva pertencem ao bounded context Podium; BPT2 consome/projeta conhecimento publicado.
4. **BPT2 continua owner do catálogo publicado.** Listing referencia identidade BPT2; feeder externo não entra no request path público.
5. **BPT1 é donor, não chassis.** Reutilizar comportamento/contrato/teste somente quando provar valor.
6. **Benchmark não é requisito automático.** Carros na Web/Webmotors/OLX/iCarros orientam inventário; promoção exige fit, dados, custo e teste.
7. **Instrumentação acompanha hipótese.** Não construir analytics amplo sem pergunta/decisão concreta.
8. **Dados desconhecidos permanecem desconhecidos.** Nunca inferir ficha/equipamento/ausência quando a autoridade canônica não sustenta.
9. **Evitar irreversibilidade prematura.** Monorepo, migração Python→.NET, microservice, broker, engine externa e shared database ficam adiados até requisito medido.
10. **Custo recorrente conta.** Provider, moderação, dados, suporte, observabilidade e manutenção entram no custo da capability.

## Estado já fechado

- Seller/Listing lifecycle baseline;
- Favorites;
- Saved Search baseline para Buyer autenticado;
- contrato mínimo de detecção de nova oferta compatível — opt-in explícito, semântica pública compartilhada e ledger idempotente;
- gatilho transacional de detecção — request local durável única por Listing no UoW de publicação, rollback e replay comprovados;
- Buyer contact/WhatsApp → Lead;
- Lead mínimo `Novo/Atendido/Fechado` com outcome `Won/Lost`;
- moderação mínima humana;
- busca/filtros baseline;
- SEO/Vehicle Hub baseline;
- administração baseline;
- Catalog Structure baseline;
- Podium 7 reconhecido como knowledge producer/feed; boundary semântica decidida;
- topologia monorepo/linguagem explicitamente adiada e mensurável.

## Blocos restantes

A ordem abaixo é orientada por dependência. Dentro de cada bloco, implementar no máximo um slice por vez.

### Bloco A — contrato de knowledge/enrichment publicado

Problema: Comparator e várias capabilities futuras precisam de specs/consumo/equipamentos/safety confiáveis; o BPT2 atual possui principalmente identidade.

Objetivo mínimo:

- definir/persistir mapping explícito de Podium external identity → publicação BPT2;
- preservar contract/snapshot/revision/provenance suficiente;
- suportar zero/um/muitos `VehicleId`;
- consumir apenas campos de enrichment com semântica/unidade/source definidas;
- provar replay idempotente/redirects sem re-resolver labels.

Não escopo inicial: bulk de todo catálogo, HTTP síncrono, shared DB, fuzzy resolver BPT2.

### Bloco B — Comparador 2–4 veículos

Pré-condição: grupo mínimo de enrichment comparável aprovado.

Contrato já decidido:

- usuário escolhe 2, 3 ou 4 Vehicles;
- máximo inicial 4, não cardinalidade fixa;
- ordem escolhida preservada;
- `only differences` independente da quantidade;
- ausente = `não informado`, nunca valor inventado;
- estado/URL compartilhável;
- sem fallback para Listing.

Primeiro slice deve usar apenas atributos que tenham autoridade/provenance suficientes.

### Bloco C — retenção Buyer

Investigar/implementar por menor prova:

1. [x] Saved Search semantic criteria (sem persistir Skip/Take/Sort);
2. [~] alertas de nova oferta compatível — **detecção, opt-in, dedup e trigger transacional comprovados; runner automático e delivery pendentes**;
3. [ ] price-drop de Favorite/listing quando existir versionamento seguro de preço;
4. [ ] preferências/opt-in/dedup/unsubscribe além do estado mínimo já provado para alertas.

O Saved Search fechado persiste somente filtros semânticos já suportados pela busca pública, deriva ownership do Buyer autenticado, deduplica critérios equivalentes e reabre resultados pelos filtros públicos atuais. Paginação/ordenação não fazem parte da identidade salva.

O contrato de detecção fechado usa somente Listing pública, reutiliza a mesma semântica da busca pública, exige opt-in explícito e persiste um único `(SavedSearchId, ListingId)`. Varredura síncrona dentro de `PublishAsync` foi rejeitada.

O trigger fechado persiste uma única `SavedSearchAlertDetectionRequest` por Listing via repositório ABP no mesmo UoW da publicação. Rollback explícito desfaz Listing + request juntas. `AlertEnabledAtUtc` evita alerta retroativo e não recebe backfill inventado. Outbox distribuído não foi promovido porque a durabilidade local necessária foi comprovada.

### Bloco D — Promotions

- sponsored separado de ranking orgânico;
- não portar `HighlightScore` BPT1;
- identificar visualmente promoção;
- período/eligibility/priority explícitos;
- instrumentar impressão/click/Lead antes de ampliar planos comerciais.

### Bloco E — confiança/moderação avançada

Baseline de report + hide/restore já existe. Só ampliar mediante problema observado:

- taxonomia de motivos;
- evidência/anexo quando justificável;
- fila/estado/SLA;
- notificações;
- histórico/auditabilidade;
- Vehicle Trust Signals somente com provider/source/privacy/legal definidos.

### Bloco F — discovery avançado

Candidatos:

- geo/radius;
- autocomplete/facets;
- relevance/ranking;
- similar vehicles;
- upgrade suggestions.

Nenhum entra por benchmark isolado. Cada um requer corpus, baseline e métrica.

### Bloco G — inteligência de mercado

- contexto de preço;
- posição de mercado;
- histórico/tendência quando fonte sustentar;
- metodologia exibível e provenance.

Bloqueado até dataset/licença/metodologia suficientes.

### Bloco H — complementares

- Compra Assistida;
- financiamento;
- seguros;
- credits/payments quando modelo comercial exigir.

Continuam atrás do core discovery/confiança/comparação.

## Trilha paralela — Carros na Web

Meta congelada em `docs/strategy/2026-08-25-carros-na-web-functional-coverage-goal.md`.

A auditoria futura deve produzir:

- inventário funcional atual verificável;
- agrupamento Buyer/Seller/Catalog/Research/SEO/Tools/Editorial;
- estado BPT2 equivalente;
- dependências de Podium/dados/providers;
- custo de implementação e custo recorrente;
- risco legal/licença/privacy;
- decisão `JÁ EXISTE / ADICIONAR / EDITAR / SUBSTITUIR / ADIAR / EXCLUIR`;
- cobertura percentual elegível e total observada.

Essa trilha pode gerar novos itens para os blocos A–H, mas não interrompe um slice ativo sem blocker material.

## Critérios de priorização

Pontuar cada candidato qualitativamente por:

- impacto no core Buyer/Seller;
- dependência para outras capabilities;
- evidência de demanda/benchmark;
- disponibilidade/autoridade dos dados;
- complexidade técnica;
- custo operacional/fornecedor;
- risco legal/privacy/moderação;
- reversibilidade;
- observabilidade do resultado.

Preferir: alto valor + alta dependência desbloqueada + baixo/médio risco + teste claro.

## Próxima decisão operacional

Checkpoint do gatilho confiável concluído em `docs/audits/2026-08-26-saved-search-alert-trigger-contract-test.md`.

Resultado atualizado:

- iniciar Comparador permanece **REPROVADO** enquanto não houver enrichment técnico publicado suficiente do Podium;
- Saved Search permanece entregue como intenção Buyer persistida;
- detecção de nova oferta **PASSA** com matcher público compartilhado, somente Published e ledger `(SavedSearchId, ListingId)`;
- gatilho local transacional **PASSA**: `PublishAsync` persiste request única O(1) via repositório ABP no mesmo UoW, e rollback explícito prova ausência de gap entre Listing e request;
- Saved Search habilitada só depois da publicação não recebe alerta retroativo; opt-out antes do processamento é preservado;
- DbContext direto foi **REPROVADO como boundary do trigger** pelo probe; repositório ABP foi mecanicamente comprovado;
- outbox/distributed event bus permanece **NÃO PROMOVIDO**, pois o requisito de durabilidade local já está atendido sem transporte distribuído;
- próxima boundary do BPT2: **provar o runner mínimo que drena requests pendentes**, cobrindo claim/concurrency, retry e recuperação após restart antes de escolher background worker/job/polling;
- provider/canal de delivery, template, digest e price-drop permanecem não decididos.

## Critérios de aceite do Plan 0049

- [x] matriz restante atualizada removendo itens já concluídos;
- [x] próximo slice único selecionado por dependência/valor;
- [ ] cada slice concluído somente com CI fresco e documentação;
- [ ] inventário Carros na Web criado quando houver acesso verificável suficiente;
- [ ] cobertura Carros na Web calculada sem denominador artificial;
- [x] decisões monorepo/.NET não bloqueiam produto e só reabrem pelos triggers registrados;
- [ ] roadmap termina com todos os itens classificados como entregue, excluído justificadamente, adiado com blocker explícito ou promovido a plano próprio.

## Decision log

- 2026-08-25 — Podium 7 confirmado como alimentador/knowledge producer do catálogo; BPT2 permanece owner da publicação.
- 2026-08-25 — monorepo polyglot é viável, mas migração agora não desbloqueia Comparator/moderação/banco; decisão adiada.
- 2026-08-25 — intenção de produto registrada: >=90% das capabilities úteis/elegíveis do Carros na Web, ambição 100%.
- 2026-08-25 — cobertura do benchmark não autoriza cópia técnica/conteúdo nem implementação sem custo/valor/provenance.
- 2026-08-25 — identity contract Podium atual não é confundido com ficha técnica; Comparador continua atrás de enrichment publicado suficiente.
- 2026-08-25 — Saved Search definido como critérios semânticos da busca pública pertencentes ao Buyer; `Skip`/`Take`/página/`Sort` não compõem identidade.
- 2026-08-26 — alerta de nova oferta: detecção e delivery separados; opt-in explícito; matcher compartilha pipeline público; `(SavedSearchId, ListingId)` é o ledger idempotente.
- 2026-08-26 — varredura síncrona de todas as buscas dentro de `PublishAsync` não foi promovida.
- 2026-08-26 — trigger confiável decidido como request local durável única por Listing via repositório ABP no UoW de publicação; rollback/replay/temporal eligibility comprovados; outbox distribuído não promovido.

## Progress log

- 2026-08-25 — Plan 0046 concluiu inventário BPT1 → BPT2.
- 2026-08-25 — Plan 0047 entregou Lead closing mínimo.
- 2026-08-25 — Plan 0048 provou boundary Podium e fixture de projection/replay/redirect/cardinality.
- 2026-08-25 — Plan 0049 aberto para concluir o restante do roadmap por blocos funcionais.
- 2026-08-25 — blocker externo do enrichment acionou o fallback independente; Saved Search baseline implementado.
- 2026-08-26 — contrato de detecção de nova oferta implementado e comprovado por HTTP: Draft/private bloqueado, Published compatível gera ledger, replay/republish não duplicam e nenhum provider participa da detecção.
- 2026-08-26 — trigger transacional comprovado: request staged via repositório ABP, rollback explícito restaura Draft + zero requests, commit normal deixa uma pendência, opt-in tardio/opt-out são respeitados e republish não duplica request.

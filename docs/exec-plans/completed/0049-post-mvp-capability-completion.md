# Plan 0049 — conclusão progressiva das capabilities BPT2

Status: **CONCLUÍDO POR CLASSIFICAÇÃO**

## Objetivo

Executar os blocos restantes do roadmap BPT2 em ordem de dependência, promovendo somente slices com precondições e testes falsificáveis suficientes. Quando um bloco falha ou está bloqueado, registrar a evidência e seguir para o próximo independente, sem transformar hipótese em requisito.

## Decision log

- Bloco A — **BLOQUEADO**: o contrato semântico Podium→BPT2 está definido, mas ainda não há enrichment técnico publicado suficiente para promover persistência/consumo de specs de Comparador sem inventar autoridade de dados.
- Bloco B — **BLOQUEADO POR A**: Comparador 2–4 mantém contrato de cardinalidade/ordem/only-differences, porém não entra sem atributos técnicos publicados com provenance suficiente.
- Bloco C1 — **ENTREGUE**: Saved Search persiste critérios semânticos da busca pública para Buyer autenticado.
- Bloco C2 — **PARCIAL / BLOQUEADO**: detecção, opt-in, dedup e trigger transacional de nova oferta foram provados; o runner automático não foi promovido porque claim/concurrency, retry e recuperação após restart ainda não possuem decisão segura.
- Bloco C3 — **PARCIAL**: histórico de preço de Listing publicada foi entregue no PR #73. A continuação para detector de price-drop foi testada no PR #75 e **NÃO PASSOU** no gate de Buyer Favorites; o primeiro erro foi do smoke (`username: unbound variable`), portanto o slice foi fechado sem merge conforme a regra de loop.
- Bloco C4 — **JÁ EXISTE NO BASELINE** para o estado mínimo atual: dedup de Saved Search, opt-in/opt-out e remoção da busca/matches já estão cobertos. Extensões de preferências ficam condicionadas a delivery real.
- Bloco D — **ENTREGUE**: sponsored separado do ranking orgânico, identificação visual e janela temporal mínima de Promotion entregues no PR #72. Instrumentação comercial adicional depende de hipótese de monetização real.
- Bloco E — **ADIADO**: moderação mínima já existe; taxonomia, SLA, anexos, notificações e Vehicle Trust Signals exigem problema/provider/privacy/legal observados.
- Bloco F — **ADIADO**: geo/radius, autocomplete/facets, ranking, similar e upgrade exigem corpus, baseline e métrica antes de implementação.
- Bloco G — **BLOQUEADO POR DADOS**: contexto/preço de mercado e tendências exigem dataset/licença/metodologia/provenance suficientes.
- Bloco H — **ADIADO**: Compra Assistida, financiamento, seguros, credits/payments permanecem atrás do core e dependem de tese comercial/parceria.
- Trilha Carros na Web — **BLOQUEADA EXTERNAMENTE**: nova tentativa de acesso não forneceu inventário atual reproduzível suficiente; não foi criado denominador artificial de cobertura.
- Topologia Podium/BPT2 — **ADIADA**: monorepo/linguagem não bloqueiam os blocos acima e só reabrem pelos triggers já documentados.

Classificação epistemológica:

- fatos de código, PRs, gates e contratos executados = A/B;
- bloqueios e dependências derivados desses fatos = C;
- nenhuma preferência de provider, runner, dataset ou monetização foi promovida como requisito.

## Critérios de aceite

- [x] cada bloco A–H foi executado, testado quando havia hipótese falsificável ou classificado por blocker explícito;
- [x] nenhum PR vermelho foi mergeado;
- [x] falha do detector de price-drop foi registrada e o slice foi encerrado sem correção em loop;
- [x] Promotions foi concluído com CI verde;
- [x] histórico seguro de preço publicado foi concluído com CI verde;
- [x] itens já existentes não foram reimplementados;
- [x] blockers de enrichment, runner, dados de mercado e Carros na Web ficaram explícitos;
- [x] roadmap terminou com todos os blocos em estado `ENTREGUE / JÁ EXISTE / PARCIAL / BLOQUEADO / ADIADO`.

## Progress log

- 2026-08-25 — Plan 0049 aberto após os Plans 0046–0048.
- 2026-08-25/26 — Saved Search, detecção de nova oferta e trigger transacional foram comprovados em slices anteriores.
- 2026-08-26 — Promotions concluído e mergeado no PR #72.
- 2026-08-26 — sweep A–H registrado no PR #74.
- 2026-08-26 — histórico de preço de Listing publicada concluído e mergeado no PR #73.
- 2026-08-26 — continuação do price-drop testada no PR #75; 14 workflows passaram e Buyer Favorites falhou no smoke por variável shell não inicializada. Slice fechado sem merge conforme regra operacional.
- 2026-08-26 — nova varredura confirmou ausência de outro slice independente com precondições suficientes; plano encerrado por classificação, não por implementação forçada.

## Resultado final

O Plan 0049 não deixa um backlog implícito. Os próximos trabalhos só devem nascer quando algum blocker registrado mudar ou quando nova evidência promova uma capability adiada a um plano próprio. Até lá, não há execution plan funcional ativo que possa ser executado sem escolher comportamento, provider, dataset ou requisito por opinião.

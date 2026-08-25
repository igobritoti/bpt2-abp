# Plan 0046 — BPT1 capability roadmap audit

Status: **ATIVO**

## Objetivo / outcome

Construir um roadmap pós-MVP de capacidades do BPT2 baseado em evidência, usando `igobritoti/bomprati` como donor de produto e comportamento — nunca como chassis técnico — e confrontando cada candidato com o BPT2 atual, documentação externa confiável, comportamento observável de portais automotivos e testes reproduzíveis.

O resultado deste plano não é implementar automaticamente funcionalidades. É produzir uma matriz de decisão suficientemente forte para que cada futuro slice possa ser aberto com hipótese, risco, evidência e acceptance criterion explícitos.

## Contexto congelado

- BPT2 MVP funcional fechado; nenhum blocker funcional ativo.
- Nenhum execution plan funcional estava ativo antes deste plano.
- BPT1 (`igobritoti/bomprati`) é donor de capacidades e evidência histórica, não baseline técnico.
- O BPT1 foi abandonado como chassis; existência de código legado não prova adequação arquitetural nem valor atual.
- `docs/ENGINEERING.md` define classes A/B/C/D e o protocolo de avaliação de donor capabilities.
- `docs/QUALITY.md` define validação proporcional ao risco, incluindo characterization/contract tests, benchmarks e regras de migração.
- Portais externos são evidência de mercado/comportamento, não autoridade automática de requisito.

## Escopo

1. Inventariar capacidades efetivamente implementadas/testadas no BPT1.
2. Separar implementação real de documentação/intenção não comprovada.
3. Mapear equivalente no BPT2: completo, parcial, ausente ou substituído por abordagem melhor.
4. Pesquisar documentação oficial, standards e literatura aplicável quando houver decisão técnica ou metodológica relevante.
5. Observar superfícies atuais de portais automotivos relevantes, inicialmente Webmotors, OLX e Carros na Web quando verificável.
6. Projetar testes/experimentos antes de promover capacidades.
7. Permitir descoberta de novas candidatas durante a auditoria, desde que passem pelo mesmo protocolo.
8. Produzir classificação final: `TRAZER`, `VALIDAR ANTES`, `JÁ EXISTE`, `ADIAR`, `DESCARTAR`.

## Não escopo

- copiar stack, ORM, auth, infraestrutura, estrutura de pastas ou arquitetura do BPT1;
- implementar capacidade só porque concorrente a possui;
- migrar schema/dados sem contrato e reconciliação explícitos;
- afirmar superioridade de ranking/recomendação/UX sem métrica observável;
- abrir vários slices funcionais antes da conclusão da auditoria comparativa.

## Hipóteses iniciais a auditar

| Capability | Evidência inicial BPT1 | Estado BPT2 conhecido | Benchmark externo inicial | Estado inicial |
|---|---|---|---|---|
| Comparador técnico 2x/3x | implementado, fechado e testado | ausente | Webmotors mantém comparador técnico amplo | AUDITAR PRIMEIRO |
| CRM/pipeline de Leads | status, origem/campanha e métricas | Lead + `ContactedAtUtc` mínimo | marketplaces tratam acompanhamento do vendedor como fluxo central | AUDITAR |
| Analytics/atribuição | funil, acquisition, CTR, lead rate | ausente como capability consolidada | métricas necessárias para validar discovery/monetização | AUDITAR |
| Promotions/boost | orgânico/destaque/patrocinado/diamante + eventos | capacidade aberta, não implementada | OLX e Webmotors usam destaque/turbinar | AUDITAR |
| Alertas/buscas salvas | retenção e price-drop no BPT1 | ausente | OLX oferece favoritos, buscas salvas e alertas | AUDITAR |
| Vehicle Knowledge/enrichment | conhecimento, segurança, equipamentos, market position | enrichment deliberadamente aberto | comparadores/filtros técnicos usam dados ricos | AUDITAR |
| Similar vehicles | implementação específica | ausente | recomendação é comum, mas qualidade precisa ser medida | VALIDAR ANTES |
| Upgrade suggestions | implementação específica | ausente | hipótese de discovery/monetização | VALIDAR ANTES |
| Busca avançada/IA | não tratar legado como requisito | busca textual/filtros já entregues | Webmotors possui busca generativa; OLX usa relevância/filtros/localização | VALIDAR ANTES |
| Localização/geocoding/radius | não promovido | filtros City/StateCode atuais | OLX e Webmotors têm forte busca por localização | VALIDAR ANTES |
| Financiamento | camada complementar | fora do núcleo atual | OLX/Webmotors oferecem simulação/financiamento | ADIAR ATÉ TESE COMERCIAL |
| Pagamentos | módulo legado real | fora do baseline | não é requisito do marketplace básico | ADIAR |
| Seguros | intenção complementar | ausente | requer tese comercial/parceria | ADIAR |

A tabela é uma fila de investigação, não uma ordem de implementação.

## Plano de testes por capability

Cada candidato deve passar, quando aplicável, pelos gates abaixo antes de receber `TRAZER`:

### Gate 1 — realidade no donor

- localizar código, contrato, schema e UI correspondentes;
- localizar testes, smoke, task/PR de fechamento ou evidência runtime;
- distinguir `implementado/testado`, `implementado sem prova`, `documentado apenas`;
- registrar falhas ou limitações conhecidas do BPT1.

### Gate 2 — delta real no BPT2

- verificar se o BPT2 já resolve o mesmo problema por outro caminho;
- identificar somente o comportamento ausente;
- preservar invariantes congelados de auth, ownership, catálogo, visibilidade e boundaries;
- não promover detalhe técnico do BPT1 como requisito.

### Gate 3 — evidência externa

Usar, conforme o caso:

- documentação oficial atual de frameworks/standards;
- pesquisa/benchmark técnico reproduzível;
- documentação e comportamento atual de portais de mercado;
- fontes secundárias apenas como apoio e com classe de confiança explícita.

`Concorrente possui X` prova apenas existência/uso de X, não prova que BPT precisa de X.

### Gate 4 — teste de valor/qualidade

Definir antes da implementação o que falsificaria a hipótese.

Exemplos:

- comparador: cobertura canônica, completude dos campos, ambiguidade de versão, consistência 2x/3x e capacidade de compartilhar estado;
- ranking/recomendação: dataset fixo, métrica offline definida, baseline simples e casos adversariais;
- CRM: estados necessários derivados do fluxo real, ownership, monotonicidade, idempotência e utilidade operacional;
- promotions: separação orgânico/pago, transparência, expiração, elegibilidade, medição de impressão/click/lead e ausência de vazamento de anúncio não público;
- alertas: deduplicação, opt-in, matching determinístico, price-change correto e idempotência de entrega;
- geo: precisão da autoridade geográfica, fallback, distância e comportamento sem coordenada;
- enrichment: provenance, confidence, versionamento e comportamento diante de conflito entre fontes.

### Gate 5 — menor slice BPT2

Somente após os gates anteriores:

- definir menor vertical slice que testa a hipótese;
- escrever acceptance criterion executável;
- selecionar checks estritamente necessários em `QUALITY.md`;
- abrir plano funcional separado.

## Benchmark externo inicial — observações de 2026-08-25

### Webmotors

- comparador público permite múltiplos veículos e fichas técnicas lado a lado;
- documentação de ajuda informa mais de 80 itens comparáveis;
- busca pública possui filtros automotivos profundos, localização, anunciante, quilometragem e outros atributos;
- há busca generativa em linguagem natural;
- vendedor possui mecanismos de destaque/turbinar.

### OLX

- favoritos são combinados com buscas salvas e alertas;
- busca usa relevância e filtros de localização, inclusive CEP/estado/cidade/bairro;
- destaque pago promove anúncios para posições superiores e mede benefícios de visibilidade;
- possui financiamento/simulação como camada complementar.

### Carros na Web

A superfície deverá ser auditada diretamente quando houver fonte atual verificável suficiente. Conhecimento histórico ou benchmark antigo do BPT1 não será elevado a evidência atual sem revalidação.

## Candidatas que podem surgir durante a auditoria

Novas capacidades podem entrar no roadmap se forem observadas no BPT1, em benchmarks externos ou como lacuna necessária para testar outra capacidade. Exemplos plausíveis, ainda não decididos:

- busca salva / alertas de estoque;
- alerta de queda de preço;
- comparação de ofertas do mesmo Vehicle;
- qualidade/completude do anúncio como sinal de ranking;
- preço relativo ao mercado;
- histórico de preço do anúncio;
- seller reputation / sinais de confiança;
- filtros por características técnicas;
- landing pages por categoria/uso;
- notificações de lead estagnado;
- relatórios operacionais do Seller;
- experimentação/A-B testing e feature flags;
- observabilidade de funil por capability.

Entrada nessa lista não significa promoção.

## Critérios de aceite do Plan 0046

O plano pode ser concluído quando:

1. o inventário relevante do BPT1 estiver classificado por força da evidência;
2. cada candidato material tiver delta BPT2 explícito;
3. benchmark externo atual tiver sido registrado para as superfícies relevantes;
4. existir protocolo de teste específico para cada candidato promovível;
5. a matriz final tiver classificação e justificativa baseada em A/B/C/D;
6. candidatos sem evidência suficiente estiverem explicitamente em `VALIDAR ANTES`, `ADIAR` ou `DESCARTAR`;
7. houver no máximo uma próxima capability promovida como primeiro slice funcional, ou nenhuma se a evidência não justificar;
8. documentação canônica e harness estiverem consistentes.

## Checkpoints

- [ ] CP1 — inventário funcional BPT1 completo o suficiente para evitar cherry-picking.
- [ ] CP2 — matriz BPT1 ↔ BPT2 consolidada.
- [ ] CP3 — benchmark atual Webmotors / OLX / Carros na Web e outras fontes justificadas.
- [ ] CP4 — testes/experimentos definidos para candidatos fortes.
- [ ] CP5 — matriz final de decisão.
- [ ] CP6 — próximo slice, se houver, escolhido por evidência.

## Decisões abertas necessárias

- qual capability, se alguma, deve ser a primeira promovida;
- quais métricas de produto existem/precisam ser instrumentadas antes de validar valor;
- até onde comparar experiência de mercado sem copiar modelo comercial alheio;
- quando enriquecimento de catálogo passa de suporte ao marketplace para produto próprio.

## Progress log

- 2026-08-25 — BPT1 confirmado como `igobritoti/bomprati` e BPT2 como `igobritoti/bpt2-abp`.
- 2026-08-25 — encontrados no BPT1: comparador 2x/3x, CRM/pipeline, analytics/atribuição, promotions, retenção por email, Vehicle Knowledge, similares e upgrade suggestions.
- 2026-08-25 — benchmark externo inicial confirmou comparador/filtros/busca generativa/destaques na Webmotors e favoritos/buscas salvas/alertas/localização/destaques na OLX.
- 2026-08-25 — protocolo de donor migration e validação baseado em evidência preparado no PR #66.

## Decision log

- 2026-08-25 — BPT1 é donor; chassis técnico legado não será transplantado por default.
- 2026-08-25 — roadmap é de investigação e promoção por evidência, não backlog contratual de features.
- 2026-08-25 — benchmark de concorrente é evidência de possibilidade/uso de mercado, nunca requisito por si só.
- 2026-08-25 — cada capacidade funcional promovida após este plano deverá receber execution plan separado.

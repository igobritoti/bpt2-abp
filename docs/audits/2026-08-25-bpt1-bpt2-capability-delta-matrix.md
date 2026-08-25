# BPT1 ↔ BPT2 — capability delta matrix

Data: 2026-08-25

Status: auditoria ativa do Plan 0046. Este documento registra evidência e hipóteses; não autoriza implementação por si só.

## Regra de leitura

- **A** = documentação oficial atual, contrato/código versionado, standard aplicável.
- **B** = comportamento empiricamente executado/reproduzido, incluindo CI/teste do donor quando o teste cobre o comportamento em questão.
- **C** = inferência arquitetural derivada de A/B.
- **D** = preferência/opinião.

BPT1 é donor de capacidades e comportamento. BPT2 é a autoridade do produto atual e de sua arquitetura.

## Baseline de evidência do donor

O `main` atual de `igobritoti/bomprati`, head `04a9c264a841e67b28daa28f1564109a3178de79`, teve o workflow `quality-gates` concluído com sucesso. O pipeline executa automaticamente os testes determinísticos encontrados em `src/` e `scripts/`, além de lint, Prisma validate/generate, build, typecheck, migration deploy e runtime smoke.

Isso aumenta a confiança em módulos com testes presentes no head, mas não prova que toda feature esteja coberta end-to-end.

## Matriz de delta

| Capability | Evidência BPT1 | Estado BPT2 | Delta objetivo | Estado de auditoria |
|---|---|---|---|---|
| Seller / Listing lifecycle | fluxo central, rotas e módulos reais; CI verde | self-registration/login → My Listings → Draft/Edit → Photos → Publish/Pause/Archive comprovado por HTTP | nenhum gap material encontrado | JÁ EXISTE |
| Favorites | feature real | comprovado por HTTP com ownership server-side | nenhum gap do baseline | JÁ EXISTE |
| Listing reports + moderação mínima | módulo/auditorias no donor | report idempotente + fila admin + retirar/restaurar visibilidade comprovados | apenas extensões sofisticadas permanecem abertas | JÁ EXISTE / REVISAR EXTENSÕES |
| WhatsApp → Lead | fluxo real | Lead persistido antes do redirect; UserId autenticado preservado quando houver sessão | baseline já coberto | JÁ EXISTE |
| SEO público / Vehicle Hub baseline | `seo/public-discovery.test.ts`, `vehicle-hub-structured-data.test.ts` e superfícies próprias | canonical, robots, sitemaps, social metadata e structured data entregues | revisar apenas gaps novos | JÁ EXISTE |
| Busca textual/filtros | discovery real | título + Brand/Model/Generation/Version, filtros, paginação, query string, preço | fuzzy/autocomplete/facets/ranking ainda sem evidência | JÁ EXISTE / VALIDAR EXTENSÕES |
| Comparador técnico 2x/3x | rotas `/comparar`, matriz técnica, buckets canonical/lookup/legacy, `diff=1`, preço/mercado/equipamentos; auditoria específica | ausente | capacidade de apoio à decisão inexistente | GAP REAL — CANDIDATO FORTE |
| CRM / Lead pipeline | `NOVO → CONTATADO → NEGOCIACAO → VENDIDO/PERDIDO`, timestamps de estágio e eventos | `CreatedAtUtc` + `ContactedAtUtc` monotônico/idempotente | negociação, ganho/perda, fechamento e estados operacionais ausentes | GAP REAL — CANDIDATO FORTE |
| Lead attribution | source/medium/campaign/content/term/referrer/session + funcionalidade associada | Lead preserva UserId/Channel, mas não há attribution consolidada | attribution e origem de aquisição ausentes | GAP REAL — VALIDAR DESENHO |
| Analytics / funil | visitors, views, clicks, leads, CTR, leadRate, comparisons, promoted/similar/upgrade metrics | não há capability analítica consolidada; produto mantém analytics aberto | falta instrumentação agregada para medir várias hipóteses pós-MVP | GAP REAL — CANDIDATO INSTRUMENTAL |
| Promotions / boost | promoção real + eventos de view/click | produto prevê promotions, não implementado | monetização por destaque ausente | GAP REAL — CANDIDATO COMERCIAL |
| Vehicle Knowledge / safety / equipment / market position | scripts de audit/backfill/enrichment, UI e métricas | Structure canônica entregue; Enrichment explicitamente aberto | specs/equipamentos/segurança/consumo/preço-mercado/editorial ausentes | GAP REAL — CANDIDATO DE ENRICHMENT |
| Alertas / retenção | price-drop, weekly seller report, lead stagnation | ausente | retenção e reengajamento ausentes | VALIDAR ANTES |
| Compra Assistida | rota e módulo dedicado com actions/schema/services/testes | ausente | fluxo assistido completo ausente | VALIDAR ANTES |
| Similar vehicles | implementação própria + analytics | ausente | recomendação de alternativas ausente | VALIDAR POR MÉTRICA |
| Upgrade suggestions | implementação própria + analytics | ausente | recomendação aspiracional/upsell ausente | VALIDAR POR MÉTRICA |
| Credits | ledger, grant/consume, testes | ausente | mecanismo comercial interno ausente | ADIAR; subordinado a tese comercial |
| Payments | módulo, services, webhook, validação real | fora do baseline e explicitamente não objetivo central | capacidade comercial fora do núcleo | ADIAR |
| Planner | contratos de work-unit + testes | não aplicável | tooling, não produto | DESCARTAR COMO FEATURE |
| Argus Core | runner/locks/reports/execution + testes | não aplicável | tooling/infra, não produto | DESCARTAR COMO FEATURE |

## 1. Comparador — contrato e hipótese

### Comportamento comprovado no donor

O donor possui:

- seleção por `vehicles[]`, com fallback `a`/`b`;
- dois veículos em rota canônica de par e três veículos na experiência de seleção;
- matriz com N colunas;
- `onlyDifferences` via `diff=1`;
- resolução por bucket `canonical`, `lookup` ou `legacy`;
- ficha mecânica, consumo, preço de referência, fatos/posição de mercado;
- separação explícita entre equipamentos legados e equipamentos canônicos;
- semântica correta para dado ausente: ausência de vínculo não equivale a `não possui`.

### Delta BPT2

BPT2 já possui identidade canônica Brand → Model → Generation → Version → Vehicle e Vehicle Hub, mas não possui superfície de comparação entre Vehicles.

### Hipótese falsificável

> Uma comparação baseada exclusivamente em identidade e enrichment canônicos do BPT2 consegue produzir matriz consistente para 2 e 3 Vehicles sem inferir dados ausentes nem depender de Listing legado.

### Teste antes de implementação funcional

1. montar fixture canônica com pelo menos 3 Vehicles e campos preenchidos/ausentes de forma controlada;
2. definir contrato puro de célula: valor conhecido, não informado, indisponível confirmado;
3. provar simetria da matriz: A×B e B×A preservam os mesmos fatos;
4. provar cardinalidade 2x/3x;
5. provar `only differences` sobre valores normalizados;
6. provar que Vehicle sem enrichment continua comparável sem inventar conteúdo;
7. reprovar a hipótese se a cobertura canônica exigir fallback textual de Listing para o conjunto mínimo definido.

### Decisão atual

`CANDIDATO FORTE`, não `TRAZER` ainda.

## 2. Analytics — instrumento, não dashboard por default

### Comportamento comprovado no donor

O donor agrega eventos em períodos 7/30/90 dias e calcula, entre outros:

- visitantes;
- visualizações de anúncio/market position/similares/upgrade/promotions;
- comparações;
- clicks;
- leads;
- CTR por funcionalidade;
- lead rate;
- aquisição por source/campaign/funcionalidade;
- top anúncios por leads.

Ele também carrega attribution com `sessionId`, `source`, `medium`, `campaign`, `content`, `term` e `referrer`.

### Delta BPT2

BPT2 mede estados funcionais por testes e possui Leads persistidos, mas não tem uma capability de instrumentação/agregação de produto consolidada.

### Risco identificado

Copiar o módulo analytics do donor misturaria cedo demais:

- telemetria;
- attribution de marketing;
- dashboards;
- métricas específicas de features que ainda nem existem no BPT2.

### Hipótese falsificável

> Um contrato mínimo de eventos de produto, independente de dashboard e de features futuras, é necessário e suficiente para medir o efeito dos próximos slices candidatos.

### Teste antes de implementação

1. listar apenas decisões pós-MVP que realmente exigem medição;
2. para cada decisão, especificar evento mínimo + unidade de análise + denominador;
3. demonstrar que as métricas pretendidas podem ser calculadas deterministicamente a partir desse contrato;
4. rejeitar eventos sem pergunta de produto associada;
5. validar idempotência/deduplicação de eventos relevantes;
6. separar PII/identidade de usuário de attribution quando não necessária;
7. só promover dashboard se houver operador/decisão que o consuma.

### Decisão atual

`CANDIDATO INSTRUMENTAL`. É possível que instrumentação mínima preceda outras features, sem que isso implique construir um dashboard analítico amplo.

## 3. CRM / Lead pipeline — separar operação de attribution

### Comportamento comprovado no donor

O donor modela:

- `NOVO`;
- `CONTATADO`;
- `NEGOCIACAO`;
- `VENDIDO`;
- `PERDIDO`;
- timestamps `contactedAt`, `negotiationAt`, `wonAt`, `lostAt`, `closedAt`;
- attribution no momento de criação do Lead;
- associação heurística da funcionalidade que precedeu o Lead;
- Seller restrito a operações autorizadas sobre seus Leads.

### Estado BPT2

O agregado `Lead` atual possui:

- `ListingId`;
- `UserId?`;
- `Channel`;
- `CreatedAtUtc`;
- `ContactedAtUtc?`;
- `MarkContacted()` idempotente.

Esse estado foi deliberadamente definido como o mínimo operacional do MVP.

### Delta objetivo

Faltam, caso sejam necessários:

- negociação;
- ganho/perda;
- fechamento;
- métricas de conversão por estágio;
- attribution/origem de marketing.

### Hipótese falsificável

> O Seller precisa de pelo menos um estado além de `contatado` para operar e aprender com Leads reais; attribution não precisa fazer parte do agregado operacional de Lead para provar essa hipótese.

### Teste antes de implementação

1. modelar fluxo mínimo hipotético `Novo → Contatado → Fechado` e comparar contra o pipeline completo do donor;
2. definir quais decisões operacionais são impossíveis hoje com apenas `ContactedAtUtc`;
3. exigir propriedade server-side e histórico de transição;
4. testar idempotência das transições;
5. testar estados terminais e comportamento de reabertura antes de permitir qualquer reversão;
6. manter attribution fora do contrato operacional inicial, salvo se um caso real exigir;
7. reprovar o pipeline de 5 estados se 3 estados cobrirem o problema operacional medido.

### Decisão atual

`GAP REAL`, mas **não copiar automaticamente os cinco estados**. O número de estados deve ser derivado do fluxo BPT2.

## 4. Promotions — dependências científicas

### Hipótese

> Destaque pago pode aumentar exposição e leads sem corromper visibilidade, elegibilidade ou interpretação do ranking orgânico.

### Testes necessários antes de promover

- regra determinística de elegibilidade: somente Listing público e válido;
- expiração automática da promoção;
- identificação visual clara de conteúdo promovido;
- nenhum Draft/private pode aparecer por efeito de promoção;
- métricas separadas de impressão, click e Lead;
- baseline orgânico preservado para comparação;
- critérios explícitos para medir lift;
- não introduzir credits/payment antes de provar que o modelo de monetização os exige.

## 5. Vehicle enrichment — dependências de qualidade

### Hipótese

> Enrichment canônico aumenta utilidade de Vehicle Hub/comparador/discovery sem comprometer a autoridade do catálogo.

### Testes necessários antes de promover

- provenance por dado/fonte aplicável;
- regra de precedência entre fontes;
- representação de `não informado` distinta de `não possui`;
- reconciliation para Vehicle canônico;
- comportamento diante de conflito;
- versionamento temporal quando o dado puder mudar;
- cobertura mensurável do conjunto de Vehicles escolhido para o experimento;
- nenhuma dependência de scraping/connector específico incorporada ao domínio canônico.

## 6. Alertas, retenção e recomendações

Essas capacidades permanecem em `VALIDAR ANTES` porque existência no donor e no mercado não prova valor incremental no BPT2.

### Alertas

Exigir antes:

- opt-in explícito;
- matching determinístico;
- deduplicação;
- idempotência;
- política de frequência;
- definição de evento real que dispara alerta de preço/estoque/lead parado.

### Similar vehicles / upgrade suggestions

Exigir antes:

- dataset fixo;
- baseline simples;
- definição de relevância;
- casos adversariais;
- métrica offline antes de qualquer IA/ML;
- experimento online apenas depois da qualidade offline mínima.

## Ordem de investigação derivada

Esta é ordem de **auditoria/teste**, não compromisso de implementação:

1. Comparador;
2. Instrumentação mínima de Analytics;
3. CRM / Lead pipeline;
4. Promotions;
5. Vehicle enrichment;
6. Alertas/retenção;
7. Compra Assistida;
8. Similar vehicles / upgrade suggestions;
9. busca avançada/geo somente quando seus próprios testes justificarem.

## Critério de promoção para um futuro execution plan

Uma capability só pode sair deste documento para um execution plan funcional quando houver:

1. problema BPT2 explícito;
2. delta não coberto por capability atual;
3. evidência donor/externa qualificada;
4. hipótese falsificável;
5. teste/benchmark definido antes da implementação;
6. menor slice capaz de reprovar ou confirmar a hipótese;
7. invariantes de segurança/ownership/catalog authority preservados.

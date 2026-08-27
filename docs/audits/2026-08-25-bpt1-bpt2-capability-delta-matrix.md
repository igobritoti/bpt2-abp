# BPT1 ↔ BPT2 — capability delta matrix

Data original da auditoria: 2026-08-25

Reconciliado com o estado corrente do BPT2 em 2026-08-27.

Status: **AUDITORIA CONCLUÍDA + RECONCILIAÇÃO CORRENTE**. Este documento registra o delta funcional do donor BPT1 contra o produto BPT2 e acompanha o que foi posteriormente promovido, entregue, bloqueado, adiado ou descartado. Ele não autoriza portar implementação do BPT1.

## Regra de leitura

- **A** = documentação oficial atual, contrato/código versionado, standard aplicável.
- **B** = comportamento empiricamente executado/reproduzido, incluindo CI/teste do donor quando o teste cobre o comportamento em questão.
- **C** = inferência arquitetural derivada de A/B.
- **D** = preferência/opinião.

BPT1 é donor de capacidades e comportamento. BPT2 é a autoridade do produto atual e de sua arquitetura.

`TRAZER` significa promover o menor slice BPT2 justificado pela evidência; nunca significa portar arquitetura, código ou desenho interno do BPT1 por continuidade histórica.

## Baseline de evidência do donor

O `main` auditado de `igobritoti/bomprati`, head `04a9c264a841e67b28daa28f1564109a3178de79`, teve o workflow `quality-gates` concluído com sucesso. O pipeline executava automaticamente os testes determinísticos encontrados em `src/` e `scripts/`, além de lint, Prisma validate/generate, build, typecheck, migration deploy e runtime smoke.

Isso aumenta a confiança em módulos com testes presentes no head, mas não prova que toda feature esteja coberta end-to-end.

## Matriz reconciliada BPT1 → BPT2

| Capability | Evidência BPT1 | Decisão da auditoria em 25/08 | Estado BPT2 reconciliado | Observação corrente |
|---|---|---|---|---|
| Seller / Listing lifecycle | fluxo central, rotas e módulos reais; CI verde | JÁ EXISTE | **ENTREGUE** | self-registration/login → profile → My Listings → Vehicle canônico → Draft/Edit → Photos → Publish/Pause/Archive comprovado por HTTP/OIDC |
| Favorites | feature real | JÁ EXISTE | **ENTREGUE** | ownership server-side, isolamento entre Buyers e visibilidade pública comprovados |
| Listing reports + moderação mínima | módulo/auditorias no donor | JÁ EXISTE / revisar extensões | **ENTREGUE** | report idempotente + fila admin + retirar/restaurar visibilidade; extensões sofisticadas seguem adiadas |
| WhatsApp → Lead | fluxo real | JÁ EXISTE | **ENTREGUE** | Lead persistido antes do redirect; sessão Buyer válida preserva `UserId` sem tornar login obrigatório |
| SEO público / Vehicle Hub baseline | testes e superfícies próprias | JÁ EXISTE | **ENTREGUE** | canonical, robots, sitemaps, social metadata e structured data entregues |
| Busca textual/filtros | discovery real | JÁ EXISTE / validar extensões | **ENTREGUE NO BASELINE** | título + Brand/Model/Generation/Version, filtros, paginação, query string e ordenação por preço; fuzzy/autocomplete/facets/ranking continuam sem promoção |
| CRM / Lead lifecycle mínimo | pipeline completo no donor | TRAZER menor slice; não copiar 5 estados | **ENTREGUE** | BPT2 entregou `ContactedAtUtc` + fechamento `Won/Lost`, idempotência, ownership e histórico após Pause/Archive |
| Pipeline CRM de 5 estados | `NOVO → CONTATADO → NEGOCIACAO → VENDIDO/PERDIDO` | DESCARTAR COMO PRIMEIRO DESENHO | **DESCARTADO NO BASELINE** | `NEGOCIACAO` e demais estados só reabrem com problema operacional real |
| Lead attribution | source/medium/campaign/content/term/referrer/session | VALIDAR ANTES | **PENDENTE** | BPT2 preserva `UserId`/Channel; attribution de marketing continua sem pergunta operacional + privacy contract |
| Analytics / funil amplo | visitors, views, clicks, leads, CTR, leadRate, comparisons e attribution | DESCARTAR COMO PRIMEIRA META | **NÃO ENTREGUE / ADIADO** | instrumentação deve nascer vinculada a uma hipótese concreta, não como plataforma antecipada |
| Instrumentação mínima | eventos e métricas no donor | EMBUTIR QUANDO NECESSÁRIA | **PARCIAL POR FEATURE** | não existe capability analítica consolidada; instrumentação dedicada só quando uma decisão mensurável exigir |
| Promotions / boost | promoção real + eventos de view/click | VALIDAR ANTES — candidato forte | **ENTREGUE NO BASELINE** | sponsorship time-bounded + `IsSponsored` + UI `Patrocinado`, sem alterar ranking orgânico; billing/planos/métricas comerciais seguem pendentes |
| `HighlightScore` | mecanismo no donor | DESCARTAR | **DESCARTADO** | não portar mistura de pago, relevância, preço, popularidade e recomendações |
| Vehicle Knowledge / safety / equipment / market position | backfill/enrichment, UI e métricas | VALIDAR ANTES — alta prioridade | **BLOQUEADO** | Structure canônica existe; enrichment técnico publicado suficiente do Podium ainda não existe |
| Comparador técnico 2–4 | rota `/comparar`, matriz técnica, `diff=1`, preço/mercado/equipamentos | VALIDAR ANTES — bloqueado por enrichment | **BLOQUEADO** | identidade canônica sozinha não sustenta ficha comparável; exige enrichment com unidade, null/unknown, revision e provenance |
| Saved Search | não era baseline donor principal da auditoria; benchmark externo reforçava hipótese | VALIDAR ANTES — candidato forte | **ENTREGUE NO BASELINE** | critérios semânticos persistidos, ownership, deduplicação e reabertura de resultados comprovados |
| Saved Search new-listing detection | hipótese posterior testada no BPT2 | validar contrato antes de delivery | **ENTREGUE** | opt-in explícito, matching reutilizando busca pública, ledger idempotente e request durável na primeira publicação |
| Saved Search runner automático | retenção/alertas no donor | dependência não resolvida | **BLOQUEADO** | falta decisão segura de deployment/locking + claim/concurrency/retry/restart; provider/canal não escolhido |
| Favorite price-drop detection | price-drop no donor | VALIDAR ANTES | **ENTREGUE** | queda em Listing publicada cria ledger somente para Favorites temporalmente elegíveis; replay idempotente, aumento ignorado e unfavorite impede match futuro |
| Favorite price-drop delivery | alertas no donor | VALIDAR ANTES | **PENDENTE** | detector existe; provider/canal/delivery não foram escolhidos |
| Alertas / retenção adicionais | weekly seller report, lead stagnation | VALIDAR ANTES | **PENDENTE** | existência no donor não prova valor incremental no BPT2 |
| Similar vehicles | implementação própria + analytics | VALIDAR POR MÉTRICA | **BLOQUEADO** | falta dataset fixo, baseline e métrica de relevância |
| Upgrade suggestions | implementação própria + analytics | VALIDAR POR MÉTRICA | **BLOQUEADO** | mesmo blocker de dataset/baseline/métrica |
| Compra Assistida | rota, schema, services e testes | VALIDAR ANTES | **PENDENTE** | precisa provar problema não coberto por discovery/comparator |
| Credits | ledger, grant/consume e testes | ADIAR | **ADIADO** | mecanismo comercial, não problema de produto; só reabrir se modelo comercial exigir |
| Payments | módulo, services, webhook e validação | ADIAR | **ADIADO** | fora do núcleo de venda do veículo; requer tese comercial específica |
| Financiamento | intenção/capacidade complementar | ADIAR | **ADIADO** | depende de parceria/modelo comercial |
| Seguros | intenção/capacidade complementar | ADIAR | **ADIADO** | depende de parceria/modelo comercial |
| Vehicle Trust Signals | referências de mercado/donor | VALIDAR ANTES / PESQUISAR | **BLOQUEADO/ADIADO** | precisa provider, validade, privacy/legal e problema operacional verificável |
| Contexto de preço de mercado | dados/métricas no donor | ADIAR ATÉ DADOS | **BLOQUEADO** | sem dataset/licença/metodologia/provenance exibível |
| Listing completeness score | hipótese derivada | VALIDAR ANTES | **PENDENTE** | exigir correlação com Lead antes de afetar qualquer ranking |
| Geo authority / radius | portais externos + hipótese | VALIDAR ANTES | **PENDENTE** | BPT2 possui City/StateCode textuais; geocoding/GPS/radius exigem autoridade geográfica e comportamento medido |
| Planner | contratos de work-unit + testes | DESCARTAR COMO FEATURE | **DESCARTADO** | tooling, não produto |
| Argus Core | runner/locks/reports/execution + testes | DESCARTAR COMO FEATURE | **DESCARTADO** | tooling/infra, não produto |

## Capacidades promovidas depois da auditoria de 25/08

A matriz original era um checkpoint, não um backlog permanente. As seguintes capacidades mudaram de estado após testes/slices posteriores e não devem ser reabertas como se ainda estivessem apenas em avaliação:

1. **CRM mínimo de Lead** — fechamento `Won/Lost` foi entregue sem transplantar o pipeline BPT1 de cinco estados.
2. **Saved Search baseline** — persistência de critérios semânticos, ownership, deduplicação e reabertura foram entregues.
3. **New-listing alert detection** — opt-in, matching determinístico, ledger e trigger durável de detecção foram entregues; runner/delivery continuam separados e pendentes.
4. **Promotions baseline** — sponsorship explícito e time-bounded foi entregue sem contaminar ranking orgânico; `HighlightScore` continua descartado.
5. **Favorite price-drop detector** — contrato temporal/replay-safe foi entregue; delivery continua não entregue.

Essas promoções substituem os estados históricos `TRAZER`/`VALIDAR ANTES` para o baseline já comprovado. Extensões continuam sujeitas a nova hipótese e nova evidência.

## Gaps reais ainda abertos do donor

### Comparador e Vehicle Enrichment

O donor prova que uma comparação técnica é uma capability real, mas o BPT2 não deve reproduzi-la com labels ou dados incompletos. O blocker atual é contrato de enrichment publicado suficientemente forte: potência/torque/consumo/dimensões/equipamentos/segurança com unidade, semântica de null/unknown, revision e provenance. Até isso existir, Comparator permanece bloqueado.

### Attribution e Analytics

O donor demonstra acquisition attribution e funil analítico, mas copiar essa plataforma antecipadamente misturaria telemetria, marketing attribution, dashboards e features ainda inexistentes. BPT2 só deve promover instrumentação vinculada a uma pergunta operacional/métrica concreta; attribution exige também contrato de privacidade.

### Alert delivery / runners

Detecção e persistência de intent já foram separadas de delivery. A pendência não é mais provar Saved Search ou price-drop; é definir com segurança runner/deployment/locking/retry/restart e, separadamente, provider/canal/template quando houver necessidade real.

### Recomendações, Compra Assistida e complementos comerciais

Similar vehicles, upgrade suggestions, Compra Assistida, financing, insurance, credits e payments permanecem fora do baseline até seus próprios datasets, métricas, parcerias ou teses comerciais justificarem promoção.

## Capacidades deliberadamente não migradas

Os seguintes elementos do BPT1 não devem reaparecer por inércia histórica:

- pipeline CRM de cinco estados como desenho padrão;
- `HighlightScore`;
- Planner como feature de produto;
- Argus Core como feature de produto;
- credits/payments sem tese comercial que os exija;
- arquitetura, persistência ou infraestrutura do donor apenas por sunk cost.

## Regra de promoção futura

Uma capability do BPT1 só pode gerar novo execution plan funcional quando houver:

1. problema BPT2 explícito;
2. delta ainda não coberto por capability atual;
3. evidência donor/externa qualificada;
4. hipótese falsificável;
5. teste/benchmark definido antes da implementação;
6. menor slice capaz de reprovar ou confirmar a hipótese;
7. invariantes de segurança, ownership e autoridade do catálogo preservados.

Antes de abrir novo slice, conferir `docs/PRODUCT.md` e o checkpoint corrente em `docs/agent/CURRENT-WORK.md`, porque esta matriz preserva a origem BPT1 do raciocínio, enquanto `PRODUCT.md` é a autoridade do estado funcional entregue.

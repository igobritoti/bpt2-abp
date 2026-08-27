# Matriz unificada de cobertura funcional — BPT2

Data: 2026-08-27

Status: checkpoint documental. Esta matriz consolida o estado funcional atual do BPT2 com a auditoria donor BPT1 e os blockers/gatilhos já documentados. Não autoriza implementação por si só.

## Regra de leitura

Estados usados:

- **JÁ EXISTE** — capacidade comprovada no BPT2 atual por código/teste/HTTP/CI e consolidada em `PRODUCT.md`;
- **PARCIAL** — parte útil da capacidade está entregue, mas existe boundary relevante ainda não entregue;
- **GAP REAL** — capacidade ausente no BPT2 e com problema/delta reconhecido, mas ainda requer teste antes de implementação;
- **BLOQUEADO** — não promover enquanto faltar pré-condição explícita;
- **ADIADO** — não há necessidade/problema suficiente para promover agora;
- **DESCARTADO** — desenho/capacidade donor explicitamente não deve ser transplantado como feature atual.

Prioridade de evidência:

`teste/código executado > código existente > documentação atual > issue/PR > inferência`

Fontes principais:

- `docs/PRODUCT.md` — autoridade do estado funcional entregue;
- `docs/audits/2026-08-25-bpt1-bpt2-capability-delta-matrix.md` — auditoria donor reconciliada;
- `docs/audits/2026-08-25-capability-final-decision-matrix.md` — decisões históricas do Plan 0046;
- `docs/audits/2026-08-26-post-plan0050-trigger-sweep.md` e checkpoint posterior — blockers/gatilhos;
- execution plans e PRs já concluídos para evidência detalhada.

## Matriz

| Área | Capability | Estado atual | Evidência/decisão consolidada | Próximo gatilho válido |
|---|---|---|---|---|
| Seller | Cadastro/login Seller | JÁ EXISTE | OIDC Authorization Code + PKCE e fluxo HTTP real | só novo gap de produto |
| Seller | Perfil + My Listings | JÁ EXISTE | ciclo Seller consolidado em `PRODUCT.md` | só novo gap de produto |
| Seller | Draft/Edit/Publish/Pause/Archive | JÁ EXISTE | lifecycle ownership-safe + concurrency + HTTP | só novo gap de produto |
| Seller | Fotos upload/preview/reorder/remove | JÁ EXISTE | Media/ListingPhoto e gates HTTP | só novo gap de produto |
| Buyer | Cadastro/login Buyer | JÁ EXISTE | self-registration + BuyerWeb PKCE | só novo gap de produto |
| Buyer | Favorites | JÁ EXISTE | add/remove/mine/isolation e visibilidade pública | só extensão com hipótese própria |
| Discovery | Busca textual + identidade canônica | JÁ EXISTE | Title + Brand/Model/Generation/Version | corpus/métrica apenas para extensões |
| Discovery | Filtros/paginação/query string/preço | JÁ EXISTE | comportamento público comprovado | só novo gap de produto |
| Discovery | Fuzzy/autocomplete/facets/relevance | BLOQUEADO | sem corpus, baseline e métrica suficientes | corpus fixo + métrica reproduzível |
| Discovery | Geo/radius/proximidade | BLOQUEADO | City/StateCode atuais não implicam autoridade geográfica | autoridade geográfica + comportamento de distância |
| Public Detail | Detalhe, galeria e WhatsApp CTA | JÁ EXISTE | fluxo público real | só novo gap de produto |
| Leads | Persistência de Lead WhatsApp | JÁ EXISTE | Lead nasce antes do redirect; anônimo permitido | só novo gap de produto |
| Leads | Atribuição ao Buyer autenticado | JÁ EXISTE | `UserId` preservado quando há sessão válida | attribution marketing é capability distinta |
| Leads | Seller inbox + MarkContacted | JÁ EXISTE | ownership server-side + histórico | só novo gap operacional |
| Leads | Close Won/Lost | JÁ EXISTE | entregue após auditoria donor; idempotência/conflito cobertos | reabrir somente se fluxo real exigir mais estados |
| Leads | Pipeline CRM de cinco estados | DESCARTADO | donor não provou necessidade de transplantar `NEGOCIACAO` etc. | ação/SLA/fila real que exija estado adicional |
| Leads | Attribution marketing | GAP REAL | source/medium/campaign do donor não foram promovidos | pergunta concreta de aquisição + privacy contract |
| Leads | Analytics/dashboard amplo | ADIADO | plataforma ampla sem pergunta operacional é premature | pergunta mensurável + consumidor operacional |
| Saved Search | Salvar/listar/excluir/reabrir critérios | JÁ EXISTE | semântica pública reutilizada; ownership e dedup | só novo gap de produto |
| Saved Search | Detecção de nova oferta | JÁ EXISTE | opt-in + ledger + matching apenas público | delivery permanece separado |
| Saved Search | Trigger durável na primeira publicação | JÁ EXISTE | request durável único por Listing no mesmo UoW | runner seguro |
| Saved Search | Runner automático | BLOQUEADO | falta contrato deployment/claim/concurrency/retry/restart/locking | decisão operacional de deployment + distributed lock real se cluster |
| Saved Search | Delivery externo de alertas | PARCIAL | detecção existe; provider/canal/template não escolhidos | canal/provider + política de frequência/idempotência |
| Price | Histórico de preço publicado | JÁ EXISTE | Draft e preço inalterado não geram histórico | só novo gap de produto |
| Favorites | Detector de price-drop | JÁ EXISTE | temporal eligibility + replay/idempotência entregues | delivery se houver hipótese real |
| Favorites | Delivery de price-drop | PARCIAL | detector existe; notificação externa não | preferência/canal + política de frequência |
| Moderação | Buyer report | JÁ EXISTE | idempotência Buyer+Listing e histórico | só novo gap operacional |
| Moderação | Fila admin + retirar/restaurar | JÁ EXISTE | autoridade humana mínima server-side | só novo gap operacional |
| Moderação | Taxonomia/SLA/evidence/scoring/notificações | ADIADO | nenhum déficit operacional/provider/legal suficiente | evidência operacional ou contrato externo |
| Trust | Trust signals / histórico / vistoria | BLOQUEADO | confiança é core, mas falta provider/privacy/legal/validity contract | provider e contrato verificáveis |
| Promotions | Sponsored Listing baseline | JÁ EXISTE | janela temporal, badge e isolamento do ranking orgânico | tese comercial/instrumentação se necessário |
| Promotions | `HighlightScore` BPT1 | DESCARTADO | mistura sinais pagos/orgânicos/preço/popularidade | não portar |
| Promotions | Planos/billing/credits/payments | ADIADO | mecanismo comercial sem tese comprovada | modelo comercial explícito |
| SEO | Canonical/robots/sitemaps | JÁ EXISTE | superfície pública comprovada | somente gaps novos |
| SEO | Social metadata + structured data | JÁ EXISTE | Listing/Vehicle Hub/Seller Hub/home conforme cobertura atual | estratégia editorial/keywords se necessária |
| SEO | Social image dedicada/SEO local/editorial | ADIADO | não há hipótese/estratégia fechada suficiente | keyword/landing/analytics/SEO question concreta |
| Catalog | Brand→Model→Generation→Version→Vehicle | JÁ EXISTE | Catalog é autoridade publicada | só novo gap estrutural |
| Vehicle Hub | Hub público + ofertas públicas | JÁ EXISTE | identidade canônica, sitemap e structured data | enrichment publicado |
| Vehicle Knowledge | Enrichment técnico amplo | BLOQUEADO | identity Podium atual é insuficiente para specs comparáveis | contrato publicado com unidade/null/revision/provenance |
| Comparator | Comparador 2–4 Vehicles | BLOQUEADO | valor/donor fortes, mas Structure isolada é insuficiente | enrichment mínimo comprovado |
| Recommendations | Similar vehicles | BLOQUEADO | donor existe, mas falta dataset/baseline/relevance metric BPT2 | dataset fixo + métrica offline |
| Recommendations | Upgrade suggestions | BLOQUEADO | mesma ausência de baseline/métrica | dataset fixo + métrica offline |
| Market | Contexto/inteligência de preço de mercado | BLOQUEADO | sem dataset/licença/metodologia/provenance | dataset verificável + metodologia |
| Admin | Hub `/admin` + resumo operacional | JÁ EXISTE | role admin + superfícies existentes | só novo gap de autoridade/operação |
| Admin | Permissões granulares/frontend separado | ADIADO | role `admin` suficiente no baseline | necessidade real de separar autoridades |
| Integration | Ingestão manual legada | JÁ EXISTE | contratos legados mantidos | somente se houver novo requisito |
| Integration | Podium producer/feed boundary | PARCIAL | boundary e direção definidos; enrichment consumer insuficiente | contrato versionado publicado suficiente |
| Integration | Scraping/polling/matching automático no BPT2 | DESCARTADO/ADIADO | acquisition/evidence/reconciliation pertencem ao Podium | novo requisito que altere boundary |
| Services | Compra Assistida | ADIADO | donor implementado, mas problema incremental não provado no BPT2 | provar gap não coberto por discovery/comparator |
| Services | Financiamento | ADIADO | complementar ao core | parceria/tese comercial |
| Services | Seguros | ADIADO | complementar ao core | parceria/tese comercial |
| Tooling | Planner donor | DESCARTADO | tooling, não capability de produto | nenhuma |
| Tooling | Argus Core donor | DESCARTADO | tooling/infra, não capability de produto | nenhuma |

## Leitura operacional

Esta matriz deve ser consultada antes de abrir qualquer execution plan funcional.

1. Se estiver **JÁ EXISTE**, não reabrir sem novo gap comprovado.
2. Se estiver **PARCIAL**, o próximo slice só pode atacar o boundary explicitamente faltante.
3. Se estiver **BLOQUEADO**, não implementar workaround especulativo para contornar a pré-condição.
4. Se estiver **ADIADO**, uma referência no donor/mercado não basta para promoção.
5. Se estiver **DESCARTADO**, não transplantar por sunk cost ou paridade histórica.
6. Um **GAP REAL** só vira execution plan depois de hipótese falsificável, teste definido antes e menor slice capaz de reprovar/confirmar.

## Gaps atualmente elegíveis para investigação sem reabrir trabalho entregue

Nenhum item deve ser tratado automaticamente como próximo feature. Os candidatos que podem ser investigados quando houver pergunta concreta são:

- attribution de marketing mínima, se surgir pergunta real de aquisição;
- instrumentação mínima embutida em uma hipótese de produto específica;
- workflow adicional de Leads somente se o Won/Lost atual se mostrar insuficiente;
- Compra Assistida somente se discovery/comparator não cobrirem o problema observado.

Os demais candidatos de maior porte continuam bloqueados por pré-condições explícitas: enrichment/Comparator, discovery avançado/recomendações, runner de alertas, trust externo e inteligência de mercado.

## Autoridade

Em conflito entre esta matriz e evidência mais nova:

1. teste/código executado mais recente;
2. `docs/PRODUCT.md` atualizado;
3. audit/checkpoint mais recente;
4. esta matriz;
5. auditoria donor histórica.

A matriz é índice operacional de cobertura, não substituto do histórico de evidência.

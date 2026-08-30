# Matriz unificada de cobertura funcional — BPT2

Data original: 2026-08-27  
Última reconciliação: 2026-08-30

Status: índice operacional reconciliado com o estado entregue até PR #156 e com o audit de precondição #157. Esta matriz não autoriza implementação por si só.

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
- `docs/agent/CURRENT-WORK.md` — snapshot operacional corrente;
- `docs/audits/2026-08-29-advanced-discovery-baseline.md` — baseline reproduzível de discovery;
- `docs/audits/2026-08-30-discovery-typo-scoring-comparison.md` — comparação inicial de scorers;
- `docs/audits/2026-08-30-discovery-metamorphic-typo-robustness.md` — robustez metamórfica;
- `docs/audits/2026-08-29-saved-search-postgres-claim-baseline.md` — claim/recovery do runner;
- `docs/audits/2026-08-29-saved-search-email-delivery-contract-baseline.md` — delivery externo de Saved Search;
- `docs/audits/2026-08-29-podium-quantitative-consumer-benchmark.md` — boundary quantitativo consumer;
- `docs/audits/2026-08-29-ibge-municipality-identity-baseline.md` — identidade municipal;
- auditorias donor/decisão anteriores permanecem históricas e subordinadas à evidência mais nova.

## Matriz

| Área | Capability | Estado atual | Evidência/decisão consolidada | Próximo gatilho válido |
|---|---|---|---|---|
| Seller | Cadastro/login Seller | JÁ EXISTE | OIDC Authorization Code + PKCE e fluxo HTTP real | só novo gap de produto |
| Seller | Perfil + My Listings | JÁ EXISTE | ciclo Seller consolidado em `PRODUCT.md` | só novo gap de produto |
| Seller | Draft/Edit/Publish/Pause/Archive | JÁ EXISTE | lifecycle ownership-safe + concurrency + HTTP | só novo gap de produto |
| Seller | Fotos upload/preview/reorder/remove | JÁ EXISTE | Media/ListingPhoto e gates HTTP | só novo gap de produto |
| Buyer | Cadastro/login Buyer | JÁ EXISTE | self-registration + BuyerWeb PKCE | só novo gap de produto |
| Buyer | Favorites | JÁ EXISTE | add/remove/mine/isolation e visibilidade pública | só extensão com hipótese própria |
| Discovery | Busca textual + identidade canônica | JÁ EXISTE | Title + Brand/Model/Generation/Version | só extensão com hipótese própria |
| Discovery | Filtros/paginação/query string/preço | JÁ EXISTE | comportamento público comprovado | só novo gap de produto |
| Discovery | Filtro por cor | JÁ EXISTE | PR #89: trim + igualdade textual case-insensitive; composição e Saved Search preservados | só novo gap de produto |
| Discovery | Seleção guiada de versão/Vehicle | JÁ EXISTE | PR #92: Catalog paginado + seleção canônica; valor persistido é `VehicleId` | só extensão com hipótese própria |
| Discovery | Ordenação por recência | JÁ EXISTE | PR #98: `FirstPublishedAtUtc?`; republish não cria bump | só extensão com hipótese própria |
| Discovery | Apresentação hífen/espaço | JÁ EXISTE | PR #147: `T Cross` e `T-Cross` equivalentes no discovery de identidade, sem regressão no corpus congelado | só nova regra de apresentação com experimento próprio |
| Discovery | Typo/fuzzy tolerance e ranking avançado | BLOQUEADO | #112 criou corpus/qrels; #150 caracterizou quatro scorers; #154 ampliou para 33 mutações válidas e separou `word_similarity` de Levenshtein, mas não escolheu vencedor trigram/cutoff; #157 concluiu que falta cardinalidade independente para scale/index | catálogo independente mais amplo ou snapshot production-like autorizado, congelado antes de cutoff/index |
| Discovery | Geo/radius/proximidade | BLOQUEADO | município IBGE já está resolvido via PR #135; código municipal não é ponto físico | autoridade do ponto físico da Listing + privacy/precision/lifecycle (#116) |
| Public Detail | Detalhe, galeria e WhatsApp CTA | JÁ EXISTE | fluxo público real | só novo gap de produto |
| Leads | Persistência de Lead WhatsApp | JÁ EXISTE | Lead nasce antes do redirect; anônimo permitido | só novo gap de produto |
| Leads | Atribuição ao Buyer autenticado | JÁ EXISTE | `UserId` preservado quando há sessão válida | attribution marketing é capability distinta |
| Leads | Seller inbox + MarkContacted | JÁ EXISTE | ownership server-side + histórico | só novo gap operacional |
| Leads | Close Won/Lost | JÁ EXISTE | idempotência/conflito cobertos | reabrir somente se fluxo real exigir mais estados |
| Leads | Pipeline CRM de cinco estados | DESCARTADO | donor não provou necessidade de transplantar estados adicionais | ação/SLA/fila real que exija estado adicional |
| Leads | Attribution marketing | ADIADO | não há pergunta operacional, consumidor, taxonomia nem privacy/retention contract suficientes | pergunta concreta de aquisição + consumidor + privacy/retention contract |
| Leads | Analytics/dashboard amplo | ADIADO | plataforma ampla sem pergunta operacional é prematura | pergunta mensurável + consumidor operacional |
| Saved Search | Salvar/listar/excluir/reabrir critérios | JÁ EXISTE | semântica pública reutilizada; ownership e dedup | só novo gap de produto |
| Saved Search | Detecção de nova oferta | JÁ EXISTE | opt-in + ledger + matching apenas público | só novo gap de produto |
| Saved Search | Visualização in-app de ofertas detectadas | JÁ EXISTE | PR #100: ledger ownership-safe em `/buscas-salvas` | só extensão com hipótese própria |
| Saved Search | Trigger durável na primeira publicação | JÁ EXISTE | request único por Listing no mesmo UoW | só novo gap operacional |
| Saved Search | Runner automático | JÁ EXISTE | #117 / PRs #133, #140, #142 e #144: claim PostgreSQL, `FOR UPDATE SKIP LOCKED`, serialização explícita, retry diferido, non-starvation e cancellation correctness | só novo requisito de deployment/escala medido |
| Saved Search | Delivery externo de alertas por email | JÁ EXISTE | #118: autorização `EMAIL_EACH_NEW_MATCH` default OFF, intent durável, recipient resolvido no dispatch, Resend adapter/probe, idempotência, outcomes, suppression e webhook autenticado | ativação real depende de credenciais/sender/domain/approval de deployment; não reabre engenharia entregue |
| Price | Histórico de preço publicado | JÁ EXISTE | Draft e preço inalterado não geram histórico | só novo gap de produto |
| Favorites | Detector de price-drop | JÁ EXISTE | temporal eligibility + replay/idempotência | delivery se houver hipótese real |
| Favorites | Visualização in-app de price-drop | JÁ EXISTE | PR #101: ledger ownership-safe em `/favoritos` | só extensão com hipótese própria |
| Favorites | Delivery de price-drop | PARCIAL | detector e histórico in-app existem; canal externo ainda não possui authorization/delivery contract próprio | canal + consentimento/destinatário + recovery/idempotency |
| Moderação | Buyer report | JÁ EXISTE | idempotência Buyer+Listing e histórico | só novo gap operacional |
| Moderação | Fila admin + retirar/restaurar | JÁ EXISTE | autoridade humana mínima server-side | só novo gap operacional |
| Moderação | Taxonomia/SLA/evidence/scoring/notificações | ADIADO | nenhum déficit operacional/provider/legal suficiente | evidência operacional ou contrato externo |
| Trust | Trust signals / histórico / vistoria | BLOQUEADO | #115 separa official facts, history e physical inspection; faltam provider autorizado, Listing-instance binding e privacy/purpose/assertion contract | provider + contrato verificável + identidade da instância física |
| Promotions | Sponsored Listing baseline | JÁ EXISTE | janela temporal, badge e isolamento do ranking orgânico | tese comercial/instrumentação se necessário |
| Promotions | `HighlightScore` BPT1 | DESCARTADO | mistura sinais pagos/orgânicos/preço/popularidade | não portar |
| Promotions | Planos/billing/credits/payments | ADIADO | mecanismo comercial sem tese comprovada | modelo comercial explícito |
| SEO | Canonical/robots/sitemaps | JÁ EXISTE | superfície pública comprovada | somente gaps novos |
| SEO | Social metadata + structured data | JÁ EXISTE | Listing/Vehicle Hub/Seller Hub/home conforme cobertura atual | estratégia editorial/keywords se necessária |
| SEO | Social image dedicada/SEO local/editorial | ADIADO | não há hipótese/estratégia fechada suficiente | pergunta concreta de SEO/landing/analytics |
| Catalog | Brand→Model→Generation→Version→Vehicle | JÁ EXISTE | Catalog é autoridade publicada | só novo gap estrutural |
| Catalog | External provider identifiers | JÁ EXISTE | PR #139: projeção/sync de `external_identifiers`, correção A→B, empty-set clear, redirect convergence e collision fail-closed | provider concreto com stable key quando houver produto autorizado |
| Vehicle Hub | Hub público + ofertas públicas | JÁ EXISTE | identidade canônica, sitemap e structured data | enrichment publicado com produto concreto |
| Vehicle Knowledge | Enrichment estrutural | JÁ EXISTE | PR #127: `powertrain`, `transmission`, `body_style` projetados como strings opacas nullable do Podium | só evolução do contrato producer com evidência |
| Vehicle Knowledge | Enrichment quantitativo amplo | BLOQUEADO | #122 provou consumer lossless/revision/provenance/state/shape/comparability em corpus delimitado; não prova cobertura Brasil/produção nem produto a promover | cobertura production-like + pergunta consumer explícita |
| Comparator | Comparador 2–4 Vehicles | BLOQUEADO | consumer/comparability boundary já provado, mas cobertura Brasil/produção e produto concreto continuam insuficientes | dataset/cobertura representativa + atributos realmente publicados |
| Recommendations | Similar vehicles | BLOQUEADO | #113: Favorite/Lead positivos sem exposição não criam negativos; falta qrel humano ou behavioral exposure-aware | ground truth versionado + protocolo de avaliação |
| Recommendations | Upgrade suggestions | BLOQUEADO | #113: além de ground truth, falta objetivo direcional explícito de “upgrade” | objetivo direcional + ground truth versionado |
| Market | Contexto/inteligência de preço de mercado | BLOQUEADO | #114: stable provider binding já entregue via #139; faltam quantidade de produto e source/provider autorizado com metodologia/licença/provenance | quantidade explícita + provider/dataset autorizado |
| Admin | Hub `/admin` + resumo operacional | JÁ EXISTE | role admin + superfícies existentes | só novo gap de autoridade/operação |
| Admin | Permissões granulares/frontend separado | ADIADO | role `admin` suficiente no baseline | necessidade real de separar autoridades |
| Integration | Ingestão manual legada | JÁ EXISTE | contratos legados mantidos | somente se houver novo requisito |
| Integration | Podium producer/feed boundary | JÁ EXISTE | boundary estrutural versionado entregue; external IDs e consumer quantitativo possuem contratos/probes; Podium não entra no request path público | só novo contrato producer/consumer baseado em produto concreto |
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

## Estado da fila após #157

Os antigos candidatos internos de maior porte mudaram de estado:

- Saved Search runner: **entregue** (#117);
- Saved Search email delivery engineering boundary: **entregue** (#118); ativação Resend real é deployment externo;
- discovery corpus/baseline: **entregue** (#112);
- apresentação hífen/espaço: **entregue** (#147);
- comparação inicial de scorers: **entregue como benchmark** (#150), sem seleção de cutoff;
- robustez metamórfica: **entregue como benchmark** (#154), sem vencedor trigram;
- scale/index discovery: **SKIP** após #157 por falta de pool independente suficientemente amplo; não sintetizar negativos para fabricar escala;
- município IBGE: **entregue** (#135), enquanto true radius permanece bloqueado em #116;
- external provider identifier projection: **entregue** (#139), enquanto market intelligence permanece bloqueado em #114.

No estado atual, não há feature grande automaticamente autorizada para execução autônoma. As issues abertas #113–#116 permanecem bloqueadas por autoridade humana/externa explícita. Os itens ADIADOS continuam sem promoção automática.

Próximo trabalho técnico só deve nascer quando um gatilho documentado mudar ou quando surgir novo gap comprovado por comportamento/código/teste. Até lá, audits de precondição devem concluir `SKIP` quando faltarem dados/autoridade, em vez de fabricar corpus, requisito ou tecnologia.

## Autoridade

Em conflito entre esta matriz e evidência mais nova:

1. teste/código executado mais recente;
2. `docs/PRODUCT.md` atualizado;
3. audit/checkpoint mais recente;
4. esta matriz reconciliada;
5. auditoria donor histórica.

A matriz é índice operacional de cobertura, não substituto do histórico de evidência.

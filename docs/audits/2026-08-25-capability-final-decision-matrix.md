# Plan 0046 — matriz final de decisão

Data: 2026-08-25

Status: checkpoint CP5/CP6. As classificações refletem a evidência disponível nesta data e podem ser superseded por nova evidência registrada.

## Regra

`TRAZER` significa que há evidência suficiente para abrir um execution plan do menor slice BPT2 definido. Não significa portar implementação do BPT1.

`VALIDAR ANTES` significa que o problema/capability é plausível ou forte, mas ainda há dependência/hipótese não resolvida.

## Matriz

| Capability | Decisão | Motivo principal | Próxima prova |
|---|---|---|---|
| Seller/Listing lifecycle baseline | JÁ EXISTE | BPT2 cobre ciclo completo por HTTP/OIDC | só revisar novos gaps |
| Favorites | JÁ EXISTE | baseline Buyer entregue | extensão só por nova hipótese |
| Moderação mínima | JÁ EXISTE | report + autoridade admin entregues | workflow sofisticado continua adiado |
| SEO/Vehicle Hub baseline | JÁ EXISTE | canonical/sitemaps/metadata/structured data entregues | somente gaps novos |
| Busca textual/filtros atuais | JÁ EXISTE | query/filtros/paginação entregues | fuzzy/facets/ranking precisam própria evidência |
| CRM Lead lifecycle mínimo | **TRAZER — PRÓXIMO SLICE RECOMENDADO** | gap pequeno, central ao Seller; donor mostra Seller usando contato/venda sem exigir pipeline completo | testar close + Won/Lost, ownership e idempotência |
| Pipeline CRM de 5 estados | DESCARTAR COMO PRIMEIRO DESENHO | donor não prova necessidade Seller de todos os estados | `NEGOCIACAO` só volta com ação/SLA/fila real |
| Attribution de marketing | VALIDAR ANTES | útil, mas não necessária para lifecycle operacional | pergunta de aquisição concreta + privacy contract |
| Analytics/dashboard amplo | DESCARTAR COMO PRIMEIRA META | cria plataforma sem perguntas reais | instrumentação mínima por hipótese |
| Instrumentação mínima | EMBUTIR QUANDO NECESSÁRIA | deve medir feature/decisão real, não existir por si | evento mínimo junto ao experimento que o exige |
| Vehicle Enrichment mínimo | VALIDAR ANTES — ALTA PRIORIDADE | necessário para Comparador; PBEV é fonte forte, mas target Vehicle é ambíguo sem ModelYear | experimento Version/Vehicle reconciliation |
| Comparador 2–4 user-selected | VALIDAR ANTES — BLOQUEADO POR ENRICHMENT | valor e benchmark fortes; Structure atual é insuficiente | matriz Grupo A após reconciliation |
| Saved Search / inventory alerts | VALIDAR ANTES — CANDIDATO FORTE | fit natural com query/favorites e benchmark OLX; não comprovado no donor | round-trip criteria + deterministic matching |
| Favorite price-drop alert | VALIDAR ANTES | donor tem delivery e mercado usa; requer trigger/preference | price-change versioning + opt-in/dedup |
| Promotions | VALIDAR ANTES — CANDIDATO FORTE | capability alvo e benchmark de mercado | política sponsored separada do orgânico + lift |
| HighlightScore BPT1 | DESCARTAR | mistura pago, relevância, preço, popularidade e recomendações | não portar |
| Credits | ADIAR | mecanismo, não problema de produto | só se modelo comercial exigir |
| Payments | ADIAR | fora do baseline; não necessário para venda do veículo | tese comercial específica |
| Vehicle Trust Signals | VALIDAR ANTES / PESQUISAR | confiança é core; mercado mostra histórico/vistoria | provider/privacy/legal/validity contract |
| Contexto de preço de mercado | ADIAR ATÉ DADOS | valor de mercado exige fonte/licença ou amostra BPT suficiente | dataset + metodologia + threshold |
| Listing completeness score | VALIDAR ANTES | pode ajudar Seller sem ranking opaco | correlação com Lead antes de afetar ranking |
| Similar vehicles | VALIDAR ANTES | donor/mercado não provam qualidade BPT2 | dataset + baseline + relevance metric |
| Upgrade suggestions | VALIDAR ANTES | hipótese aspiracional/monetização | dataset + baseline + metric |
| Compra Assistida | VALIDAR ANTES | donor implementado/testado, mas complementar | provar problema não coberto por discovery/comparator |
| Geo authority / radius | VALIDAR ANTES | múltiplos portais usam proximidade; BPT2 hoje City/StateCode | autoridade geográfica + distance behavior |
| Financiamento | ADIAR | camada complementar | tese comercial/parceria |
| Seguros | ADIAR | intenção sem fluxo concreto suficiente | tese comercial/parceria |
| Planner / Argus Core | DESCARTAR COMO FEATURE | tooling/infra, não produto | nenhuma |

## Próximo slice único promovido

### CRM — fechamento mínimo de Lead

**Problema:** BPT2 sabe que o Lead nasceu e se foi contatado, mas não consegue representar deterministicamente que o atendimento terminou nem o resultado.

**Hipótese:** adicionar fechamento + outcome `Won/Lost` resolve fila operacional e permite medir conversão sem pipeline de cinco estados.

### Acceptance criterion proposto

Um Seller autenticado consegue, exclusivamente sobre Leads de seus próprios Listings:

1. manter `MarkContacted` atual monotônico/idempotente;
2. fechar um Lead com outcome explícito `Won` ou `Lost`;
3. repetir o mesmo fechamento sem duplicar efeito;
4. não sobrescrever silenciosamente outcome conflitante;
5. não alterar Lead de outro Seller;
6. continuar consultando o histórico após Listing Pause/Archive;
7. derivar deterministicamente `needs action`, contact rate e closed/won conversion sem `NEGOCIACAO`;
8. não introduzir attribution, notes, dashboard, pipeline de cinco estados ou automação neste slice.

### Evidência para promoção

- BPT2 Lead atual já possui ownership e `ContactedAtUtc` idempotente;
- BPT1 possui pipeline completo, mas a mutação Seller encontrada expõe apenas `CONTATADO` e `VENDIDO`, enfraquecendo a necessidade de transplantar todos os estados;
- fechamento/outcome é menor mudança capaz de responder `ainda exige ação?` e `qual foi o resultado?`.

Classificação da decisão: **C** derivada de contratos A e comportamento/testes B disponíveis. O valor operacional em produção deverá ser reavaliado quando houver dados reais de uso.

## Ordem restante após o próximo slice

A ordem abaixo continua sendo de investigação, não backlog contratual:

1. experimento de reconciliation/enrichment PBEV;
2. Comparador 2–4 após enrichment suficiente;
3. Saved Search / alerts;
4. Promotions com separação sponsored/orgânico;
5. Vehicle Trust Signals;
6. geo/radius;
7. market-price context quando houver dados;
8. recomendações/Compra Assistida conforme métricas.

## Resultado do Plan 0046 até este checkpoint

- inventário donor suficientemente amplo para evitar cherry-picking;
- tooling separado de produto;
- delta BPT1 ↔ BPT2 registrado;
- benchmark Webmotors/OLX verificado e iCarros usado como terceiro portal verificável; Carros na Web ficou sem conclusão atual por falha de acesso reproduzível;
- testes falsificáveis definidos para candidatos fortes;
- recomendações de adição/edição/exclusão/substituição registradas;
- apenas um próximo slice funcional foi promovido.

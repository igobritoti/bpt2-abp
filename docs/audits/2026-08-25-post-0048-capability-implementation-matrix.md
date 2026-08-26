# Matriz de implementação pós-0048

Data: 2026-08-25

Status: **checkpoint inicial do Plan 0049**

## Mudanças desde a matriz do Plan 0046

- CRM Lead closing mínimo foi entregue no Plan 0047 e deixa de ser gap.
- O experimento PBEV direto no BPT2 foi superseded pelo Plan 0048: Podium 7 é o knowledge producer/feed; BPT2 não deve duplicar acquisition/reconciliation.
- A topologia Podium/BPT2 (dois repos vs monorepo; Python vs convergência .NET) está explicitamente adiada e não bloqueia produto.
- Meta estratégica adicional: cobertura >=90% das capabilities úteis/elegíveis do Carros na Web, com ambição de 100%.

## Matriz corrente

| Bloco | Estado | Decisão atual | Próxima prova |
|---|---|---|---|
| Seller/Listing lifecycle | entregue | MANTER | novos gaps somente |
| Favorites | entregue | MANTER | extensões por hipótese |
| Lead lifecycle mínimo | entregue | MANTER | medir uso real depois |
| Moderação mínima | entregue | MANTER | avançado só por problema observado |
| Busca/filtros baseline | entregue | MANTER | advanced discovery separado |
| SEO/Vehicle Hub baseline | entregue | MANTER | enrichment pode ampliar valor |
| Catalog Structure | entregue | MANTER | projection de knowledge externo sem duplicar resolver |
| Podium → BPT2 identity mapping | experimental | PROMOVER MENOR SLICE | persistência real + replay + redirects + 0/1/N VehicleId |
| Enrichment técnico publicado | insuficiente | **PRIORIDADE ALTA** | read contract mínimo com fields/unidades/provenance de decisão de compra |
| Comparador 2–4 | bloqueado | VALIDAR DEPOIS DO ENRICHMENT | fixture >=3 Vehicles com matriz técnica útil |
| Saved Search / alerts | gap forte independente | VALIDAR/PROMOVER SE BLOQUEIO NO BLOCO A | criteria round-trip + matching determinístico |
| Favorite price drop | gap | VALIDAR | versionamento de preço + opt-in/dedup |
| Promotions | gap forte | VALIDAR | sponsored separado do orgânico + lift |
| Trust signals | gap | PESQUISAR | provider/source/legal/privacy |
| Moderação avançada | não necessária ainda | ADIAR | volume/motivo/SLA real |
| Geo/radius | gap plausível | VALIDAR | autoridade geo + comportamento distância |
| Similar/Upgrade | gap plausível | VALIDAR POR MÉTRICA | corpus + relevance baseline |
| Market price context | bloqueado por dados | ADIAR | dataset/licença/metodologia |
| Compra Assistida | complementar | ADIAR/VALIDAR | problema não coberto por discovery/comparator |
| Financiamento/Seguro | complementar | ADIAR | tese comercial/provider |
| Payments/Credits | complementar | ADIAR | modelo comercial explícito |
| Carros na Web coverage | inventário não executável ainda | TRILHA PARALELA | inventário verificável + custo/cobertura |

## Teste do contrato Podium atual para destravar Comparador

### Evidência

O `BOM-PRATICHE-CONTRACT-V2.md` congela um contrato de **identidade** com make/model/generation/variant/powertrain/transmission/body style/market, ranges de anos, aliases, engine IDs, external IDs e redirects.

Esse contrato não congela uma ficha técnica de consumo/potência/torque/dimensões/equipamentos/safety.

O benchmark `source_backed_enrichment_v3.json` prova enrichment interno/evidence-backed de alguns campos, incluindo `powertrain`, `transmission`, `body_style` e `generation`, mas não constitui sozinho um read contract técnico suficientemente amplo para o Comparador.

### Resultado

**REPROVADO PARA INICIAR O COMPARADOR COMPLETO AGORA.**

Motivo: uma matriz baseada apenas em identidade + poucos campos mecânicos não satisfaz o objetivo já definido de comparação técnica útil e criaria pressão para inventar/fallback em Listing.

### Menor prerequisite promovido

Definir e provar um **enrichment read contract mínimo Podium → BPT2** que:

1. seja separado do identity contract `2.0` ou versionado explicitamente sem quebrá-lo;
2. associe facts ao stable Podium ID;
3. exponha value + unidade + semântica de null/unknown + provenance/revision;
4. não exponha conflito não resolvido como fato aceito;
5. contenha atributos suficientes para responder perguntas reais de comparação;
6. possa ser projetado/persistido no BPT2 sem Listing fallback.

Candidatos de alto valor devem ser admitidos somente quando o Podium tiver evidência válida: potência, torque, transmissão, combustível/propulsão, consumo urbano/rodoviário, eficiência PBE, dimensões/capacidades e safety/equipment quando semanticamente seguros.

## Próximo slice recomendado

**Publication mapping + enrichment contract mínimo Podium → BPT2**, com escopo estrito.

Não é um projeto de ingestão novo. O objetivo é transformar conhecimento já resolvido/evidence-backed pelo Podium em uma projeção publicável/consumível pelo BPT2.

Se esse slice exigir alteração material no Podium que não possa ser feita no fluxo atual, aplicar a regra operacional e avançar para **Saved Search** como próximo gap independente, retornando ao enrichment depois.

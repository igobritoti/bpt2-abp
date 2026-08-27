# Audit — Podium enrichment readiness

Data: 2026-08-27

## Pergunta

Depois do primeiro feed estrutural `Podium 7 -> BPT2 Catalog`, quais dados do Podium já justificam promoção para novos campos/filtros do BPT2 e quais continuam bloqueados?

## Evidência inspecionada

- Podium Catalog JSON Contract `2.0` congelado.
- Implementação `CatalogVehicleIdentity` do Podium.
- benchmark Brazil `catalog_identity_golden_br_v1.json`.
- source-backed enrichment V3.
- Repeatable Web Extraction V1/V2 e segunda família FuelEconomy.gov.
- estado consolidado do BPT2 após Plan 0052.

## Resultado

| Capacidade/dado | Estado | Evidência/limite |
|---|---|---|
| make/model/generation/variant | JÁ USÁVEL | Contrato `2.0` + Plan 0052 entregues no BPT2. |
| canonical external id + redirects | JÁ USÁVEL | `entity.id`/`redirectsFrom` integrados com replay e continuidade histórica comprovados. |
| powertrain | CANDIDATO, NÃO PROMOVIDO | Campo pertence à identidade Catalog do Podium e aparece com evidência oficial em casos BR; cobertura do catálogo publicado ainda não foi medida como requisito de produto. |
| transmission | CANDIDATO, NÃO PROMOVIDO | Campo de identidade; benchmark BR e enrichment V3 mostram uso source-backed, inclusive Onix/T-Cross. Ainda sem métrica de cobertura do catálogo consumível. |
| body_style | CANDIDATO, NÃO PROMOVIDO | Campo de identidade; benchmark BR e enrichment V3 mostram valores explícitos (`SUV`, `hatch`, `pickup`, `sedan`). Ainda sem cobertura publicada medida. |
| market | NÃO PROMOVIDO | Existe no contrato, mas não há necessidade BPT2 comprovada para projetá-lo como filtro/atributo novo neste momento. |
| manufacture-year range | NÃO PROJETÁVEL NO V1 | BPT2 não possui dimensão equivalente explícita no Catalog atual. |
| model-year range real | NÃO PROJETÁVEL NO V1 | BPT2 `Vehicle.ModelYear?` é escalar; Plan 0052 falha fechado para ranges reais. |
| potência/torque/consumo/peso/dimensões | EXTRAÇÃO EXISTE; PRODUTO NÃO PRONTO | Podium possui extração determinística e evidência quantitativa em corpora limitados, mas esses dados não fazem parte do Catalog JSON `2.0` publicado. Cobertura heterogênea/produção não está estabelecida. |
| equipamentos/specs amplos para Comparator | BLOQUEADO | Ainda falta contrato de enrichment publicado com unidades, null/unknown, revision e provenance suficientes para consumo estável do BPT2. |

## Achados

### 1. `powertrain`, `transmission` e `body_style` não são campos decorativos

No Podium eles fazem parte de `CatalogVehicleIdentity`; mudanças nesses campos são classificadas como mudança de identidade. Portanto, se forem projetados no BPT2, devem permanecer associados à identidade canônica do Vehicle, não nascer como texto livre independente no Listing.

### 2. Há evidência brasileira real, mas ainda não há prova de cobertura para um filtro público geral

O benchmark Brazil usa explicitamente powertrain/transmission/body style em configurações como Corolla Cross, Onix, T-Cross e Strada. O enrichment V3 também mostra preenchimento source-backed desses campos para gaps reais de identidade.

Isso prova existência e utilidade semântica. Não prova que a população publicada do Podium tenha cobertura suficiente para oferecer um filtro público sem produzir uma experiência sistematicamente incompleta.

### 3. O Podium já extrai specs além do contrato de identidade

A extração web congelada mede fatos quantitativos e semânticos em corpora Autoevolution e FuelEconomy.gov. Há precisão local alta e política fail-closed, inclusive suporte a valores limitados/ranges e rejeição explícita de MPGe quando a semântica de MPG não se aplica.

Mas o próprio documento classifica generalização heterogênea/produção como desconhecida. Esses fatos não estão publicados no Catalog JSON `2.0`; portanto, não constituem ainda um consumer contract de enrichment para BPT2.

## Decisão

`PODIUM_STRUCTURE_FEED = JÁ EXISTE`

`POWERTRAIN_TRANSMISSION_BODY_STYLE_BPT2_PROJECTION = NÃO DECIDIDO / REQUER MEDIÇÃO DE COBERTURA`

`PUBLIC_FILTER_BY_POWERTRAIN_TRANSMISSION_BODY_STYLE = NÃO ABRIR AINDA`

`COMPARATOR_TECHNICAL_ENRICHMENT = BLOQUEADO`

## Próximo gate mínimo

Antes de alterar schema/UI do BPT2, medir sobre o corpus/catálogo canônico publicável do Podium:

- total de canonical vehicles avaliados;
- presença/null rate de `powertrain`, `transmission` e `body_style`;
- cobertura por mercado/source family, especialmente Brasil;
- cardinalidade e normalização dos valores;
- casos contraditórios/review que impediriam uso como filtro;
- estabilidade do contrato `2.0` para esses campos.

Somente depois dessa medição escolher se algum dos três campos merece um slice BPT2 de projeção + Vehicle Hub + filtro público. Não criar taxonomia/sinônimos no BPT2 para compensar ausência de evidência do producer.

# Consumer contract — ficha técnica / enrichment do Vehicle

Data: 2026-08-27

Status: **CONTRATO DE NECESSIDADE DO CONSUMIDOR / NÃO AUTORIZA SCHEMA POR SI SÓ**

## Pergunta

Quais fatos automotivos o BPT2 precisa conseguir consumir de um knowledge producer para evoluir Vehicle Hub, discovery e Comparator sem duplicar aquisição/reconciliation do Podium, inventar taxonomia local ou acoplar os dois sistemas por persistence/runtime?

## Evidência de base

- O BPT2 já possui Structure canônica `Brand → Model → Generation → Version → Vehicle` e integra o contrato Podium Catalog JSON `2.0` preservando `entity.id` e redirects.
- `powertrain`, `transmission` e `body_style` já aparecem como fatos de identidade no producer, mas a cobertura/normalização da população publicável ainda não foi medida.
- Potência, torque, consumo, peso e dimensões já possuem evidência de extração upstream em corpora limitados, porém não fazem parte de um contrato de enrichment publicado e estável consumível pelo BPT2.
- Comparator continua bloqueado porque fatos comparáveis exigem unidade, ausência explícita, revisão e provenance; existência de extração isolada não prova prontidão de produto.

Fontes internas principais:

- `docs/PRODUCT.md`;
- `docs/audits/2026-08-27-podium-enrichment-inventory.md`;
- `docs/exec-plans/completed/0052-podium-catalog-feed-v1.md`;
- `docs/audits/2026-08-27-unified-functional-coverage-matrix.md`.

## Princípios do boundary

1. **BPT2 define necessidade de consumo; Podium decide aquisição/evidence/reconciliation.**
2. **Contrato, não banco compartilhado.** O BPT2 não lê tabelas internas do producer e o public request path não depende da disponibilidade online do Podium.
3. **Vehicle, não Listing.** Fatos técnicos/configuracionais pertencentes à configuração automotiva canônica não devem nascer como texto livre do anúncio.
4. **Ausência é dado.** `unknown`, `not_applicable` e ausência de observação não devem ser convertidos em zero, string vazia, placeholder ou valor inferido.
5. **Unidades são parte do significado.** Quantidades sem unidade/semântica não são fatos comparáveis.
6. **Provenance e revisão são necessários para enrichment mutável.** O BPT2 precisa conseguir explicar de qual revisão/fonte publicada veio o fato quando essa distinção for material.
7. **Sem compensação local.** O BPT2 não cria sinônimos/taxonomia ad hoc para esconder baixa cobertura ou inconsistência upstream.
8. **Fail closed para perda semântica.** Se o domínio consumidor não representar corretamente range, limite, múltiplos valores ou aplicabilidade, não achatar arbitrariamente.

## Camadas de consumo

### Camada A — identidade/configuração

São os primeiros candidatos porque já participam da identidade Catalog do producer e podem melhorar Vehicle Hub/discovery sem exigir ainda uma ficha quantitativa completa.

| Fato | Uso BPT2 pretendido | Forma mínima necessária | Gate antes de projetar |
|---|---|---|---|
| `powertrain` | Vehicle Hub; possível filtro futuro | valor canônico publicado + null/unknown explícito | cobertura/null-rate + cardinalidade + normalização + recorte Brasil/market |
| `transmission` | Vehicle Hub; possível filtro futuro | valor canônico publicado + null/unknown explícito | cobertura/null-rate + cardinalidade + normalização + contradições |
| `body_style` | Vehicle Hub; possível filtro futuro | valor canônico publicado + null/unknown explícito | cobertura/null-rate + cardinalidade + normalização + contradições |

**Decisão:** nenhum desses três vira coluna/UI/filtro público apenas porque o campo existe no producer. Primeiro medir a população publicável. Não definir threshold numérico arbitrário antes de observar a distribuição real e o impacto da ausência.

### Camada B — motor/desempenho

| Fato | Uso pretendido | Semântica mínima de contrato |
|---|---|---|
| cilindrada/deslocamento | ficha técnica + Comparator | quantidade + unidade; aplicabilidade explícita para powertrains sem cilindrada |
| potência | ficha técnica + Comparator | valor ou intervalo/limite quando a fonte assim publicar + unidade e contexto de medição quando necessário |
| torque | ficha técnica + Comparator | valor ou intervalo/limite + unidade; não converter ausência em zero |
| combustível/energia/powertrain detail | ficha + comparação | categoria publicada estável; múltiplas fontes/energias representáveis sem concatenar texto |

O BPT2 não exige neste momento um modelo interno definitivo para estes campos. O primeiro deliverable upstream é um contrato publicado capaz de preservar a semântica observada.

### Camada C — eficiência/consumo

| Fato | Uso pretendido | Semântica mínima de contrato |
|---|---|---|
| consumo urbano | ficha + Comparator | quantidade + unidade + ciclo/método/mercado quando material |
| consumo rodoviário | ficha + Comparator | quantidade + unidade + ciclo/método/mercado quando material |
| consumo combinado | ficha + Comparator | quantidade + unidade + metodologia |
| eficiência elétrica/híbrida | ficha + Comparator futuro | não forçar MPGe/Wh/km/km/l para uma mesma semântica; tipo de métrica deve ser explícito |

**Regra:** valores de metodologias/mercados diferentes não são automaticamente comparáveis. O contrato deve permitir ao consumidor distinguir o contexto ou recusar comparação.

### Camada D — massa e dimensões

Candidatos: peso/massa, comprimento, largura, altura, entre-eixos, capacidade de porta-malas/carga quando houver evidência estável.

Requisitos mínimos:

- quantidade + unidade;
- tipo da medida (ex.: curb/kerb/gross quando aplicável), não apenas número;
- ranges/limites preservados se a fonte não publicar escalar único;
- `unknown/not_applicable` explícito;
- provenance/revision.

### Camada E — segurança e equipamentos

Não promover como schema amplo agora.

Antes disso, o producer precisa demonstrar:

- vocabulário/taxonomia reproduzível;
- diferença entre equipamento padrão, opcional, pacote e indisponível;
- aplicabilidade por versão/ano/mercado;
- provenance e revisão;
- cobertura suficiente para não transformar ausência de evidência em ausência do equipamento.

Essa camada não é pré-requisito para a primeira ficha técnica quantitativa.

## Envelope mínimo de um fato de enrichment

O nome exato do JSON não está decidido; o requisito semântico é:

- identidade estável do Vehicle/configuração externa à qual o fato se aplica;
- `field`/tipo de fato conhecido pelo contrato;
- valor tipado, preservando escalar/range/limite/múltiplo quando necessário;
- unidade quando quantitativo;
- estado de conhecimento (`known`, `unknown`, `not_applicable` ou equivalente semântico);
- market/aplicabilidade quando material;
- revision/version do payload publicado;
- provenance/source reference suficiente para auditoria do producer;
- comportamento determinístico de correção/substituição entre revisões.

O BPT2 não precisa receber páginas HTML, scraping evidence bruto ou detalhes internos de reconciliation para consumir o fato. Esses elementos continuam no bounded context do producer.

## Gates de prontidão

### Gate 1 — cobertura de identidade

Para `powertrain`, `transmission`, `body_style`, medir no catálogo canônico publicável:

- total avaliado;
- presença/null/unknown;
- distribuição por market/source family, Brasil explicitamente quando representado;
- cardinalidade dos valores;
- variantes de spelling/case/normalização;
- contradições/review cases;
- estabilidade no contrato publicado.

Saída esperada: relatório reproduzível, não opinião.

### Gate 2 — contrato quantitativo

Antes de BPT2 criar schema para potência/torque/consumo/peso/dimensões, o producer deve publicar exemplos reais que provem:

- unidade;
- null/unknown/not-applicable;
- escalar vs range/limite;
- market/metodologia quando relevante;
- revision/provenance;
- correção/replay determinísticos.

### Gate 3 — projeção BPT2

Somente depois dos Gates 1/2 escolher, por menor slice útil:

1. quais fatos entram no domínio/read model do BPT2;
2. se o primeiro uso é apenas Vehicle Hub ou também discovery;
3. quais campos são comparáveis no Comparator;
4. quais migrations e contratos públicos são necessários;
5. testes de replay, ausência, mudança de revisão e regressão.

### Gate 4 — filtro público

Um fato projetado no BPT2 não vira automaticamente filtro. Filtro exige prova adicional de que:

- cobertura e cardinalidade produzem uma experiência útil;
- semântica de igualdade/agrupamento está definida pelo contrato, não por heurística frontend;
- Saved Search/matching conseguem reutilizar exatamente a mesma semântica;
- ausência não exclui silenciosamente uma parcela material sem UX explícita.

## Primeira solicitação upstream recomendada

**Missão Podium: medir readiness de `powertrain`, `transmission` e `body_style` no catálogo publicável.**

A missão deve entregar somente medição e evidência reproduzível primeiro. Não deve, nessa etapa, inventar taxonomia nova, alterar BPT2, criar filtro público ou expandir para toda a ficha técnica.

Critérios de aceite da missão:

- corpus/população avaliada identificável e reproduzível;
- métricas de presença/null/unknown dos três campos;
- distribuição por market/source family, com Brasil destacado se presente;
- cardinalidade + valores distintos/normalizados;
- lista/contagem de conflitos/review cases quando houver;
- versão do contrato/output avaliado;
- resultado versionável que possa ser auditado novamente após mudanças do producer.

## Decisões explícitas

`TECHNICAL_SHEET_CONSUMER_BOUNDARY = BPT2 DEFINE NEEDS / PODIUM PUBLISHES EVIDENCED CONTRACT`

`SHARED_DATABASE_OR_RUNTIME_COUPLING = DESCARTADO`

`IDENTITY_ENRICHMENT_FIRST = POWERTRAIN + TRANSMISSION + BODY_STYLE, PENDING COVERAGE`

`QUANTITATIVE_SCHEMA_NOW = NÃO AUTORIZADO`

`COMPARATOR_NOW = BLOQUEADO ATÉ CONTRATO QUANTITATIVO PUBLICADO`

`PUBLIC_FILTER_FROM_PRODUCER_FIELD_EXISTENCE_ALONE = PROIBIDO`

## Próxima decisão

Depois do relatório upstream de readiness, reabrir este boundary e decidir por evidência se `powertrain`, `transmission` e/ou `body_style` merecem um slice BPT2 de projeção e qual deve ser o primeiro uso visível. Até lá, nenhum schema/taxonomia/filtro correspondente deve ser criado no BPT2.

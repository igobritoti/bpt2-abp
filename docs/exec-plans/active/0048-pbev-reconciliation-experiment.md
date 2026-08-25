# Plan 0048 — PBEV reconciliation experiment

Status: **ATIVO**

## Objetivo

Provar ou refutar uma reconciliação segura entre registros oficiais do Programa Brasileiro de Etiquetagem Veicular (PBEV/Inmetro) e a identidade canônica do catálogo BPT2, sem inventar `ModelYear`, sem matching automático por igualdade textual ingênua e sem autorizar ainda a implementação do Comparador.

## Base congelada

- partir do `main` após merge do PR #67 em `1471de8f69d0216f09d6c42c57a2ccbba900b2d7`;
- Plan 0047 concluído e arquivado;
- matriz do Plan 0046 define reconciliation/enrichment PBEV como próximo boundary antes do Comparador;
- `Vehicle` BPT2 referencia `BrandId`, `ModelId`, `GenerationId?`, `VersionId` e `ModelYear?`;
- `VehicleVersion` referencia `ModelId`, `GenerationId?`, `Name` e `NormalizedName`;
- Brand/Model/Version hoje normalizam nomes apenas por trim + uppercase;
- fonte oficial PBEV 2026 lista `Marca`, `Modelo`, `Versão` e atributos técnicos/energéticos, mas não fornece `ModelYear` como chave da linha observada.

## Problema

O PBEV é uma fonte oficial forte para consumo, eficiência, propulsão e emissões, mas sua granularidade não coincide automaticamente com a identidade `Vehicle` do BPT2. Um match textual direto `Marca + Modelo + Versão -> Vehicle` poderia:

- escolher arbitrariamente entre Vehicles de anos diferentes;
- falhar com diferenças de grafia, aliases ou equipamento agregado no nome da versão;
- misturar observação de ciclo PBEV com identidade permanente do catálogo;
- atribuir dados oficiais a um `ModelYear` que a fonte não declarou.

## Hipóteses falsificáveis

1. `Brand + Model + Version` pode reconciliar com confiança suficiente para `VehicleVersion` em uma amostra representativa, desde que ambiguidades sejam explicitamente rejeitadas.
2. O ciclo/ano da tabela PBEV não deve ser reinterpretado automaticamente como `Vehicle.ModelYear`.
3. Um registro PBEV pode ser armazenado como observação versionada/proveniente ligada a `VehicleVersion` mesmo quando nenhum `Vehicle` específico pode ser resolvido.
4. Matching automático só é aceitável para casos de unicidade determinística; casos ambíguos ou sem match devem permanecer pendentes/revisáveis.

## Escopo

1. confirmar contrato/campos da fonte oficial atual e disponibilidade estruturada (CSV quando acessível);
2. congelar os campos mínimos de provenance necessários: fonte, ciclo/data, identificadores/nome bruto e métricas observadas;
3. extrair uma amostra reproduzível de registros PBEV;
4. comparar contra Brand/Model/VehicleVersion/Vehicle atuais do BPT2 quando houver corpus canônico real versionado;
5. medir exact match, normalized match, unmatched e ambiguous sem confundir fixture sintético com coverage real;
6. identificar classes reais de divergência textual;
7. testar se alguma regra adicional é determinística e generalizável, sem fuzzy opaco;
8. decidir o target correto de persistência/reconciliação (`VehicleVersion`, `Vehicle`, observation independente ou combinação);
9. definir critérios para eventual ingestão futura e para desbloquear o primeiro enrichment do Comparador.

## Não escopo

- implementar Comparador;
- importar toda a tabela PBEV em produção;
- criar fuzzy/LLM matching em produção;
- assumir que ciclo PBEV = `ModelYear`;
- preencher potência, torque, dimensões ou equipamentos com fontes não provadas neste plano;
- alterar a identidade canônica de `Vehicle` sem evidência;
- automação de revisão humana;
- ranking/recommendation.

## Contrato observado da fonte oficial

No artefato PBEV 2026 inspecionado em 25/08/2026, as linhas observadas contêm, entre outros:

- categoria;
- marca;
- modelo;
- versão;
- motor;
- tipo de propulsão;
- transmissão;
- direção assistida;
- combustível;
- emissões/poluentes;
- consumo urbano/rodoviário por combustível;
- equivalência elétrica/autonomia quando aplicável;
- consumo energético;
- classificações PBE e selo de eficiência.

Não foi observado campo `ModelYear` na chave/linha. O cabeçalho `Tabela Ano 2026` e a data de atualização descrevem o ciclo/publicação, não um ano-modelo individual.

### Provenance mínima exigida pelo experimento

Qualquer observação candidata a ingestão futura deve carregar pelo menos:

- authority/source = Inmetro/PBEV;
- ciclo/tabela declarada;
- data/revisão declarada no artefato;
- URL ou identificador do artefato efetivamente lido;
- data de retrieval;
- valores brutos de `Marca`, `Modelo`, `Versão`;
- métricas brutas usadas no enrichment;
- status/resultado da reconciliação e alvo, quando houver.

Apenas `PBEV 2026` não é provenance suficiente: a página oficial indicava atualização em 19/08/2026, o PDF inspecionado declarava `ATUALIZAÇÃO 14-Aug-26` e 965 modelos/versões, enquanto notícia oficial de 14/08/2026 registrava 959. Essa divergência deve ser preservada como evidência de revisão/versionamento, não harmonizada por suposição.

O Inmetro informa que há CSV no dados.gov.br. A página do dataset foi localizada, porém o navegador deste checkpoint recebeu apenas a aplicação dependente de JavaScript e não recuperou diretamente o recurso CSV. Isso fica como problema de aquisição do recurso, não como licença para usar scraping heurístico ou declarar o CSV inspecionado.

## Baseline BPT2 observado

O módulo Catalog contém domínio, DbContext, leitura e criação administrativa, mas não contém seed/import/data file automotivo real versionado. O serviço administrativo cria Brand/Model/Generation/Version/Vehicle sob demanda e é idempotente pelas identidades atuais.

Os gates do repositório usam catálogo sintético para provar comportamento. O smoke canônico cria explicitamente `Bom Pra Ti Motors / MVP One / G1 / 1.0 Turbo / ModelYear 2026`; portanto esses registros são fixtures de teste, não um corpus automotivo representativo.

O módulo Ingestion também não contém dataset externo embutido. Seu contrato atual persiste candidatos arbitrários e só reconcilia para `ReconciledVehicleId`, validando o alvo por `IVehicleCatalogReader`. Não há hoje target de reconciliation para `VehicleVersion` nem corpus canônico versionado que permita medir coverage PBEV real.

Consequência metodológica:

- CP2 pode congelar o **algoritmo/boundaries** atuais;
- CP3 pode provar a mecânica de classificação com fixture explícito e amostra oficial reproduzível;
- CP3 **não pode** declarar taxa de coverage contra “o catálogo BPT2 real” enquanto esse corpus não existir/versionar;
- qualquer percentual calculado apenas contra fixtures sintéticos será rotulado como teste mecânico, nunca como evidência de coverage de produto.

### Baseline de matching congelado

1. target primário experimental: chave de `VehicleVersion` por `Brand.NormalizedName + Model.NormalizedName + VehicleVersion.NormalizedName`, respeitando `ModelId`/`GenerationId?` e exigindo unicidade;
2. normalização baseline = comportamento BPT2 atual: trim + uppercase, sem remoção de acento, pontuação, tokens, potência/equipamento ou aliases;
3. zero match => `unmatched`;
4. mais de um target possível => `ambiguous`;
5. exatamente um target pela chave baseline => `exact/normalized-current`;
6. nenhuma promoção automática a `Vehicle` quando existirem múltiplos `ModelYear` ou quando a fonte não declarar ano-modelo.

## Critérios de aceite

1. fonte oficial atual e campos usados estão registrados com data/status;
2. amostra e procedimento de reconciliação são reproduzíveis;
3. resultados distinguem `exact`, `normalized`, `ambiguous` e `unmatched`;
4. nenhuma ambiguidade é silenciosamente convertida em match;
5. nenhuma linha recebe `ModelYear` não declarado pela fonte;
6. exemplos reais de divergência textual são registrados;
7. target de domínio/persistência é decidido por evidência;
8. se reconciliation não atingir segurança suficiente, o plano termina com bloqueio explícito e alternativa, não com matching heurístico promovido por conveniência;
9. Comparador permanece bloqueado até existir enrichment mínimo com provenance e cobertura suficientes.

## Estratégia de teste

- usar fonte oficial Inmetro/dados.gov.br como autoridade PBEV;
- preferir CSV/estrutura oficial quando disponível; PDF serve para conferir semântica/colunas;
- usar dataset fixo/amostra versionada para tornar taxas reproduzíveis;
- baseline 1: igualdade canônica atual (`trim + uppercase`);
- baseline 2: somente normalizações determinísticas justificadas por casos observados;
- reportar contagens e exemplos por classe, não apenas percentual agregado;
- distinguir explicitamente teste mecânico em fixture de teste de coverage em corpus real;
- não usar fuzzy score sem threshold previamente justificado e casos adversariais;
- não escrever em tabelas de produção durante o experimento.

## Checkpoints

- [x] CP1 — fonte oficial e schema observado congelados; aquisição direta do CSV permanece pendente e explicitamente separada;
- [x] CP2 — catálogo BPT2 e algoritmo baseline congelados; ausência de corpus automotivo real versionado registrada como limitação de coverage;
- [ ] CP3 — amostra reproduzível reconciliada e classes de falha medidas em teste mecânico; coverage real permanece condicionado a corpus canônico real;
- [ ] CP4 — regras determinísticas adicionais testadas, se necessárias;
- [ ] CP5 — target de domínio/provenance decidido;
- [ ] CP6 — decisão final: desbloqueia enrichment mínimo, exige revisão humana/dataset adicional, ou bloqueia.

## Decision log

- não fazer match textual direto para `Vehicle` apenas porque a fonte tem Marca/Modelo/Versão;
- `VehicleVersion` é a hipótese inicial de target, não decisão final;
- ano/ciclo PBEV não será tratado como `ModelYear` sem campo/evidência explícita;
- fonte externa será preservada com provenance e temporalidade;
- revision/artifact identity faz parte da provenance porque fontes oficiais do mesmo ciclo podem divergir em contagem/revisão;
- fixtures sintéticos do repositório não serão tratados como corpus real para métricas de coverage;
- o contrato Ingestion atual `ReconciledVehicleId` é uma limitação observada, não um motivo para forçar PBEV a `Vehicle`;
- unmatched/ambiguous são resultados válidos do experimento, não erros a esconder;
- Comparador continua fora de escopo.

## Progress log

- 2026-08-25 — PR #67 integrado; `main` verificado em `1471de8f69d0216f09d6c42c57a2ccbba900b2d7`.
- 2026-08-25 — fonte oficial Inmetro verificada: página PBE Veicular informa ciclo 2026 atualizado em 19/08/2026; notícia de 14/08/2026 reporta 43 marcas e 959 modelos/versões; FAQ do Inmetro informa disponibilidade de CSV no dados.gov.br.
- 2026-08-25 — contrato BPT2 verificado: `Vehicle` possui `ModelYear?`; `VehicleVersion` não possui ano e representa versão por modelo/geração.
- 2026-08-25 — artefato oficial PBEV inspecionado visualmente: cabeçalho declara `Tabela Ano 2026`, `ATUALIZAÇÃO 14-Aug-26`, 43 marcas e 965 modelos/versões; schema de identidade começa por categoria/marca/modelo/versão e não expõe `ModelYear`.
- 2026-08-25 — divergência 959 vs 965 registrada como evidência de que provenance precisa identificar revisão/artefato, não apenas ciclo.
- 2026-08-25 — página oficial do dataset no dados.gov.br localizada; recurso CSV direto ainda não recuperado no navegador devido à camada JavaScript do portal.
- 2026-08-25 — árvore Catalog inspecionada: sem seed/import/data file real; criação canônica é administrativa e sob demanda.
- 2026-08-25 — smoke administrativo confirmado como sintético (`Bom Pra Ti Motors / MVP One / 1.0 Turbo`).
- 2026-08-25 — Ingestion inspecionado: sem corpus embutido e reconciliation existente somente para `VehicleId`.
- 2026-08-25 — CP2 fechado com separação explícita entre teste mecânico e coverage real.

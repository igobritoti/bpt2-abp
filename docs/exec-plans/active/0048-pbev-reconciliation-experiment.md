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
4. comparar contra Brand/Model/VehicleVersion/Vehicle atuais do BPT2;
5. medir exact match, normalized match, unmatched e ambiguous;
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
- não usar fuzzy score sem threshold previamente justificado e casos adversariais;
- não escrever em tabelas de produção durante o experimento.

## Checkpoints

- [ ] CP1 — fonte oficial estruturada e schema observado congelados;
- [ ] CP2 — catálogo BPT2 e algoritmo baseline congelados;
- [ ] CP3 — amostra reproduzível reconciliada e classes de falha medidas;
- [ ] CP4 — regras determinísticas adicionais testadas, se necessárias;
- [ ] CP5 — target de domínio/provenance decidido;
- [ ] CP6 — decisão final: desbloqueia enrichment mínimo, exige revisão humana/dataset adicional, ou bloqueia.

## Decision log

- não fazer match textual direto para `Vehicle` apenas porque a fonte tem Marca/Modelo/Versão;
- `VehicleVersion` é a hipótese inicial de target, não decisão final;
- ano/ciclo PBEV não será tratado como `ModelYear` sem campo/evidência explícita;
- fonte externa será preservada com provenance e temporalidade;
- unmatched/ambiguous são resultados válidos do experimento, não erros a esconder;
- Comparador continua fora de escopo.

## Progress log

- 2026-08-25 — PR #67 integrado; `main` verificado em `1471de8f69d0216f09d6c42c57a2ccbba900b2d7`.
- 2026-08-25 — fonte oficial Inmetro verificada: página PBE Veicular informa ciclo 2026 atualizado em 19/08/2026; notícia de 14/08/2026 reporta 43 marcas e 959 modelos/versões; FAQ do Inmetro informa disponibilidade de CSV no dados.gov.br.
- 2026-08-25 — contrato BPT2 verificado: `Vehicle` possui `ModelYear?`; `VehicleVersion` não possui ano e representa versão por modelo/geração.

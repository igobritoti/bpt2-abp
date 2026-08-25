# Plan 0048 — PBEV reconciliation and Podium 7 catalog boundary

Status: **ATIVO**

## Objetivo

Provar ou refutar uma integração segura entre o Podium 7 e o catálogo do BPT2, preservando a regra de produto de que o Bom Pra Ti é o dono do catálogo publicado, sem duplicar no BPT2 a aquisição/reconciliação/evidence pipeline que já existe no Podium 7 e sem autorizar ainda a implementação do Comparador.

## Base congelada

- partir do `main` após merge do PR #67 em `1471de8f69d0216f09d6c42c57a2ccbba900b2d7`;
- Plan 0047 concluído e arquivado;
- matriz do Plan 0046 define reconciliation/enrichment PBEV como boundary antes do Comparador;
- `Vehicle` BPT2 referencia `BrandId`, `ModelId`, `GenerationId?`, `VersionId` e `ModelYear?`;
- `VehicleVersion` referencia `ModelId`, `GenerationId?`, `Name` e `NormalizedName`;
- Podium 7 (`tihotm/podium7`) é um sistema Python separado de aquisição, integração, reconciliação, revisão e exportação de conhecimento automotivo;
- Podium 7 já possui Catalog Identity V2, persistence/redirects, consumer reads, batch ingestion, review durável e benchmarks de identidade;
- Podium 7 já possui contrato JSON congelado `2.0` e documento de consumer contract para Bom Pratiche/Bom Pra Ti;
- a regra declarada pelo owner em 25/08/2026 é: Bom Pra Ti é o dono do catálogo publicado; Podium 7 será o aplicativo que o alimenta.

## Problema

O problema original de reconciliar PBEV diretamente dentro do BPT2 mudou após a descoberta do papel real do Podium 7. O Podium já implementa exatamente as responsabilidades de aquisição, evidence/provenance, normalização, entity resolution, conflitos, revisão e exportação que o Plan 0048 estava prestes a reexperimentar no BPT2.

Reimplementar isso no BPT2 criaria dois motores concorrentes de identidade e duas noções de catálogo canônico. Por outro lado, simplesmente apontar ambos para o mesmo banco ou fundir os runtimes também criaria acoplamento entre Python/SQLite e .NET/PostgreSQL sem evidência de necessidade.

A decisão agora precisa separar quatro conceitos:

1. **product ownership** — Bom Pra Ti decide o catálogo que publica e consome;
2. **knowledge acquisition/resolution** — Podium 7 coleta evidência, resolve identidade, preserva conflitos e produz conhecimento candidato/canônico do seu bounded context;
3. **published catalog persistence** — BPT2 persiste a representação usada pelo marketplace;
4. **integration contract** — transformação/versionamento entre a identidade Podium e a identidade BPT2.

## Hipóteses falsificáveis

1. Podium 7 e BPT2 são bounded contexts diferentes: knowledge acquisition/resolution vs marketplace/published catalog.
2. Manter os repositórios separados e integrar inicialmente por export/import versionado oferece menor acoplamento total que unificar runtimes ou compartilhar banco.
3. A integração pode ser assíncrona/batch; nenhuma evidência atual exige Podium 7 no request path do marketplace.
4. O contrato Podium `2.0` é rico o bastante para um adapter BPT2 sem acessar SQLite interno nem reimplementar resolver.
5. O modelo BPT2 atual não é isomórfico ao Podium: uma entidade Podium possui variant/powertrain/transmission/body style/market e intervalos separados de fabricação/model year, enquanto BPT2 hoje usa Brand/Model/Generation/Version + um `ModelYear?` por Vehicle.
6. Portanto, `Podium entity.id -> BPT2 VehicleId` não deve ser assumido como relação 1:1 sem teste de cardinalidade e semântica.
7. Compartilhar schema/database entre os projetos deve ser reprovado se exigir deploy coordenado ou conhecimento do schema interno de um projeto pelo outro.
8. Um HTTP/microservice wrapper só deve ser criado se testes mostrarem necessidade de sincronização online, frequência/latência incompatível com batch, ou operação independente que justifique o custo distribuído.

## Opções arquiteturais sob teste

### A — projetos/repositórios separados + contrato export/import

Podium 7 mantém sua pipeline e exporta contrato versionado. BPT2 possui adapter/importer e persiste sua projeção publicada.

Testar:
- contract compatibility;
- idempotência;
- redirects/merge;
- criação/correção;
- cardinalidade Podium identity ↔ BPT2 identity;
- replay completo;
- comportamento quando Podium está indisponível;
- custo de atualização e rollback.

### B — monorepo, bounded contexts/runtimes separados

Mover código para um mesmo repositório sem fundir modelos ou processos.

Só passa se houver benefício mensurável de coordenação/build/test que supere perda de independência e aumento de CI/toolchain. Localidade de arquivos por si só não é benefício arquitetural.

### C — unificação de runtime/modelo

Portar/incorporar Podium no BPT2 ou substituir um dos modelos por um único runtime.

Só passa se evidência demonstrar que os contextos precisam de consistência transacional ou mudança coordenada tão frequente que a fronteira separada é artificial. Custo de reescrita e perda de benchmarks/provenance existentes contam contra.

### D — serviço distribuído síncrono (HTTP/RPC)

Manter separado e colocar Podium no request path.

Só passa se houver consumidor online concreto/latência requerida. Não adotar apenas porque os projetos são separados.

## Evidência Podium 7 já observada

- README: sistema evidence-driven de aquisição, integração, reconciliação, revisão e exportação automotiva em Python;
- Catalog Identity V2: make/model/aliases/generation/variant/powertrain/transmission/body style/market, manufacturing-year e model-year separados, engine/external IDs, resolução conservadora, `REVIEW`, IDs estáveis e redirects;
- Catalog JSON Contract `2.0`: wire shape congelado e explicitamente versionado;
- Consumer API V2: adapter transport-neutral, sem dependência HTTP;
- Bom Pratiche consumer contract V2: já prevê consumo in-process ou thin HTTP/RPC wrapper apenas se houver cross-process need;
- tests: acceptance, persistence, batch ingestion, consumer API, evidence policy e benchmarks de identidade, incluindo slice BR;
- Current State 25/08/2026: private technical MVP completo; aquisição/resolution/persistence/consumer path funcional.

## Evidência externa de arquitetura

- bounded context é fronteira de modelo e não exige por si só processo/microserviço separado;
- serviços separados devem evitar chamadas tagarelas, deploy coordenado e shared schema;
- microservices trazem deploy/escala independentes, mas adicionam complexidade distribuída;
- data ownership precisa ser explícito; compartilhar schema entre serviços cria acoplamento de evolução.

Esses princípios não determinam sozinhos a opção; servem como critérios, e a escolha final depende dos testes locais.

## Escopo

1. congelar o contrato Podium 7 relevante ao Bom Pra Ti;
2. comparar identidade Podium V2 vs Catalog BPT2 atual;
3. definir authority matrix para acquisition, resolution, publication e IDs;
4. criar contract fixture reproduzível Podium `2.0` → adapter BPT2;
5. testar cardinalidade 1:1, 1:N e redirects;
6. testar idempotência e replay de snapshot;
7. testar operação BPT2 sem Podium online;
8. comparar objetivamente A/B/C/D;
9. escolher a menor integração suficiente;
10. só depois retomar enrichment/comparador sobre o catálogo alimentado.

## Não escopo

- implementar Comparador;
- duplicar resolver PBEV no BPT2;
- importar toda a tabela PBEV em produção;
- criar fuzzy/LLM matching no BPT2;
- compartilhar banco SQLite/PostgreSQL entre projetos;
- criar microserviço/queue apenas por antecipação;
- reescrever Podium em .NET ou BPT2 em Python sem teste que exija isso;
- alterar a identidade canônica de `Vehicle` antes da comparação semântica;
- ranking/recommendation.

## Critérios de aceite

1. authority matrix explícita e sem dois writers para a mesma decisão de publicação;
2. contrato Podium consumido sem acessar persistence interna;
3. transformação demonstra como lidar com fields extras, nulls, years e external IDs;
4. redirects e replay não geram duplicata silenciosa;
5. cardinalidade Podium↔BPT2 é medida em fixtures adversariais;
6. BPT2 continua operando para leitura pública quando Podium está offline;
7. nenhuma opção é promovida apenas por preferência de linguagem/repo;
8. opção escolhida tem menor custo/risco para os requisitos observados;
9. se cross-process online não for necessário, HTTP/microservice fica adiado;
10. Comparador continua bloqueado até existir catálogo/enrichment publicado suficiente.

## Estratégia de teste

### Contract test mínimo

Fixture Podium `contractVersion=2.0` contendo:
- identidade simples;
- manufacturing/model-year ranges distintos;
- aliases/external IDs;
- historical redirect;
- entidade com campos não representáveis diretamente no modelo BPT2 atual.

O adapter deve falhar explicitamente quando a transformação for ambígua; não pode descartar silenciosamente semântica de identidade.

### Replay/idempotência

Aplicar o mesmo snapshot duas vezes e exigir estado publicado idêntntico, sem duplicatas.

### Correction/redirect

Aplicar correção mantendo Podium ID e depois merge com `redirectsFrom`; provar comportamento BPT2 determinístico.

### Availability coupling

Desligar/ausentar Podium durante reads normais do marketplace. Se o BPT2 precisar dele online para servir catálogo já publicado, opção A falha o objetivo de desacoplamento.

### Change/deploy coupling

Simular evolução compatível do Podium mantendo `2.0`; BPT2 não deve exigir deploy. Mudança incompatível deve exigir novo contract version, não quebra silenciosa.

## Matriz provisória

| opção | acoplamento de código | acoplamento operacional | reaproveita Podium | preserva BPT2 publicado | complexidade inicial | status |
|---|---|---|---|---|---|---|
| A separado + export/import | baixo | baixo | alto | sim | baixa-média | **FAVORITA PARA TESTE** |
| B monorepo, runtimes separados | médio | baixo-médio | alto | sim | média | validar só se houver ganho de coordenação |
| C unificação runtime/modelo | alto | alto | baixo/médio | exige redesenho | alta | não justificada hoje |
| D separado + HTTP síncrono | baixo código | alto runtime | alto | sim | média-alta | sem necessidade observada |

A tabela é conclusão provisória C baseada na evidência atual; só CP final pode promovê-la a decisão.

## Checkpoints

- [x] CP1 — fonte PBEV/schema observado congelados;
- [x] CP2 — catálogo BPT2 atual e ausência de corpus real versionado registrados;
- [x] CP2b — papel do Podium 7 e seus contratos atuais auditados;
- [ ] CP3 — authority matrix e contract fixture Podium→BPT2 congelados;
- [ ] CP4 — adapter/replay/redirect/cardinality test executados;
- [ ] CP5 — opções A/B/C/D comparadas com resultados locais;
- [ ] CP6 — decisão final e próximo slice escolhido.

## Decision log

- Bom Pra Ti é o owner do catálogo publicado; Podium 7 é o alimentador/knowledge integration producer;
- o experimento PBEV direto no BPT2 foi superseded pela descoberta de que Podium já implementa essa responsabilidade;
- não copiar resolver/evidence pipeline do Podium para BPT2;
- não fazer match textual direto para `Vehicle` apenas porque uma fonte tem Marca/Modelo/Versão;
- `VehicleVersion` deixou de ser hipótese isolada de target: primeiro deve ser comparado ao modelo Podium V2 completo;
- ano/ciclo PBEV não será tratado como `ModelYear` sem evidência explícita;
- manter projetos separados + integração por contrato é a hipótese líder, não decisão final;
- mesmo repositório e mesmo runtime são decisões diferentes e serão avaliadas separadamente;
- nenhum shared database;
- nenhum HTTP/microservice até existir requisito online concreto;
- unmatched/ambiguous continuam resultados válidos;
- Comparador permanece fora de escopo.

## Progress log

- 2026-08-25 — PR #67 integrado; `main` BPT2 verificado em `1471de8f69d0216f09d6c42c57a2ccbba900b2d7`.
- 2026-08-25 — fonte oficial PBEV e ausência de `ModelYear` na linha registradas.
- 2026-08-25 — BPT2 Catalog verificado: `Vehicle` usa `ModelYear?`; `VehicleVersion` não possui ano.
- 2026-08-25 — repositório BPT2 não contém corpus automotivo real versionado; gates usam fixtures sintéticos.
- 2026-08-25 — owner informou que Podium 7 (`tihotm/podium7`) será o aplicativo responsável por alimentar o catálogo do Bom Pra Ti.
- 2026-08-25 — Podium 7 auditado: private MVP funcional, Python, Catalog Identity V2, evidence/provenance, conservative resolution, redirects, batch ingestion, consumer API e benchmarks.
- 2026-08-25 — localizado `BOM-PRATICHE-CONTRACT-V2.md`, contrato explícito já preparado para consumo pelo produto e com escolha de transport ainda deliberadamente aberta.
- 2026-08-25 — pesquisa arquitetural atual confirmou que bounded context não implica microserviço e que deploy/shared-schema/chatty coupling são critérios materiais para separar ou agrupar serviços.

# Execution Plan 0014 — Ingestion Candidate Reconciliation

Status: **ATIVO**

## Objetivo

Fechar o primeiro loop operacional real do módulo Ingestion reutilizando o modelo e o boundary já existentes:

`candidate externo → registro persistido → fila pendente → operador admin reconcilia com Vehicle canônico`

O slice deve provar que uma identidade externa pode ser registrada de forma auditável e vinculada somente a um `Vehicle` que exista no Catalog, sem transformar Ingestion em fonte de verdade do catálogo.

## Contexto congelado

- `PRODUCT.md` define ingestão de fontes externas como capacidade central e o Catalog como autoridade canônica.
- `IngestionRecord` já persiste `Source`, `ExternalId`, `RawIdentity`, `Confidence`, `Provenance` e `ReconciledVehicleId`.
- `IngestionDbContext` já possui índice único em `(Source, ExternalId)` e índice em `ReconciledVehicleId`.
- `IngestionCandidateDto` já existe em Contracts.
- Ingestion já referencia somente `BomPraTi.Catalog.Contracts` e o `IVehicleCatalogReader` já permite validar um `vehicleId` canônico.
- A role `admin` já é usada no produto para operações internas de moderação.
- Não há necessidade demonstrada de connector externo, background job, broker, cache, nova UI ou migration para este loop.

## Escopo

- expor application service de Ingestion restrito a `admin`;
- registrar candidate usando a identidade externa existente `(Source, ExternalId)`;
- listar registros ainda não reconciliados;
- reconciliar um registro pendente com `Vehicle` existente no Catalog através de `Catalog.Contracts`;
- provar por HTTP real autenticação/autorização, persistência, deduplicação da identidade externa, rejeição de Vehicle inexistente e saída da fila após reconciliação;
- integrar a prova ao gate backend aplicável existente, sem criar suite paralela desnecessária.

## Fora de escopo

- connector para fonte externa real;
- scraping, polling, scheduler ou background job;
- aprovação automática por score/confidence;
- fuzzy matching ou algoritmo de reconciliação;
- criação/alteração automática do catálogo canônico;
- UI/painel de ingestão;
- edição de candidate, undo/reopen de reconciliação ou workflow multiestado;
- nova migration ou mudança de schema;
- promoções, Vehicle Hub ou extensões de SEO/moderação não necessárias a este loop.

## Critérios de aceite

1. [ ] Superfície HTTP de Ingestion existe via conventional controllers do ABP.
2. [ ] Anônimo recebe 401 e usuário autenticado sem role `admin` recebe 403.
3. [ ] Admin registra candidate e o registro persistido preserva Source/ExternalId/RawIdentity/Confidence/Provenance.
4. [ ] Repetir o mesmo `(Source, ExternalId)` não cria um segundo registro.
5. [ ] Registro novo aparece na fila pendente.
6. [ ] Reconciliation para `vehicleId` inexistente é rejeitada e não altera o registro.
7. [ ] Reconciliation para Vehicle canônico existente persiste `ReconciledVehicleId`.
8. [ ] Registro reconciliado deixa de aparecer na fila pendente.
9. [ ] Build, boundary guard, fresh database, prova HTTP focal e harness aplicáveis passam no head final.
10. [ ] Docs canônicos refletem a capacidade realmente comprovada, sem elevar connector/job/UI a requisito.

## Checkpoints

- [x] Revalidar `main` remoto e fontes canônicas.
- [x] Selecionar o menor gap real por evidência.
- [x] Confirmar que o modelo/schema e o boundary Ingestion → Catalog.Contracts já existem.
- [ ] Abrir draft PR.
- [ ] Implementar contrato/application service mínimo.
- [ ] Adicionar prova HTTP focal ao gate backend existente.
- [ ] Corrigir somente falhas observadas.
- [ ] Executar self-review e fechar documentação.
- [ ] Exigir CI fresco no head documental final.
- [ ] Refazer review/base refresh e merge somente verde.
- [ ] Verificar `main` pós-merge e ausência de plano ativo.

## Decisões abertas necessárias

Nenhuma decisão arquitetural nova é necessária neste momento. A política de ingestão automática, algoritmo de matching, fontes concretas e background processing permanecem abertas até existir caso real.

## Progress log

- 2026-08-24: `main` remoto confirmado em `e43dd45f6e1c9b828815ca0586647b70a7260713`; Plan 0013 encerrado e sem blocker conhecido.
- 2026-08-24: auditoria do código encontrou Ingestion já parcialmente modelado: aggregate persistente, candidate DTO, identidade externa única e referência opcional ao Vehicle canônico, mas nenhuma superfície operacional.
- 2026-08-24: escolhido o loop de reconciliation como menor gap central fechável sem infraestrutura nova.

## Decision log

- **DECIDIDO para este slice:** operações de ingestão são internas e usam a role `admin` já existente; não será criada identidade/role nova sem evidência.
- **DECIDIDO para este slice:** o Catalog continua autoridade canônica; Ingestion só pode reconciliar para `Vehicle` validado por `IVehicleCatalogReader`.
- **DECIDIDO para este slice:** `(Source, ExternalId)` continua sendo a identidade externa deduplicada já expressa pelo índice único existente.
- **NÃO DECIDIDO:** connector/source concreto, matching automático, threshold de confidence, workflow de aprovação, jobs e UI.

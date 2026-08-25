# Execution Plan 0028 — Admin Canonical Catalog

Status: **ATIVO**

## Objetivo

Fechar o blocker `MVP-01` permitindo que um operador `admin` crie a identidade automotiva canônica mínima exigida por Listing em um banco fresco, sem fixture de teste, connector externo, importador ou schema novo.

Outcome vertical:

`admin → Brand/Model/Generation/Version/Vehicle canônicos → catálogo público → Seller Draft`

## Contexto congelado

- Base: `main` em `2d95d0fb84a5dd641af0649104336727085f955f`, merge do Plan 0027.
- `VehicleCatalogAppService` é `[AllowAnonymous]` e somente leitura; escrita não será adicionada nessa classe.
- `CatalogDbContext` já possui `Brand`, `VehicleModel`, `Generation`, `VehicleVersion` e `Vehicle` com índices naturais para Brand/Model/Version/Vehicle.
- Os gates atuais criam essa árvore por `tests/BomPraTi.HttpLifecycleFixture` e exportam `BPT_FIXTURE_VEHICLE_ID` antes de provar Seller/Buyer.
- O host já usa Razor Pages protegidas por `[Authorize(Roles = "admin")]` para `/admin`, `/moderacao` e `/ingestao`.

## Escopo

- contrato separado `ICanonicalVehicleAdminAppService`;
- DTO de entrada com nomes canônicos e anos mínimos necessários;
- serviço admin-only que reutiliza nós existentes por chaves naturais e cria somente os ausentes;
- criação/reuso do `Vehicle` final e retorno de `VehicleRefDto`;
- página Razor administrativa para operação manual;
- entrada no hub `/admin`;
- smoke HTTP em PostgreSQL fresco que prova autorização, criação, idempotência, leitura pública e criação de Draft sem `HttpLifecycleFixture`;
- workflow focal para o smoke novo;
- documentação de estado ao concluir.

## Não escopo

- fonte externa de catálogo;
- importação em lote/CSV;
- edição/remoção de identidade canônica;
- matching automático de ingestion;
- specs/equipamentos/preço de mercado/editorial;
- nova migration ou alteração de schema;
- frontend Next.js para administração;
- permissões granulares além do role `admin` já usado pelo host.

## Critérios de aceite

1. [ ] usuário anônimo/não-admin não consegue executar a criação canônica;
2. [ ] admin consegue criar `Brand → Model → Generation opcional → Version → Vehicle` em banco fresco sem fixture de catálogo;
3. [ ] repetir a mesma entrada reutiliza a mesma identidade e retorna o mesmo `VehicleId`;
4. [ ] o `VehicleId` criado aparece em `GET /api/app/vehicle-catalog`;
5. [ ] um Seller autenticado consegue criar Draft usando o `VehicleId` retornado, sem executar `tests/BomPraTi.HttpLifecycleFixture`;
6. [ ] `/catalogo` oferece formulário operacional protegido e `/admin` aponta para ele;
7. [ ] nenhum schema/migration ou dependência externa é introduzido;
8. [ ] checks focais e regressões aplicáveis ficam verdes no head integrado.

## Checkpoints

1. [x] evidência e boundary de autorização definidos;
2. [ ] contrato + serviço Catalog;
3. [ ] Razor Page + hub admin;
4. [ ] smoke/workflow em banco fresco sem fixture de catálogo;
5. [ ] documentação final, CI fresco, review e merge.

## Decisões abertas necessárias

Nenhuma decisão arquitetural nova. A implementação deve usar as chaves naturais já expressas no modelo:

- Brand: `NormalizedName`;
- Model: `BrandId + NormalizedName`;
- Generation: `ModelId + Name + StartYear + EndYear` no boundary operacional;
- Version: `ModelId + GenerationId + NormalizedName`;
- Vehicle: `BrandId + ModelId + GenerationId + VersionId + ModelYear`.

Se a implementação revelar incompatibilidade real entre essas chaves e o schema, parar somente esse checkpoint e registrar a evidência antes de ampliar escopo.

## Progress log

- 2026-08-24: Plan 0027 mergeado; `MVP-01` selecionado como primeiro blocker independente.
- 2026-08-24: `main` remoto refetchado em `2d95d0fb84a5dd641af0649104336727085f955f`.
- 2026-08-24: confirmado que escrita não deve entrar no `VehicleCatalogAppService` porque a classe é `[AllowAnonymous]`.
- 2026-08-24: confirmado padrão existente de Razor Page e service admin-only via role `admin`.

## Decision log

- **DECIDIDO:** escrita canônica fica em application service separado e admin-only.
- **DECIDIDO:** operação manual é idempotente por chaves naturais e cria/reutiliza a árvore em uma unidade de trabalho.
- **DECIDIDO:** o primeiro gate funcional deve provar Seller Draft sem `HttpLifecycleFixture`.
- **DECIDIDO:** Generation permanece opcional porque o domínio e `Vehicle` já permitem `GenerationId = null`.
- **NÃO DECIDIDO:** fonte externa/inicial em lote do catálogo; continua pós-MVP enquanto operação manual mínima for suficiente.

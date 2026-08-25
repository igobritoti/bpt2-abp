# Execution Plan 0028 — Admin Canonical Catalog

Status: **CONCLUÍDO**

## Objetivo

Fechar o blocker `MVP-01` permitindo que um operador `admin` crie a identidade automotiva canônica mínima exigida por Listing em um banco fresco, sem fixture de teste, connector externo, importador ou schema novo.

Outcome vertical comprovado:

`admin → Brand/Model/Generation opcional/Version/Vehicle canônicos → catálogo público → Seller Draft`

## Contexto congelado

- Base inicial: `main` em `2d95d0fb84a5dd641af0649104336727085f955f`, merge do Plan 0027.
- `VehicleCatalogAppService` permanece `[AllowAnonymous]` e somente leitura; escrita foi mantida em boundary separada.
- `CatalogDbContext` já possuía os aggregates e chaves necessárias; nenhuma migration/schema novo foi necessário.
- Antes deste slice, os gates Seller/Buyer dependiam de `tests/BomPraTi.HttpLifecycleFixture` para inserir um `Vehicle` canônico em banco fresco.

## Implementação concluída

- `CreateCanonicalVehicleInput` e `ICanonicalVehicleAdminAppService` adicionados ao contrato Catalog.
- `CanonicalVehicleAdminAppService` protegido por `[Authorize(Roles = "admin")]`.
- criação/reuso idempotente de `Brand → Model → Generation opcional → Version → Vehicle` usando as chaves naturais existentes.
- `/catalogo` adicionado como Razor Page administrativa para criação manual.
- `/admin` passou a apontar para a nova superfície.
- `scripts/admin-canonical-catalog-http-smoke.sh` prova o fluxo em PostgreSQL fresco sem `HttpLifecycleFixture`.
- `.github/workflows/admin-canonical-catalog-http-gate.yml` executa a prova focal no PR.

## Critérios de aceite

1. [x] usuário anônimo/não-admin não consegue executar a criação canônica;
2. [x] admin consegue criar `Brand → Model → Generation opcional → Version → Vehicle` em banco fresco sem fixture de catálogo;
3. [x] repetir a mesma entrada reutiliza a mesma identidade e retorna o mesmo `VehicleId`;
4. [x] o `VehicleId` criado aparece em `GET /api/app/vehicle-catalog`;
5. [x] um Seller autenticado consegue criar Draft usando o `VehicleId` retornado, sem executar `tests/BomPraTi.HttpLifecycleFixture`;
6. [x] `/catalogo` oferece formulário operacional protegido e `/admin` aponta para ele;
7. [x] nenhum schema/migration ou dependência externa foi introduzido;
8. [x] gate focal, Host, Fresh Migration, Architecture e Harness ficaram verdes no head funcional antes do fechamento documental; o head final deve repetir os checks aplicáveis antes do merge.

## Checkpoints

1. [x] evidência e boundary de autorização definidos;
2. [x] contrato + serviço Catalog;
3. [x] Razor Page + hub admin;
4. [x] smoke/workflow em banco fresco sem fixture de catálogo;
5. [x] documentação final preparada para CI fresco, review e merge.

## Evidência executada

No head `f374a31a2f27dec00f0c2743a4569f8c6bbb82ad` do PR #47:

- `BPT2 Admin Canonical Catalog HTTP Gate`: **success**;
  - fresh database: success;
  - seed Identity/OpenIddict: success;
  - smoke canônico sem fixture: success;
- `BPT2 Host Gate`: **success**;
- `BPT2 Fresh Migration Gate`: **success**;
- `BPT2 Architecture Gate`: **success**;
- `BPT2 Harness Gate`: **success** após sincronizar os fatos gerados;
- regressões Seller Shell, Seller Draft/Edit e Gate 01 também concluíram com **success** antes do fechamento documental.

A fonte final de verdade continua sendo o CI do head integrado; os SHAs acima registram somente a evidência histórica deste plano.

## Decision log

- **DECIDIDO:** escrita canônica fica em application service separado e admin-only.
- **DECIDIDO:** operação manual é idempotente por chaves naturais e cria/reutiliza a árvore em uma unidade de trabalho.
- **DECIDIDO:** Generation permanece opcional porque o domínio e `Vehicle` já permitem `GenerationId = null`.
- **DECIDIDO por teste executado:** um ambiente novo não precisa mais da fixture de catálogo para fechar `admin → catálogo → Seller Draft`.
- **NÃO DECIDIDO:** fonte externa/inicial em lote do catálogo; continua pós-MVP enquanto operação manual mínima for suficiente.

## Progress log

- 2026-08-24: Plan 0027 mergeado; `MVP-01` selecionado como primeiro blocker independente.
- 2026-08-24: `main` remoto refetchado em `2d95d0fb84a5dd641af0649104336727085f955f`.
- 2026-08-24: escrita separada do `VehicleCatalogAppService` anônimo e restrita ao role `admin`.
- 2026-08-24: serviço, Razor Page, hub admin, smoke e workflow focal implementados.
- 2026-08-24: primeira execução do Harness revelou somente `repository-facts.md` desatualizado pela adição de workflow/plano; fatos derivados sincronizados.
- 2026-08-24: gate focal comprovou fresh DB, autorização, criação, idempotência, leitura pública e Seller Draft sem `HttpLifecycleFixture`.
- 2026-08-24: `MVP-01` classificado como fechado; `MVP-02` passa a ser o próximo blocker funcional.

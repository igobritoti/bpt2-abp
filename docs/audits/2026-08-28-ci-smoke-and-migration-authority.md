# CI smoke coverage and migration authority — 2026-08-28

Status: **AUDITADO**

## Perguntas

1. Existe algum `scripts/*-http-smoke.sh` na raiz que represente uma prova funcional única, mas não seja executado por workflow ativo?
2. A migration versionada `main/BomPraTi/Migrations/20260823012701_Initial.cs` compete com as migrations efêmeras geradas pelo Fresh Migration Gate ou possui autoridade distinta?
3. Restou algum workflow de migração histórica que não corresponde mais à árvore canônica atual?

## Evidência — smokes HTTP

O inventário de `scripts/` foi cruzado com os workflows root que executam os fluxos HTTP.

Cobertura observada:

- Admin canonical catalog → `admin-canonical-catalog-http-gate.yml`;
- Admin operations hub/summary/global navigation + Ingestion candidate/vehicle lookup → `product-api-gate.yml`;
- Buyer Favorites, Favorite price-drop, Saved Search, Listing report e moderation inbox → `buyer-favorites-http-gate.yml`;
- public Buyer, Seller Hub, Vehicle Hub, social images, SEO, Listing structured data, authenticated Lead e WhatsApp forwarding → `public-buyer-http-gate.yml`;
- canonical Vehicle search, discovery, price sort, recency sort, color, Saved Search color e sponsored Listing → `public-discovery-http-gate.yml`;
- moderation listing authority → `moderation-listing-authority-http-gate.yml`;
- Listing lifecycle → `listing-http-lifecycle-gate.yml`;
- Listing photo → `listing-photo-http-gate.yml`;
- Seller auth → `seller-auth-http-gate.yml`;
- Seller Draft/Edit → `seller-draft-edit-http-gate.yml`;
- Seller shell → `seller-shell-http-gate.yml`;
- Seller publish/photos e Seller Leads → `seller-publish-http-gate.yml`.

### Decisão

`ROOT_HTTP_SMOKE_ORPHANS = 0`

Não conectar scripts adicionais por ritual. Um novo smoke só precisa de novo wiring quando introduzir prova não coberta por gate ativo.

## Evidência — authority de migrations

### Host

`main/BomPraTi/Data/BomPraTiDbContext.cs` configura somente infraestrutura ABP:

- Permission Management;
- Setting Management;
- Audit Logging;
- Identity;
- OpenIddict;
- Feature Management;
- Tenant Management.

A migration versionada `main/BomPraTi/Migrations/20260823012701_Initial.cs` cria infraestrutura ABP e não contém tabelas de domínio pesquisadas como `Listings` ou `Catalog`.

### Módulos de negócio

Os módulos `catalog`, `media`, `sellers`, `marketplace` e `ingestion` possuem DbContexts próprios. Não há migration versionada de domínio sob `Data/Migrations` no estado auditado.

`scripts/fresh-migration-gate.sh`:

1. gera `Data/Migrations/Gate` efêmeras para os cinco DbContexts de negócio;
2. compila as migrations geradas;
3. executa `database update` para `BomPraTiDbContext` do host;
4. executa `database update` separadamente para cada DbContext de negócio.

Isso estabelece authorities distintas:

- `HOST_ABP_MIGRATION = VERSIONADA / MANTER`;
- `BUSINESS_MODULE_GATE_MIGRATIONS = EFÊMERAS / NÃO VERSIONAR COMO EVIDÊNCIA DO GATE`.

Não remover a `Initial` do host apenas porque os módulos geram migrations temporárias: elas têm escopos diferentes.

## Evidência — workflow histórico de importação

Após o Plan 0058 remover `bpt2/` e `bpt2-vertical-slice.yml`, permaneceu `.github/workflows/migration-import.yml`.

Esse workflow:

- só disparava na branch `migrate-bpt2-assets-20260822`;
- exigia mudança em `migration/bpt2-export.b64`;
- decodificava o antigo archive;
- tentava commitar `bpt2/` e `.github/workflows/bpt2-vertical-slice.yml`.

A branch histórica ainda existe, mas o diretório `migration/` não existe nela no audit de 2026-08-28. Portanto não há payload ativo e o workflow aponta exclusivamente para artifacts já aposentados.

### Decisão

`LEGACY_MIGRATION_IMPORT_WORKFLOW = REMOVER`

A branch histórica é preservada. Não há necessidade de apagá-la para consolidar a árvore/runtime atual.

## Resultado

- smokes HTTP órfãos: **0**;
- migration versionada do host: **MANTER**;
- migrations efêmeras dos módulos no gate: **MANTER COMO MECANISMO DE PROVA, NÃO COMO ARTEFATO VERSIONADO**;
- workflow legado `migration-import.yml`: **REMOVER**;
- alteração de produto/runtime/schema: **NÃO**.

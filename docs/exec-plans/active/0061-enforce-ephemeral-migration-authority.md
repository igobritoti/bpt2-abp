# Plan 0061 — Enforce ephemeral migration authority

Status: **ATIVO**

## Objetivo

Impedir que o output temporário `Data/Migrations/Gate` gerado pelo Fresh Migration Gate seja versionado e passe a competir com a autoridade de migrations definida no audit de 2026-08-28.

## Evidência de base

- o audit `docs/audits/2026-08-28-ci-smoke-and-migration-authority.md` decidiu que a migration do host `BomPraTiDbContext` é versionada e pertence à infraestrutura ABP/Identity/OpenIddict;
- `scripts/fresh-migration-gate.sh` gera migrations efêmeras em `Data/Migrations/Gate` para os cinco módulos de negócio antes de aplicar os respectivos DbContexts;
- a árvore canônica atual não contém nenhum arquivo versionado sob `Data/Migrations/Gate`;
- não existe `.gitignore` root que transforme essa boundary em proteção suficiente por si só;
- o Harness já atua como guard de autoridade estrutural e acabou de ganhar uma invariante equivalente para smokes HTTP.

## Boundary entregue

- adicionar ao Harness uma checagem fail-closed sobre arquivos versionados sob qualquer `Data/Migrations/Gate/`;
- basear a checagem em `git ls-files`, para não reprovar output local não versionado gerado durante desenvolvimento;
- adicionar teste focal da regra de classificação de paths;
- executar o teste focal no Harness Gate antes da validação completa.

## Não objetivos

- mudar o Fresh Migration Gate;
- versionar migrations dos módulos neste slice;
- remover ou recriar a migration `Initial` do host;
- adicionar `.gitignore` como substituto do guard de autoridade;
- alterar runtime, schema, API ou produto.

## Critérios de aceite

- [ ] nenhum arquivo atual sob `Data/Migrations/Gate/` aparece em `git ls-files`;
- [ ] helper classifica como proibido qualquer path versionado dentro de `Data/Migrations/Gate/`;
- [ ] paths normais de migration fora de `Gate/` permanecem permitidos;
- [ ] Harness falha se encontrar output efêmero versionado;
- [ ] teste focal e Harness Gate verdes no head exato;
- [ ] review/thread check e base refresh limpos antes do merge.

## Decision log

- `HOST_ABP_MIGRATION = VERSIONADA`
- `BUSINESS_MODULE_GATE_MIGRATIONS = EFÊMERAS`
- `TRACKED_DATA_MIGRATIONS_GATE = PROIBIDO`
- `UNTRACKED_LOCAL_GATE_OUTPUT = PERMITIDO`
- `PRODUCT_RUNTIME_CHANGE = NÃO`

## Progress log

- 2026-08-28 — audit de migrations reconciliou host versionado versus módulos efêmeros.
- 2026-08-28 — sweep após Plan 0060 confirmou zero output `Data/Migrations/Gate` na árvore canônica e ausência de guard automático específico.

## Validation

Mudança de harness/test/documentação apenas. Exigir teste focal e BPT2 Harness Gate no head exato; não disparar suites de produto sem path/risk correspondente.

## Rollback

Remover a checagem restaura o comportamento anterior sem tocar dados ou runtime.

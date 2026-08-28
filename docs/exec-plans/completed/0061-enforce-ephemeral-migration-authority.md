# Plan 0061 — Enforce ephemeral migration authority

Status: **CONCLUÍDO**

## Objetivo

Impedir que o output temporário `Data/Migrations/Gate` gerado pelo Fresh Migration Gate seja versionado e passe a competir com a autoridade de migrations definida no audit de 2026-08-28.

## Evidência de base

- o audit `docs/audits/2026-08-28-ci-smoke-and-migration-authority.md` decidiu que a migration do host `BomPraTiDbContext` é versionada e pertence à infraestrutura ABP/Identity/OpenIddict;
- `scripts/fresh-migration-gate.sh` gera migrations efêmeras em `Data/Migrations/Gate` para os cinco módulos de negócio antes de aplicar os respectivos DbContexts;
- a árvore canônica não continha nenhum arquivo versionado sob `Data/Migrations/Gate` antes deste slice;
- o Harness já atua como guard de autoridade estrutural.

## Boundary entregue

- `scripts/check-harness.py` consulta `git ls-files` e reprova qualquer arquivo rastreado dentro de `Data/Migrations/Gate/`;
- output local não rastreado continua permitido;
- `scripts/test-ephemeral-migration-authority.py` prova que paths `Gate/` são proibidos e a migration `Initial` versionada do host permanece permitida;
- `harness-gate.yml` executa o teste focal antes da validação completa.

## Não objetivos

- mudar o Fresh Migration Gate;
- versionar migrations dos módulos;
- remover/recriar a migration `Initial` do host;
- alterar runtime, schema, API ou produto.

## Critérios de aceite

- [x] nenhum arquivo atual sob `Data/Migrations/Gate/` aparece em `git ls-files`;
- [x] helper classifica como proibido qualquer path versionado dentro de `Data/Migrations/Gate/`;
- [x] paths normais de migration fora de `Gate/` permanecem permitidos;
- [x] Harness falha se encontrar output efêmero versionado;
- [x] teste focal e Harness Gate verdes no head funcional `08b2dcd41a49959558bd2073dad262f982fca765`;
- [ ] review/thread check e base refresh limpos antes do merge — executar no closeout do PR.

## Decision log

- `HOST_ABP_MIGRATION = VERSIONADA`
- `BUSINESS_MODULE_GATE_MIGRATIONS = EFÊMERAS`
- `TRACKED_DATA_MIGRATIONS_GATE = PROIBIDO`
- `UNTRACKED_LOCAL_GATE_OUTPUT = PERMITIDO`
- `PRODUCT_RUNTIME_CHANGE = NÃO`

## Progress log

- 2026-08-28 — audit de migrations reconciliou host versionado versus módulos efêmeros.
- 2026-08-28 — sweep após Plan 0060 confirmou zero output `Data/Migrations/Gate` na árvore canônica e ausência de guard automático específico.
- 2026-08-28 — PR #110 implementou guard via `git ls-files`, teste focal e integração ao Harness.
- 2026-08-28 — Harness #702 passou, incluindo `Prove ephemeral migration authority guard` e o checker completo.

## Validation

Mudança de harness/test/documentação apenas. O head funcional `08b2dcd41a49959558bd2073dad262f982fca765` passou no BPT2 Harness Gate #702. Exigir Harness fresco após o closeout documental e então review/base refresh antes do merge.

## Rollback

Remover a checagem restaura o comportamento anterior sem tocar dados ou runtime.

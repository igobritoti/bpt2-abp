# Plan 0058 — Remove legacy `bpt2/` subtree

Status: **CONCLUÍDO**

## Objetivo

Remover o subtree top-level `bpt2/` que preservava o bootstrap/migração histórica e aposentar o workflow de compatibilidade usado para desacoplar o CI desse subtree, deixando uma única árvore canônica executável na raiz do repositório.

## Evidência de base

- `bpt2/BOOTSTRAP_STATUS.md` declarava que o subtree continha artefatos transferidos do trabalho isolado antes mantido em `igobritoti/bomprati` e que o estado corrente pertencia ao `docs/MDV.md` da raiz;
- root `README.md` e `docs/LOCAL-DEVELOPMENT.md` usam `main/`, `modules/`, `public-web/`, `scripts/` e `.github/workflows/` da raiz como caminhos suportados;
- o primeiro attempt de remoção (#105) revelou que somente o root workflow `bpt2-vertical-slice.yml` ainda dependia diretamente de `bpt2/`;
- PR #106 removeu essa dependência e passou bootstrap root, build de `main/BomPraTi.slnx` e Fresh Migration, mergeando no commit `54d55fa91ae4f163b4616d96281a4e21eef05f38`;
- não foi encontrado outro consumidor atual do subtree histórico.

## Boundary entregue

- `bpt2/` removido por inteiro;
- `.github/workflows/bpt2-vertical-slice.yml` removido após cumprir sua função transitória;
- runtime, módulos, APIs, schema e public web canônicos preservados;
- inventário recursivo reduzido de 20 para 15 projetos `.csproj` e de 21 para 20 workflows root.

## Não objetivos

- reescrever histórico Git;
- alterar produto ou arquitetura atual;
- migrar novamente código histórico;
- remover o `gate01.yml` canônico;
- alterar migrations canônicas — audit separado.

## Critérios de aceite

- [x] `bpt2/` ausente da árvore candidata;
- [x] `bpt2-vertical-slice.yml` ausente da árvore candidata;
- [x] 15 projetos `.csproj` canônicos e 20 workflows root refletidos em `repository-facts.md`;
- [x] cinco módulos de negócio e quatro projetos de teste permanecem no inventário;
- [x] Harness Gate #684 verde no head funcional `b05d14703c2dd8f22c49d94c07995be2b92a9f86`;
- [x] PR #106 provou previamente que o workflow desacoplado executava bootstrap root, build root e Fresh Migration sem depender do subtree;
- [ ] CI fresco do head final de closeout + review/thread/base refresh antes do merge.

## Decision log

- `ROOT_CANONICAL_TREE = main/ + modules/ + public-web/ + scripts/ + .github/workflows/`
- `LEGACY_BPT2_SUBTREE = REMOVIDO`
- `LEGACY_BOOTSTRAP_COMPATIBILITY_WORKFLOW = APOSENTADO`
- `HISTORICAL_RECOVERY = GIT HISTORY`
- `PRODUCT_RUNTIME_CHANGE = NÃO`

## Progress log

- 2026-08-28 — attempt #105 encontrou o acoplamento residual do workflow root ao subtree e foi fechado sem merge.
- 2026-08-28 — PR #106 desacoplou o workflow, validou root bootstrap/build/migrations e mergeou verde.
- 2026-08-28 — Plan 0058 reaberto em base limpa `54d55fa91ae4f163b4616d96281a4e21eef05f38`.
- 2026-08-28 — subtree e workflow transitório removidos; fatos gerados ajustados para 15 projetos e 20 workflows.
- 2026-08-28 — Harness #684 passou, validando knowledge base, fatos gerados e boundary Podium na árvore sem o subtree.

## Validation

Evidência funcional/infrastrutural relevante:
- PR #106: workflow de compatibilidade verde com `scripts/bootstrap-host.sh`, build de `main/BomPraTi.slnx` e `scripts/fresh-migration-gate.sh`;
- PR #107 head funcional `b05d14703c2dd8f22c49d94c07995be2b92a9f86`: BPT2 Harness Gate #684 success.

O merge permanece condicionado ao Harness fresco do head final de closeout, reviews/threads e base refresh.

## Rollback

Todo conteúdo removido permanece recuperável pelo histórico Git anterior ao Plan 0058. Rollback é revert/restore normal.

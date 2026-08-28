# Plan 0058 — Remove legacy `bpt2/` subtree

Status: **ATIVO**

## Objetivo

Remover o subtree top-level `bpt2/` que preserva o bootstrap/migração histórica e aposentar o workflow de compatibilidade criado para desacoplar o CI desse subtree, deixando uma única árvore canônica executável na raiz do repositório.

## Evidência de base

- `bpt2/BOOTSTRAP_STATUS.md` declara que o subtree contém artefatos transferidos do trabalho isolado antes mantido em `igobritoti/bomprati` e que o estado corrente pertence ao `docs/MDV.md` da raiz;
- root `README.md` e `docs/LOCAL-DEVELOPMENT.md` usam `main/`, `modules/`, `public-web/`, `scripts/` e `.github/workflows/` da raiz como caminhos suportados;
- o primeiro attempt de remoção (#105) revelou que somente o root workflow `bpt2-vertical-slice.yml` ainda dependia diretamente de `bpt2/`;
- PR #106 removeu essa dependência e passou bootstrap root, build de `main/BomPraTi.slnx` e Fresh Migration, mergeando no commit `54d55fa91ae4f163b4616d96281a4e21eef05f38`;
- não existe outro consumidor conhecido do subtree histórico.

## Boundary entregue

- deletar `bpt2/` por inteiro;
- deletar `.github/workflows/bpt2-vertical-slice.yml`, cuja função transitória termina com a remoção do subtree;
- preservar runtime, módulos, APIs, schema e public web canônicos;
- atualizar fatos gerados e `CURRENT-WORK`.

## Não objetivos

- reescrever histórico Git;
- alterar produto ou arquitetura atual;
- migrar novamente código histórico;
- remover o `gate01.yml` canônico;
- alterar migrations canônicas — isso será auditado em bloco separado.

## Critérios de aceite

- [ ] `bpt2/` ausente da árvore candidata;
- [ ] `bpt2-vertical-slice.yml` ausente da árvore candidata;
- [ ] 15 projetos `.csproj` canônicos e 20 workflows root refletidos em `repository-facts.md`;
- [ ] cinco módulos de negócio e quatro projetos de teste permanecem no inventário;
- [ ] Harness Gate verde no head exato;
- [ ] workflow de compatibilidade disparado pela transição usa a definição já mergeada do #106 e termina verde;
- [ ] review/thread check e base refresh limpos antes do merge.

## Decision log

- `ROOT_CANONICAL_TREE = main/ + modules/ + public-web/ + scripts/ + .github/workflows/`
- `LEGACY_BPT2_SUBTREE = REMOVER`
- `LEGACY_BOOTSTRAP_COMPATIBILITY_WORKFLOW = APOSENTAR APÓS #106`
- `HISTORICAL_RECOVERY = GIT HISTORY`
- `PRODUCT_RUNTIME_CHANGE = NÃO`

## Progress log

- 2026-08-28 — attempt #105 encontrou o acoplamento residual do workflow root ao subtree e foi fechado sem merge.
- 2026-08-28 — PR #106 desacoplou o workflow, validou root bootstrap/build/migrations e mergeou verde.
- 2026-08-28 — Plan 0058 reaberto em base limpa `54d55fa91ae4f163b4616d96281a4e21eef05f38` para remoção definitiva.

## Validation

Exigir Harness no head exato. O workflow transitório do #106 pode ser disparado pelo diff de deleção; a definição mergeada deve validar a árvore root sem depender de `bpt2/`.

## Rollback

Todo conteúdo removido permanece recuperável pelo histórico Git anterior ao Plan 0058. Rollback é revert/restore normal.

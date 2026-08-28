# Plan 0058 — Remove legacy `bpt2/` subtree

Status: **ATIVO**

## Objetivo

Remover o subtree top-level `bpt2/` que preserva um snapshot histórico do bootstrap/migração inicial, depois de provar que a autoridade atual do repositório e os caminhos executáveis vivem na raiz (`main/`, `modules/`, `public-web/`, `scripts/` e `.github/workflows/`).

## Evidência de base

- o `README.md` da raiz aponta agentes para `docs/`, `ARCHITECTURE.md` e `CURRENT-WORK` da raiz;
- `docs/LOCAL-DEVELOPMENT.md` usa somente `main/`, `modules/`, `public-web/` e `scripts/` da raiz para desenvolvimento/bootstrap suportado;
- `bpt2/BOOTSTRAP_STATUS.md` declara explicitamente que aquele subtree contém artefatos transferidos do trabalho isolado antes mantido em `igobritoti/bomprati` e que o estado corrente pertence ao `docs/MDV.md` da raiz;
- a busca do repositório não encontrou consumidor atual do caminho `bpt2/` em runtime/docs/workflows canônicos;
- workflows sob `bpt2/.github/workflows` não pertencem ao inventário ativo de workflows da raiz;
- o subtree contém 5 projetos `.csproj` históricos; removê-lo reduz o inventário recursivo de 20 para 15 sem alterar os cinco módulos de negócio ou os 21 workflows ativos da raiz.

## Boundary entregue

- remover somente o subtree top-level `bpt2/`;
- preservar todo material no histórico Git para rollback/restauração;
- não alterar runtime, contratos de produto, módulos canônicos ou workflows ativos;
- atualizar apenas fatos gerados e documentação de trabalho necessários para refletir a nova árvore.

## Não objetivos

- reescrever histórico Git;
- alterar arquitetura atual;
- migrar novamente código do subtree legado;
- modificar schema, API, frontend ou comportamento de produto;
- apagar branches/commits históricos.

## Critérios de aceite

- [ ] `bpt2/` ausente da árvore candidata;
- [ ] caminhos canônicos da raiz inalterados, exceto docs/fatos necessários ao cleanup;
- [ ] `repository-facts.md` coerente com a árvore candidata;
- [ ] Harness Gate verde no head exato;
- [ ] qualquer outro workflow disparado pelo diff verde ou com blocker externo comprovado;
- [ ] review/thread check e base refresh limpos antes do merge.

## Decision log

- `ROOT_CANONICAL_TREE = main/ + modules/ + public-web/ + scripts/ + .github/workflows/`
- `LEGACY_BPT2_SUBTREE = REMOVER`
- `HISTORICAL_RECOVERY = GIT HISTORY`
- `PRODUCT_RUNTIME_CHANGE = NÃO`

## Progress log

- 2026-08-28 — `main` confirmado no commit `5eec8cab746855922fbec8ea6201b0ec0cb8dff0`.
- 2026-08-28 — audit confirmou que `bpt2/BOOTSTRAP_STATUS.md` é material de transferência histórica e que o desenvolvimento canônico atual usa somente a raiz.
- 2026-08-28 — subtree `bpt2/` removido atomicamente na branch `chore/remove-legacy-bpt2-subtree`.
- 2026-08-28 — fatos gerados ajustados para 15 projetos e 1 plano ativo; `CURRENT-WORK` aponta para este Plan.
- 2026-08-28 — primeiro Harness falhou apenas porque o Plan não seguia o schema documental canônico; nenhum teste/runtime foi executado como falha de produto.

## Validation

A validação final exige Harness no head exato e qualquer gate adicional disparado pelo path diff. O primeiro Harness serviu como validação estrutural e detectou somente o formato do Plan, agora corrigido.

## Rollback

O subtree deletado permanece recuperável do commit anterior via Git; rollback é um revert/restore normal, sem operação destrutiva fora do histórico versionado.

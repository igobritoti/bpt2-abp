# Plan 0060 — Enforce HTTP smoke CI wiring

Status: **CONCLUÍDO**

## Objetivo

Transformar a auditoria manual de cobertura dos `scripts/*-http-smoke.sh` em uma invariante automática do Harness, impedindo que uma prova HTTP seja adicionada e permaneça fora dos workflows ativos.

## Evidência de base

- Plan 0054 encontrou anteriormente `buyer-saved-search-http-smoke.sh` existente mas órfão de CI;
- Plan 0059 re-auditou os smokes e encontrou `ROOT_HTTP_SMOKE_ORPHANS = 0`;
- o Harness não possuía checagem preventiva de wiring.

## Boundary entregue

- `scripts/check-harness.py` agora exige execução real de cada `scripts/*-http-smoke.sh` em workflow root;
- referências de path trigger e `bash -n` isolado não contam como execução;
- `scripts/test-http-smoke-wiring.py` prova o caso negativo e positivo;
- `harness-gate.yml` compila e executa o teste focal antes do Harness completo.

## Não objetivos

- executar todos os smokes dentro do Harness;
- reorganizar workflows ou aumentar fan-out;
- exigir wiring de scripts não-HTTP;
- alterar produto/runtime/schema.

## Critérios de aceite

- [x] checker reporta erro quando smoke possui apenas syntax check;
- [x] checker aceita execução real `bash scripts/<smoke>`;
- [x] todos os smokes atuais satisfazem a invariante;
- [x] facts e knowledge base coerentes;
- [x] BPT2 Harness Gate #696 verde no head funcional `8400525cd87ecf309d396d30e1a89c89c5202e5d`;
- [ ] Harness fresco do head final + review/thread/base refresh antes do merge.

## Decision log

- `HTTP_SMOKE_CI_WIRING = HARNESS_INVARIANT`
- `SYNTAX_ONLY_COUNTS_AS_EXECUTION = NÃO`
- `CURRENT_HTTP_SMOKE_ORPHANS = 0`
- `PRODUCT_RUNTIME_CHANGE = NÃO`

## Progress log

- 2026-08-28 — Plan 0059 confirmou zero smokes órfãos.
- 2026-08-28 — adicionado checker de wiring ao Harness.
- 2026-08-28 — adicionado teste focal que falha com `bash -n` isolado e passa com execução real.
- 2026-08-28 — Harness #696 passou incluindo `Prove HTTP smoke wiring guard`.

## Validation

O merge permanece condicionado ao Harness fresco do head final e review/base refresh.

## Rollback

Remover a checagem e o teste focal restaura o comportamento anterior; nenhum dado/runtime é afetado.

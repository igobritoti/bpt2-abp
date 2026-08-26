# Plan 0050 — validar detector de price-drop de Favorites

Status: **ATIVO**

## Objetivo

Retomar em slice próprio o detector de price-drop fechado sem merge no PR #75, corrigindo apenas o probe Bash que falhou antes de exercer o contrato funcional.

## Escopo

- reutilizar o detector/ledger do experimento original;
- corrigir somente o erro de inicialização de variáveis locais sob `set -u`;
- rerodar os gates necessários contra o `main` atual;
- não introduzir provider, delivery, scheduler ou novo runner.

## Critérios de aceite

- [ ] syntax do smoke passa;
- [ ] Fresh Migration passa;
- [ ] Buyer Favorites regressivo passa;
- [ ] Favorite price-drop smoke passa todos os cenários congelados;
- [ ] CI fresco aplicável verde no head exato;
- [ ] review/base refresh limpos;
- [ ] merge somente verde.

## Decision log

- 2026-08-26 — PR #75 não evidenciou falha de domínio; o primeiro erro foi `username: unbound variable` no smoke.
- 2026-08-26 — retry limitado ao probe antes de qualquer alteração adicional de produto.

## Progress log

- 2026-08-26 — Plan 0050 aberto em branch nova a partir do `main` pós-Plan 0049, transplantando apenas o slice funcional/teste do PR #75.

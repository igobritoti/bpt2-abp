# Favorite price-drop retry after PR #75

Status: **EM TESTE**

## Contexto

O PR #75 foi fechado sem merge após o gate `BPT2 Buyer Favorites HTTP Gate` falhar no script `scripts/favorite-price-drop-http-smoke.sh` com `username: unbound variable` antes de exercer o contrato de detecção.

O restante da rodada do PR #75 ficou verde, incluindo Fresh Migration e regressões Seller/Public.

## Hipótese

A falha observada no PR #75 é mecânica do smoke Bash e não evidencia falha do detector de price-drop.

## Correção mínima

Separar as declarações `local` em `get_token` e `create_buyer` para que variáveis como `username` existam antes de serem usadas na expansão de `token_file`/`email` sob `set -u`.

Nenhuma regra de domínio, persistência, matching ou endpoint é alterada neste retry.

## Critério de aceite

- syntax do smoke passa;
- Fresh Migration passa;
- Buyer Favorites regressivo passa;
- smoke price-drop exerce Draft ignored, existing Favorite, no retroactive match, replay idempotent, increase ignored e unfavorite stops future match;
- demais gates aplicáveis permanecem verdes;
- merge somente após CI fresco no head exato e review/base refresh.

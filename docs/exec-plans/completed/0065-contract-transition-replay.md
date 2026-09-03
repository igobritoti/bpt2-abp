# Plan 0065 — Historical contract transition replay

Status: **CONCLUÍDO**

## Objetivo / outcome

Reexecutar o mecanismo de fingerprint/lock do Plan 0064 sobre a população histórica congelada do Plan 0062/0063 para medir quantos sinais heurísticos de sincronização correspondem a mudança real de bytes na superfície pública de contrato e qual coordenação mínima o protocolo experimental impõe quando o contrato muda.

O estudo não classifica compatibilidade semântica, não mede produtividade humana e não seleciona monorepo ou split como arquitetura vencedora.

## Contexto congelado antes dos resultados

- `main` de origem: `18fd7d10c47e541adc6eba296fe79adbe35be240`;
- população: os mesmos 13 commits `cross_boundary` do Plan 0062;
- filtro de candidato: heurística idêntica ao Plan 0063;
- superfície de contrato: `modules/**/.Contracts/**` + `main/BomPraTi/Controllers/**`;
- identidade: SHA-256 determinístico de path + bytes da árvore parent/commit.

## Perguntas e métricas pré-declaradas

RQ1. Reproduzir 12/13 candidatos da heurística anterior.

RQ2. Medir mudança real de fingerprint entre parent e commit.

RQ3. Medir quantos casos deixariam o lock frontend stale se backend integrasse primeiro.

RQ4. Medir falsos positivos da heurística para drift de bytes.

RQ5. Contar checkpoints mínimos do protocolo em cenários explicitamente declarados `compatible` e `breaking`.

Métricas: candidatos, actual contract changes, false positives, stale-lock cases, contract paths alterados e checkpoints compatible/breaking.

## Modelo pré-declarado

- `compatible`: 4 checkpoints por transição real — integrar/publicar backend, disponibilizar backend, atualizar lock/integrar frontend, disponibilizar frontend;
- `breaking`: 6 checkpoints — dual-support backend, deploy dual-support, atualizar/integrar frontend, deploy frontend, remover suporte antigo, deploy cleanup;
- `unknown`: bloqueado.

Checkpoints são estados/integrações observáveis, não tempo ou esforço humano.

## Regras de decisão pré-declaradas

- ratio de actual changes entre candidatos <50% invalidaria a heurística como proxy de drift real;
- qualquer stale-lock case exige mecanismo de sincronização equivalente ou alternativa comprovada antes de recomendar split;
- 100% de acerto nesta população não autoriza generalização futura;
- checkpoint count não autoriza claim de custo humano/lead time/manutenção.

## Execução e resultado

Workflow run: `33818750711`.

Head executado: `e56fc6a3b6ce0ac66cbbfecc1de78c540630f698`.

Artifact id: `9917474558`.

Artifact SHA-256: `a39e2bf07b2537e47beaec10cb5b38b0b309a9fc1da2b5c762dd533c4b5ea75a`.

Resultados:
- população: **13**;
- candidatos heurísticos: **12/13 (92,31%)**;
- mudanças reais de fingerprint entre candidatos: **12/12 (100%)**;
- falsos positivos: **0**;
- stale-lock cases: **12/12**;
- compatible checkpoints: **48**;
- breaking checkpoints: **72**.

O único não-candidato foi `688157b93f046c3850ddd169449b9b1fa94b1848`; ele tinha sinal frontend, nenhum sinal backend de contrato e fingerprint inalterado.

## Interpretação

O threshold de invalidação da heurística não disparou: nesta população congelada, todos os 12 candidatos por path também alteraram os bytes da superfície de contrato.

Como `stale_lock_cases > 0`, um split que preserve a fronteira atual precisa de sincronização explícita de contrato (lock/package/versionamento/compatibility gate equivalente em finalidade) ou evidência de alternativa melhor antes de recomendação.

O estudo não determina se nenhuma das 12 mudanças foi compatible ou breaking; SHA/diff não é usado como classificador semântico.

## Threats to validity

- byte drift não equivale a breaking change;
- a superfície por paths pode incluir arquivos sem efeito externo;
- outros canais de acoplamento semântico não foram medidos;
- população histórica não prevê necessariamente o futuro;
- checkpoints não medem duração, esforço ou custo;
- não houve deploy real em dois repositórios.

## Progress log

- 2026-09-03: protocolo pré-registrado antes da primeira execução.
- 2026-09-03: workflow reproduziu 12/13 candidatos e produziu artifact machine-readable.
- 2026-09-03: artifact inspecionado; 12/12 candidatos alteraram fingerprint, 0 falsos positivos.
- 2026-09-03: interpretação limitada a drift de contrato e checkpoints de protocolo.

## Decision log

- 2026-09-03: todos os 13 casos foram usados para evitar seleção subjetiva.
- 2026-09-03: compatible/breaking permanecem inputs explícitos, nunca inferidos do diff.
- 2026-09-03: build isolation não será reestudado; Plan 0064 já o demonstrou para a partição testada.
- 2026-09-03: próximo estudo decision-relevant deve medir uma quantidade operacional ainda ausente, como two-stream CI/deploy/rollback lead time ou maintenance workload controlado.

## Artefatos

- `scripts/replay-contract-transitions.py`;
- `.github/workflows/contract-transition-replay.yml`;
- artifact `contract-transition-replay.json`;
- `docs/audits/2026-09-03-contract-transition-replay.md`.

## Critérios de aceite

- protocolo antes dos resultados: PASS;
- população idêntica: PASS;
- heurística 12/13 reproduzida: PASS;
- fingerprint parent/commit: PASS;
- artifact: PASS;
- interpretação bounded: PASS;
- checks/review: revalidar no head final do PR #190.

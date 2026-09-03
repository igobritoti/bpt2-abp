# Plan 0064 — Multi-repo contract-boundary prototype

Status: **CONCLUÍDO**

## Objetivo / outcome

Testar mecanicamente uma fronteira de dois repositórios sobre o estado atual do BPT2 sem migrar o produto: um snapshot backend e um snapshot frontend independentes, com ownership explícito dos arquivos shared/control-plane e um mecanismo fail-closed de sincronização de contrato.

O estudo responde aos thresholds disparados no Plan 0063. Ele não mede produtividade humana, não cria repositórios permanentes e não seleciona monorepo ou split como arquitetura vencedora.

## Contexto congelado antes dos resultados

- `main` de origem: `1006d6c1f1e61942b037487bf1fbc9cd86d3b6ba`;
- evidência precedente: Plan 0063, com 12/13 contract-sync candidates e 13/13 mudanças contendo paths shared/control-plane;
- árvore backend protótipo: checkout completo menos `public-web/**`;
- árvore frontend protótipo: somente `public-web/**`;
- ownership shared/control-plane: backend/plataforma neste protótipo; nenhum `docs/**`, `scripts/**`, `.github/**` ou arquivo root copiado para o snapshot frontend;
- contrato público exportado: `modules/**/.Contracts/**` mais `main/BomPraTi/Controllers/**`;
- identidade do contrato: SHA-256 determinístico de path+conteúdo;
- lock frontend experimental: digest do contrato exportado, com divergência fail-closed.

## Perguntas e métricas pré-declaradas

RQ1. Backend compila sem `public-web/**`?

RQ2. Frontend instala e passa lint/typecheck/build sozinho?

RQ3. Fingerprint detecta lock stale e converge após atualização explícita?

RQ4. Protocolo representa `unchanged`, `compatible`, `breaking`, `unknown` sem inferir compatibilidade semântica?

RQ5. Quantos arquivos shared/control-plane precisam ser copiados para o frontend para estes builds?

Métricas: passes dos builds, contagens de arquivos, cópias shared para frontend, tamanho/digest da superfície de contrato, stale/updated lock e estados de rollout.

## Regras de decisão pré-declaradas

- falha de qualquer build isolado bloqueia recomendação de split até dependência ser medida/corrigida;
- `frontend_shared_files_copied > 0` exige estudo posterior de ownership/duplicação;
- stale lock não rejeitado ou lock atualizado não convergente invalida o mecanismo;
- rollout que não bloqueie `breaking`/`unknown` não sustenta alegação de segurança operacional;
- sucesso prova apenas viabilidade mecânica do particionamento/build e protocolo de lock, não custo, velocidade ou manutenção superiores.

## Execução e resultado

Workflow run: `33815473792`.

Head exato executado: `573afbb1bdf913b71c5442d9c87e60dd5278700d`.

Artifact id: `9916388576`.

Artifact SHA-256: `f5d5d1d536c95d3266a551eb70195a5ef668709afbc8fd9c8ad3421c2b1e0bb4`.

Resultados do artifact:
- arquivos rastreados: **527**;
- arquivos backend-product: **255**;
- arquivos frontend: **40**;
- arquivos shared/control-plane: **232**;
- shared files copiados para frontend: **0**;
- arquivos na superfície de contrato: **72**;
- contract SHA-256: `4bd1205c1ebf604928d2526761eba54f7e8dfc899ca6815f5d815b69dcd641d8`;
- stale lock rejeitado: **PASS**;
- lock atualizado aceito: **PASS**;
- backend snapshot build: **PASS**;
- frontend `npm ci`: **PASS**;
- frontend lint/typecheck/build (`npm run check`): **PASS**.

Protocolo de rollout executável:
- `unchanged`: permitido, ordem independente;
- `compatible`: permitido somente após classificação explícita, ordem `backend publish/deploy -> frontend lock update -> frontend deploy`;
- `breaking`: deploy direto bloqueado, exige dual-support ou rollout coordenado;
- `unknown`: bloqueado.

## Interpretação

O particionamento físico testado é mecanicamente viável para build no estado atual: backend e frontend passaram seus gates em árvores separadas, e o frontend não precisou copiar arquivos shared/control-plane para compilar.

Isso remove uma hipótese de bloqueio técnico simples — dependência de build direta entre as duas árvores — mas não demonstra vantagem do split. O Plan 0063 continua relevante: 26,53% dos commits de produto medidos eram cross-boundary, 12/13 tinham sinal de sincronização de contrato e duas linhas independentes duplicam a transação mínima de integração/revert para uma mudança lógica backend+frontend.

O fingerprint/lock prova apenas detecção mecânica de drift de contrato. Ele não classifica compatibilidade semântica, e o protocolo deliberadamente bloqueia `breaking` e `unknown`.

## Threats to validity

- builds isolados não equivalem a deploy real;
- o frontend não consome hoje package gerado dos contratos C#; fingerprint/lock é mecanismo experimental;
- compatibilidade compatible/breaking é entrada explícita, não inferência automática;
- ownership backend/plataforma é hipótese do protótipo;
- zero cópias shared no frontend não mede conhecimento/coordenação humana;
- um snapshot e um runner não medem CI lead time, deploy duration ou produtividade.

## Progress log

- 2026-09-03: protocolo registrado antes dos resultados no head inicial do PR #189.
- 2026-09-03: workflow materializou snapshots backend/frontend independentes.
- 2026-09-03: backend build independente passou.
- 2026-09-03: frontend npm install + lint/typecheck/build independente passou.
- 2026-09-03: artifact machine-readable produzido e inspecionado.
- 2026-09-03: Harness inicial falhou apenas por seções obrigatórias ausentes no plano ativo e fatos gerados stale após o 30º workflow; nenhuma falha do experimento/produto.

## Decision log

- 2026-09-03: nenhum shared/control-plane source foi copiado para o frontend para não esconder dependência por duplicação.
- 2026-09-03: compatibilidade semântica não é inferida por diff/fingerprint; `unknown` permanece fail-closed.
- 2026-09-03: resultado não autoriza migração para dois repositórios nem adoção de Nx/Turborepo.
- 2026-09-03: próximo estudo, se necessário para decisão final, deve medir custo operacional real de coordenação/contrato/deploy ou comparar lead time/manutenção com workloads equivalentes; build isolation já está empiricamente demonstrado neste particionamento.

## Artefatos

- `scripts/prototype-multi-repo-boundary.py`;
- `.github/workflows/multi-repo-contract-boundary-prototype.yml`;
- artifact `multi-repo-contract-boundary-prototype.json`;
- `docs/audits/2026-09-03-multi-repo-contract-boundary-prototype.md`.

## Critérios de aceite

- protocolo antes dos resultados: PASS;
- produto/runtime/schema/dependencies inalterados: PASS;
- artifact machine-readable: PASS;
- backend/frontend builds isolados: PASS;
- stale/updated lock: PASS;
- rollout fail-closed: PASS;
- interpretação bounded: PASS;
- checks/review: revalidar no head final do PR #189.

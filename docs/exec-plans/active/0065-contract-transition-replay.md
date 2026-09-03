# Plan 0065 — Historical contract transition replay

Status: **ATIVO**

## Objetivo / outcome

Reexecutar o mecanismo de fingerprint/lock do Plan 0064 sobre a população histórica congelada do Plan 0062/0063 para medir quantos sinais heurísticos de sincronização correspondem a mudança real de bytes na superfície pública de contrato e qual coordenação mínima o protocolo experimental impõe quando o contrato muda.

O estudo não classifica compatibilidade semântica, não mede produtividade humana e não seleciona monorepo ou split como arquitetura vencedora.

## Contexto congelado antes dos resultados

- `main` de origem do estudo: `18fd7d10c47e541adc6eba296fe79adbe35be240`;
- população: os mesmos 13 commits `cross_boundary` do Plan 0062, sem nova amostragem;
- filtro de candidato: exatamente a heurística do Plan 0063 — sinal backend em path contendo `.Contracts/` ou `main/BomPraTi/Controllers/`, e sinal frontend em `public-web/lib/**` ou `public-web/app/api/**`;
- expectativa precedente: 12/13 commits satisfazem essa heurística;
- superfície de contrato: `modules/**/.Contracts/**` + `main/BomPraTi/Controllers/**`;
- identidade do contrato: SHA-256 determinístico de path + bytes do arquivo para a árvore anterior e posterior de cada commit.

Commits congelados:

1. `eaf2a49b88453f751782fb2a5bc49f4170fe38f8`
2. `b6a9e2e693be2a80de32cdc38ee52ca910a44de2`
3. `39ed3fec59db3211d44e58fba56e874b494106a7`
4. `36195602e965f4b6cc99f436768a644e77d11252`
5. `688157b93f046c3850ddd169449b9b1fa94b1848`
6. `88f3bd355c46aa2cc1e8ff188c43866eb2e00e6f`
7. `a02fd6d311f88944b12a332617ef42c138f483e6`
8. `20561030611e802bad51d07476f5f77b3234310a`
9. `3aae3379de909ab9ed4a0a70ee931035803af55f`
10. `1471de8f69d0216f09d6c42c57a2ccbba900b2d7`
11. `d610b0f0a5bd244da9e8504265f667e0e2416d95`
12. `207ae3bf064e90b37cb094d86ef626be9d6ca48c`
13. `29e4d5fde05f8dd1a84a3146d789a5e2e7efbf87`

## Perguntas de pesquisa

RQ1. Quantos dos 13 commits continuam classificados como `contract_sync_candidate` pela mesma regra do Plan 0063?

RQ2. Entre os candidatos, quantos realmente mudam o SHA-256 da superfície pública de contrato entre parent e commit?

RQ3. Em quantos casos o lock experimental do frontend ficaria stale após integrar apenas o lado backend?

RQ4. Quantos candidatos heurísticos são falsos positivos para mudança de bytes da superfície de contrato?

RQ5. Para cada mudança real de contrato, quantos checkpoints mínimos o protocolo experimental exige sob dois cenários declarados, sem inferência semântica: `compatible` e `breaking`?

## Métricas pré-declaradas

- total de commits: 13;
- `contract_sync_candidates` e ratio;
- `actual_contract_changes` e ratio entre candidatos;
- `heuristic_false_positives`;
- `stale_lock_cases`;
- número de arquivos de contrato antes/depois por caso;
- quantidade de paths de contrato adicionados/modificados/removidos por caso;
- checkpoints de coordenação por caso e totais em cenários `compatible` e `breaking`.

## Modelo de checkpoints pré-declarado

O modelo conta estados/integrações observáveis necessários ao protocolo, não tempo ou esforço humano.

Para uma mudança real de contrato classificada externamente como `compatible`:
1. integrar/publicar backend com novo contrato;
2. disponibilizar/deployar backend compatível;
3. atualizar lock + integrar frontend;
4. disponibilizar/deployar frontend.

Total: **4 checkpoints** por transição real.

Para uma mudança real classificada externamente como `breaking`:
1. integrar backend com dual-support/compatibilidade temporária;
2. deployar dual-support;
3. atualizar lock + integrar frontend;
4. deployar frontend consumidor novo;
5. remover suporte antigo no backend;
6. deployar cleanup backend.

Total: **6 checkpoints** por transição real.

`unknown` permanece bloqueado e não recebe contagem de rollout permitido.

## Regras de decisão pré-declaradas

- se `actual_contract_changes / contract_sync_candidates < 0.50`, a heurística por path é inadequada como proxy de drift real e estudos posteriores devem usar fingerprint/diff de conteúdo;
- se `stale_lock_cases > 0`, qualquer split que preserve o contrato atual precisa de mecanismo equivalente de sincronização ou evidência de alternativa superior antes de recomendação;
- se todos os candidatos forem mudanças reais, a heurística anterior ganha suporte apenas para esta população histórica; não se generaliza automaticamente;
- a contagem de checkpoints não autoriza alegação de custo humano, lead time ou manutenção.

## Execução

Workflow dedicado deverá:
1. checkout do head exato com `fetch-depth: 0`;
2. verificar que todos os 13 commits e seus parents estão disponíveis;
3. executar `scripts/replay-contract-transitions.py`;
4. publicar `contract-transition-replay.json` como artifact;
5. falhar se a população não tiver 13 casos, se a heurística não reproduzir 12 candidatos ou se o modelo fail-closed permitir `unknown`.

## Threats to validity

- a superfície de contrato é definida por paths e pode conter arquivos sem impacto de API efetiva;
- mudança de bytes não equivale a breaking change;
- ausência de mudança nessa superfície não prova ausência de acoplamento semântico por outros canais;
- commits históricos representam o período congelado, não toda a vida futura do produto;
- checkpoints são um modelo de protocolo, não duração, esforço ou custo humano.

## Critérios de aceite

- protocolo registrado antes dos resultados;
- população histórica idêntica ao Plan 0062/0063;
- artifact machine-readable por head exato;
- fingerprint parent/commit por caso;
- reprodução da heurística 12/13;
- conclusões bounded às métricas declaradas;
- checks aplicáveis verdes e nenhum review thread pendente antes de merge.

## Progress log

- 2026-09-03: protocolo pré-registrado antes da primeira execução.

## Decision log

- 2026-09-03: usar todos os 13 casos elimina seleção subjetiva de amostra.
- 2026-09-03: compatibilidade semântica não será inferida de SHA/diff; compatible/breaking são cenários explícitos.

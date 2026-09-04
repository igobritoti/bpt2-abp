# Plan 0066 — Paired CI cost probe

Status: **CONCLUÍDO**

## Objetivo / outcome

Medir uma quantidade operacional ainda ausente na decisão monorepo vs split: custo de execução CI de um workload equivalente backend+frontend, comparando no mesmo runner uma execução conjunta e uma execução particionada em snapshots independentes.

O estudo não mede produtividade humana, deploy real, custo financeiro nem manutenção de longo prazo. Ele mede duração observada e trabalho executado sob um protocolo controlado.

## Contexto congelado antes dos resultados

- `main` de origem: `4bdf7475d77320505bf4861fe39c3b18da54c40d`;
- partição idêntica ao Plan 0064: backend = checkout menos `public-web/**`; frontend = somente `public-web/**`;
- backend command: `dotnet build main/BomPraTi/BomPraTi.csproj --configuration Release --nologo`;
- frontend commands: `npm ci --no-audit --no-fund` + `npm run check`;
- comparação pareada no mesmo GitHub-hosted runner;
- mínimo de 5 pares válidos;
- ordem alternada: ímpares `combined -> split`, pares `split -> combined`;
- diretórios novos e sem outputs de build compartilhados entre condições.

## Regras de decisão pré-declaradas

- menos de 5 pares válidos: evidência insuficiente;
- diferença absoluta de mediana <10%: inconclusiva para custo CI neste protocolo;
- split compute >=20% acima do combined: penalidade de compute relevante;
- split critical-path >=20% abaixo do combined: benefício potencial de paralelização relevante;
- trade-offs conflitantes permanecem trade-offs;
- nenhum resultado autoriza claim de produtividade, manutenção ou custo financeiro.

## Execução

### Piloto não-autoritativo

Run: `33823539141`.
Artifact id: `9919234890`.
Artifact SHA-256: `73d5925d595782573980a6fdd822f211b0c1114503cc06cb4e2331f40062b39d`.

O checkout do workflow foi confirmado no PR head `2308b81fb2e7cd746baba6e9caebffbaeacc5c9b`, porém o JSON registrou `GITHUB_SHA` da merge-ref em `head_sha`. O workload foi executado corretamente, mas a identidade registrada no artifact ficou ambígua; portanto este run é mantido apenas como piloto de estabilidade e não como evidência autoritativa.

### Execução autoritativa

Run: `33824148587`.
Head medido: `74395f87f3f0009481cdf8dda8bc2b5216eb90ec`.
Artifact id: `9919443682`.
Artifact SHA-256: `2fec3d4d711eacb1c69abeffcdaca911153754f2c6899467ddcfebaad77e9345`.

O script passou a registrar `git rev-parse HEAD` como `head_sha` e manteve `GITHUB_SHA` separadamente apenas como contexto do evento.

## Resultados autoritativos

- pares válidos: **5/5**;
- combined total mediano: **28,377 s**;
- split compute mediano: **28,650 s**;
- split compute / combined: **1,0096** (**+0,96%**);
- split critical path mediano: **23,631 s**;
- split critical path / combined: **0,8327** (**-16,73%**).

O primeiro par apresentou warm-up maior, principalmente no restore/build .NET, mas a mediana ficou estável e próxima ao piloto. O desenho alternado reduz, mas não elimina, efeitos de warm-up e caches do runner.

## Interpretação contra thresholds

- diferença de compute: **+0,96%**, abaixo de 10% e muito abaixo do threshold de penalidade de 20% — **inconclusiva / sem penalidade material demonstrada neste workload**;
- redução de critical path modelado: **16,73%**, acima de 10% mas abaixo do threshold pré-registrado de 20% — **não atinge evidência suficiente para benefício arquitetural relevante**;
- portanto o estudo não seleciona monorepo nem split.

O resultado mede apenas build/check do estado atual em runner compartilhado. Ele não mede scheduling/startup real de dois jobs independentes, deploy, rollback, revisão humana, lead time de PR, coordenação de contrato ou manutenção futura.

## Threats to validity

- GitHub-hosted runners têm ruído de infraestrutura;
- o critical path do split é `max(streams)` modelado, não elapsed observado de dois jobs reais;
- package restore/cache pode influenciar pares posteriores;
- um workload de build/check não representa todo CI nem deploy;
- o estado atual do projeto pode não representar workloads futuros.

## Progress log

- 2026-09-03: protocolo pré-registrado antes da primeira execução.
- 2026-09-03: piloto completou 5/5 pares, mas artifact registrou merge-ref no campo `head_sha`.
- 2026-09-03: rastreabilidade corrigida para registrar `git rev-parse HEAD`; piloto rebaixado a não-autoritativo.
- 2026-09-03: execução autoritativa completou 5/5 pares no head `74395f87...`.
- 2026-09-03: thresholds avaliados sem selecionar arquitetura.

## Decision log

- 2026-09-03: compute e critical path permanecem métricas separadas.
- 2026-09-03: resultado abaixo dos thresholds pré-registrados não será promovido a preferência arquitetural.
- 2026-09-03: o próximo estudo decision-relevant, se necessário, deve medir uma variável ainda ausente — preferencialmente lead time/coordenação de mudança equivalente ou deploy/rollback em duas streams reais — em vez de repetir build isolation ou fingerprint.

## Critérios de aceite

- protocolo antes dos resultados: PASS;
- >=5 pares válidos: PASS;
- artifact machine-readable: PASS;
- head medido explicitamente: PASS na execução autoritativa;
- comandos equivalentes ao Plan 0064: PASS;
- interpretação bounded: PASS;
- checks/review: revalidar no head final do PR #191.

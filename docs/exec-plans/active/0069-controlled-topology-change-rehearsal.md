# Plan 0069 — Controlled topology change rehearsal

Status: **ATIVO**

## Objetivo / outcome

Executar o mesmo workload funcional e compilável em duas topologias controladas — árvore combinada atual e duas árvores fisicamente separadas — mantendo o conteúdo da mudança constante e variando somente o fluxo de integração/validação.

O workload é experimental: adicionar um campo opcional compatível a `VehicleRefDto` e um consumidor TypeScript compilável que lê esse campo. As alterações são aplicadas apenas em cópias temporárias; nenhum campo experimental entra no produto.

## Contexto congelado antes dos resultados

- `main` de origem: `0dd665bafa614018891304ff41d0b785dcaa1a26`;
- contrato real escolhido: `modules/catalog/src/BomPraTi.Catalog.Contracts/VehicleRefDto.cs`;
- consumidor: arquivo TypeScript temporário sob `public-web/lib/` para participar do `npm run check`;
- mudança idêntica nos dois tratamentos:
  - backend: adicionar `string? TopologyProbeLabel = null` ao final do positional record;
  - frontend: adicionar tipo/consumer que aceita `topologyProbeLabel?: string | null` e produz fallback determinístico;
- nenhum arquivo de produto do checkout fonte será modificado pelo workload.

## Perguntas e métricas pré-declaradas

RQ1. O mesmo conteúdo de mudança compila/passa checks nas duas topologias?

RQ2. Quantas transações/checkpoints operacionais mínimos são necessários em cada topologia para levar a mudança de baseline a estado validado?

RQ3. Qual o custo de compute e o critical path modelado de cada fluxo quando executados no mesmo runner?

Métricas por par: tempo de materialização, patch, build backend, `npm ci`, `npm run check`, digest de contrato antes/depois, número de transações/checkpoints e resultado funcional do consumer. Serão executados 3 pares alternando a ordem dos tratamentos.

## Tratamentos

### Combined

1. materializar uma cópia completa;
2. aplicar backend + consumer no mesmo change-set;
3. validar backend;
4. validar frontend;
5. verificar consumer funcional.

Checkpoint de integração mínimo modelado: **1 transação atômica**.

### Split

1. materializar backend sem `public-web` e frontend somente `public-web`;
2. aplicar mudança backend;
3. validar backend;
4. publicar/registrar novo digest de contrato;
5. atualizar consumer frontend para o digest novo;
6. validar frontend;
7. verificar consumer funcional.

Checkpoints mínimos modelados: **2 transações de repositório + 1 handoff de contrato**.

## Regras de decisão pré-declaradas

- menos de 3 pares em que ambos os tratamentos passem: evidência insuficiente;
- qualquer diferença no conteúdo lógico da mudança entre tratamentos invalida o par;
- se uma topologia não construir/validar, registrar incompatibilidade mecânica do workload nessa topologia;
- diferença de compute >=20% em uma direção é material para este workload;
- redução de critical path >=20% é benefício potencial material para este workload;
- diferenças temporais menores que 20% são inconclusivas;
- diferença de checkpoints/transações é reportada estruturalmente, mas **não** convertida em horas de trabalho ou produtividade humana;
- nenhum resultado isolado autoriza afirmar superioridade global de monorepo ou multi-repo.

## Threats to validity

- workload é pequeno e sintético, embora use um contrato real e checks reais;
- campo opcional compatível não representa mudança breaking;
- consumer temporário testa compilabilidade/consumo, não UX de produção;
- tempos de runner têm ruído de cache/host;
- critical path do split é modelado como máximo dos streams, não elapsed de dois runners realmente paralelos;
- checkpoints não equivalem a esforço cognitivo ou tempo humano.

## Progress log

- 2026-09-03: protocolo pré-registrado antes de executar o workload.

## Decision log

- 2026-09-03: usar `VehicleRefDto` porque pertence à superfície de contrato real já medida nos Plans 0064/0065.
- 2026-09-03: mudança opcional compatível escolhida para permitir rollout sequencial sem inventar uma breaking change.
- 2026-09-03: alterações experimentais ficam apenas em cópias temporárias para não adicionar feature artificial ao produto.

## Critérios de aceite

- protocolo registrado antes dos resultados;
- 3 pares válidos ou insuficiência explicitamente registrada;
- mesmo patch lógico em ambos os tratamentos;
- build/check real em ambas as topologias;
- artifact machine-readable com tempos, digests e checkpoints;
- interpretação contra thresholds pré-declarados;
- plano arquivado e fatos gerados atualizados;
- checks/review verdes no head final.

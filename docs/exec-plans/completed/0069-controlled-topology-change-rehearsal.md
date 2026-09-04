# Plan 0069 — Controlled topology change rehearsal

Status: **CONCLUÍDO**

## Objetivo / outcome

Executar o mesmo workload funcional e compilável em duas topologias controladas — árvore combinada atual e duas árvores fisicamente separadas — mantendo o conteúdo da mudança constante e variando somente o fluxo de integração/validação.

O workload experimental adicionou `string? TopologyProbeLabel = null` a uma cópia temporária do contrato real `VehicleRefDto` e um consumer TypeScript temporário. Nenhum campo experimental foi integrado ao produto.

## Contexto congelado antes dos resultados

- `main` de origem: `0dd665bafa614018891304ff41d0b785dcaa1a26`;
- contrato: `modules/catalog/src/BomPraTi.Catalog.Contracts/VehicleRefDto.cs`;
- consumidor temporário: `public-web/lib/topology-probe.ts`;
- 3 pares, alternando a ordem combined/split;
- thresholds: diferença temporal material somente a partir de 20%.

## Resultado autoritativo

Run: `33830287763`

Artifact: `9921501268`

Artifact SHA-256: `9d7a645128f34f2f063ea96b4470c269112110a57d38bd5535923c10c5733444`

Head medido: `64137478bf526aef8c2ad8fa19837d06573b9fcc`

Change fingerprint: `2185812ec0e0df738d26ca8db6e3fefd3b0fd278cd264b82d3bb0d018de73bcc`

- pares requeridos: **3**;
- pares válidos: **3/3**;
- ambos os tratamentos: backend build PASS, frontend install/check PASS, consumer PASS;
- identidade lógica da mudança: preservada em todos os pares;
- combined compute mediano: **29.133 s**;
- split compute mediano: **31.592 s**;
- split vs combined compute: **+8.44%**;
- combined critical path mediano: **29.133 s**;
- split critical path modelado: **25.720 s**;
- split vs combined critical path: **-11.71%**;
- combined: **1 transação / 0 handoffs / 1 checkpoint**;
- split: **2 transações / 1 handoff / 3 checkpoints**.

## Interpretação contra regras pré-declaradas

- `+8.44%` de compute no split fica abaixo do threshold de 20%: **diferença temporal inconclusiva**;
- `-11.71%` no critical path modelado fica abaixo do threshold de 20%: **benefício de paralelização inconclusivo**;
- o workload não encontrou incompatibilidade mecânica em nenhuma topologia;
- a diferença de 1 para 3 checkpoints é estrutural e observada pelo protocolo, mas não é convertida em horas, produtividade ou custo humano.

O estudo não seleciona uma arquitetura vencedora. Ele demonstra que, para uma pequena mudança compatível de contrato+consumer, ambas as topologias são mecanicamente viáveis; o split exige mais fronteiras de integração explícitas, sem penalidade/benefício temporal >=20% demonstrado neste workload.

## Threats to validity

- workload pequeno e sintético, embora use contrato e checks reais;
- não representa mudança breaking;
- consumer temporário mede compilabilidade/consumo, não UX real;
- tempos são de um mesmo runner e sofrem ruído;
- critical path do split é modelado com dependência de handoff, não observado em dois runners paralelos;
- checkpoints não medem esforço cognitivo.

## Progress log

- 2026-09-03: protocolo pré-registrado antes dos resultados.
- 2026-09-03: modelo de critical path corrigido antes da primeira execução para respeitar a dependência `backend build -> contract handoff -> consumer update/check`.
- 2026-09-03: run `33830287763` concluiu 3/3 pares válidos e publicou artifact reproduzível.

## Decision log

- 2026-09-03: usar `VehicleRefDto` por pertencer à superfície de contrato real já estudada.
- 2026-09-03: manter mudança apenas nos snapshots temporários evita contaminar produto com feature experimental.
- 2026-09-03: diferenças temporais observadas ficaram abaixo do threshold; não declarar vencedor.
- 2026-09-03: registrar checkpoints separadamente porque são propriedade do fluxo, não proxy validado de esforço humano.

## Critérios de aceite

- [x] protocolo pré-registrado;
- [x] 3 pares válidos;
- [x] mesmo patch lógico;
- [x] build/check reais em ambas topologias;
- [x] artifact machine-readable;
- [x] interpretação contra thresholds;
- [x] plano arquivado;
- [ ] checks/review verdes no head final.

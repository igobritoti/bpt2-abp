# Comparador — contrato de cardinalidade BPT2

Data: 2026-08-25
Status: decisão de produto para orientar a auditoria do Plan 0046; não autoriza implementação antes dos pré-requisitos de enrichment.

## Decisão

O comparador BPT2 terá cardinalidade variável escolhida pelo usuário, com teto inicial de **4 veículos**.

- mínimo útil: **2 Vehicles**;
- cardinalidades aceitas no primeiro contrato: **2, 3 ou 4 Vehicles**;
- **4 é teto inicial, não quantidade fixa**;
- o usuário escolhe quantos Vehicles deseja comparar dentro desse intervalo;
- a UI não deve exigir quatro seleções para iniciar;
- o contrato interno da matriz deve ser N-colunas dentro do limite suportado, evitando branches independentes 2x/3x/4x quando um contrato genérico resolver corretamente.

## Evidência

- O BPT1 já provou comportamento 2x/3x e usa matriz capaz de receber N colunas.
- O benchmark atual da Webmotors demonstra que comparação de até quatro veículos é uma superfície real de mercado.
- Essas evidências sustentam viabilidade e referência de UX, mas não autorizam copiar arquitetura ou implementação do donor/concorrente.

## Testes obrigatórios

Antes da implementação funcional, o contrato deve provar:

1. seleção válida com exatamente 2, 3 e 4 VehicleIds distintos;
2. rejeição de 0, 1 e mais de 4 Vehicles;
3. rejeição ou normalização explícita de IDs duplicados;
4. ordem selecionada pelo usuário preservada na apresentação;
5. simetria factual: reordenar colunas não altera os fatos de cada Vehicle;
6. `only differences` funciona de forma independente da cardinalidade;
7. Vehicle sem dado de enrichment produz `não informado`, nunca dado inventado;
8. URL/estado compartilhável preserva exatamente a seleção feita pelo usuário;
9. remoção de um Vehicle de 4→3 ou 3→2 não exige reiniciar a comparação;
10. nenhum Listing legado pode virar fallback de ficha técnica para satisfazer a matriz canônica.

## Pré-requisito ainda aberto

O contrato atual do Catalog BPT2 expõe identidade canônica, mas não enrichment técnico suficiente para um comparador útil. Portanto:

`enrichment canônico mínimo → teste do contrato comparável → comparador 2–4`

A cardinalidade de 4 não altera esse bloqueio.

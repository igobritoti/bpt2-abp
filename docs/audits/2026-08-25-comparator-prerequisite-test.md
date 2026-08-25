# Comparator prerequisite test — BPT2

Data: 2026-08-25

Status: **REPROVADO PARA IMPLEMENTAÇÃO IMEDIATA**

Este teste pertence ao Plan 0046 e avalia se o BPT2 atual já possui dados canônicos suficientes para iniciar um comparador técnico sem reintroduzir dependência de Listing legado.

## Hipótese testada

> O contrato canônico atual do Catalog é suficiente para montar um comparador técnico útil entre 2–3 Vehicles sem fallback textual de Listing.

## Evidência BPT2

O contrato público atual `VehicleRefDto` contém somente:

- `Id`;
- `Brand`;
- `Model`;
- `Generation?`;
- `Version`;
- `ModelYear?`.

O aggregate `Vehicle` contém somente os vínculos:

- `BrandId`;
- `ModelId`;
- `GenerationId?`;
- `VersionId`;
- `ModelYear?`.

Não há, no contrato/aggregate atual, ficha mecânica, consumo, dimensões, equipamentos, segurança, preço de referência ou fatos de mercado.

## Evidência donor

O comparador técnico do BPT1 depende de dados além da identidade:

- motor;
- cilindrada;
- potência;
- torque;
- câmbio;
- tração;
- consumo urbano/rodoviário;
- peso;
- porta-malas;
- tanque;
- portas;
- preço de referência;
- fatos/posição de mercado;
- equipamentos estruturados quando disponíveis.

O donor também distingue corretamente `não informado` de `não possui` e evita inferir equipamento canônico a partir de texto legado.

## Resultado

A hipótese foi **reprovada**.

Com o contrato atual do BPT2, um comparador técnico imediato teria uma destas consequências indesejadas:

1. comparar apenas identidade/ano, gerando utilidade muito baixa;
2. usar campos de Listing como fallback e voltar a misturar oferta com autoridade canônica do Vehicle;
3. inventar um schema de enrichment dentro do próprio Comparador, criando acoplamento errado.

Nenhuma dessas opções é aceitável segundo as regras atuais do produto.

## Decisão derivada

- Comparador continua classificado como **capability valiosa / gap real**.
- Comparador deixa de ser candidato ao **primeiro slice funcional imediato**.
- Antes dele, deve existir um **mínimo de Vehicle Enrichment canônico** suficiente para sustentar um teste de comparação útil.
- Esse resultado não autoriza importar o schema de enrichment do BPT1; apenas prova a dependência funcional.

## Próxima hipótese

> É possível definir um conjunto mínimo de enrichment canônico, pequeno e bem providenciado, que aumente simultaneamente a utilidade do Vehicle Hub e viabilize um comparador técnico sem depender de Listing.

## Teste proposto para Vehicle Enrichment mínimo

1. selecionar um conjunto pequeno de atributos de alto valor e baixa ambiguidade;
2. definir tipo, unidade e nulabilidade de cada atributo;
3. definir provenance/source por valor ou conjunto coerente de valores;
4. definir regra de precedência/conflito entre fontes;
5. distinguir `desconhecido`, `não aplicável` e `ausência confirmada` quando semanticamente necessário;
6. carregar fixture de pelo menos 3 Vehicles;
7. provar leitura pelo Vehicle Hub sem quebrar Structure;
8. provar que o mesmo contrato puro consegue alimentar uma matriz 2x/3x;
9. reprovar se a solução exigir dependência Catalog → Marketplace ou leitura de Listing para completar ficha técnica;
10. só depois escolher se o primeiro slice deve ser enrichment em si ou comparador sobre enrichment já aprovado.

## Consequência para a ordem de auditoria

A ordem técnica passa a ser:

`Vehicle Enrichment mínimo → prova de contrato comparável → Comparador`

Analytics/CRM/Promotions continuam trilhas independentes e podem ser avaliadas em paralelo lógico, sem abrir múltiplos slices funcionais simultâneos.

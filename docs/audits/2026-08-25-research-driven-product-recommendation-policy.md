# Política de recomendação proativa de produto — Plan 0046

Data: 2026-08-25

## Objetivo

Durante a auditoria BPT1 → BPT2 e benchmarks externos, o agente pode propor mudanças no roadmap além de simples transplante de funcionalidades legadas.

As recomendações podem ser de:

- **ADIÇÃO** — capability nova ou extensão não existente no BPT1, quando a evidência mostrar problema/benefício relevante para o BPT2;
- **EDIÇÃO/SIMPLIFICAÇÃO** — alterar escopo, UX, estados, contrato ou dependências de uma capability existente quando a solução do donor for mais complexa ou menos adequada que o necessário;
- **EXCLUSÃO** — retirar capability do roadmap ou explicitamente não migrá-la quando não resolver problema atual, duplicar comportamento já coberto ou introduzir custo/risco sem evidência suficiente;
- **ADIAMENTO** — manter candidata conhecida fora da implementação até surgir caso de uso, métrica ou dependência que a justifique;
- **SUBSTITUIÇÃO** — recomendar abordagem diferente da usada no BPT1 quando documentação, testes ou constraints atuais do BPT2 indicarem solução melhor.

## Regra epistemológica

Toda recomendação deve separar:

- **A** — documentação oficial atual, standards, contratos/código versionado;
- **B** — comportamento executado/reproduzido, testes, CI, benchmark mensurável;
- **C** — inferência arquitetural/produto derivada de A/B;
- **D** — preferência/opinião.

Recomendação D nunca será apresentada como fato ou requisito.

## Critério mínimo para recomendação material

Uma recomendação que altere o roadmap deve registrar, quando aplicável:

1. problema ou oportunidade observada;
2. evidência BPT1 e/ou externa;
3. estado atual do BPT2;
4. alternativa considerada;
5. risco/custo da mudança;
6. hipótese falsificável;
7. teste ou métrica que pode rejeitar a recomendação;
8. classificação: `ADICIONAR`, `EDITAR`, `EXCLUIR`, `ADIAR`, `SUBSTITUIR` ou `MANTER`.

## Guardrails

- benchmark de concorrente prova existência/uso de mercado, não necessidade automática;
- existência de código no BPT1 não prova valor atual;
- uma feature bem testada no donor pode ser excluída do BPT2 por falta de problema atual;
- uma feature ausente no donor pode ser adicionada ao roadmap se houver evidência suficiente;
- simplificar é preferível a transplantar complexidade sem necessidade comprovada;
- recomendações podem mudar conforme novas evidências aparecem; mudanças de decisão devem ser registradas no log do Plan 0046.

## Aplicação já observada

- Comparador: **MANTER COMO CANDIDATO**, mas **EDITAR** cardinalidade para seleção variável de 2–4 Vehicles e **ADIAR implementação** até enrichment mínimo canônico.
- CRM: **EDITAR/SIMPLIFICAR**; testar pipeline mínimo antes de copiar os cinco estados do BPT1.
- Analytics: **SUBSTITUIR** a ideia de copiar dashboard por instrumentação mínima orientada a perguntas de produto.
- Planner/Argus Core: **EXCLUIR COMO FEATURES DE PRODUTO**, apesar de implementação/testes no donor.
- Credits: **ADIAR**, subordinado a uma tese comercial real.

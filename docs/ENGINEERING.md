# Engenharia — política de decisão e execução

## Princípio

O projeto deve reduzir decisões por preferência quando existe evidência disponível. O objetivo não é eliminar julgamento humano, mas separar claramente **fato, observação, inferência e preferência**.

## Classes de evidência

- **A — direta:** documentação oficial atual, standard aplicável, código/testes upstream ou teste executado no BPT2 que prova diretamente a afirmação.
- **B — observada:** comportamento reproduzido empiricamente no BPT2.
- **C — inferência:** conclusão arquitetural derivada de A/B, mas não provada diretamente.
- **D — hipótese/preferência:** escolha reversível, convenção, gosto ou opinião.

### Regra de congelamento

Arquitetura só é congelada quando a necessidade do BPT e evidência suficiente A/B sustentam a escolha. Evidência de que uma tecnologia **pode** fazer algo não prova que BPT **deve** usá-la.

C/D podem orientar experimento ou implementação provisória, mas devem permanecer identificadas como tal.

## Ordem de evidência

Quando houver conflito, priorizar:

1. teste executado/código que reproduz o comportamento relevante;
2. documentação oficial atual;
3. standard aplicável;
4. evidência empírica externa confiável;
5. inferência arquitetural;
6. opinião/preferência.

Atualidade importa: para frameworks, ferramentas e serviços em evolução, documentação desatualizada não deve sobrepor documentação atual.

## Fluxo de decisão

`pergunta → fonte oficial/código/standard → capacidade comprovada? → necessidade BPT resolvida? → se não, teste mínimo → passa/não passa → registrar decisão`

Estados canônicos estão em `MDV.md`:

- `PASSA`
- `NÃO PASSA`
- `DECIDIDO`
- `NÃO DECIDIDO`
- `ADIADO`

`PASSA` não implica automaticamente `DECIDIDO`.

## ADRs

Criar ou atualizar ADR quando uma escolha:

- altera boundary, ownership ou direção de dependência;
- introduz infraestrutura ou mecanismo transversal;
- muda consistência/transação/concurrency;
- muda estratégia de persistência ou side effects;
- é cara de reverter ou provável de ser questionada novamente.

ADR deve registrar contexto, decisão, evidência, consequências e o que **não** está sendo afirmado.

## Autonomia de agentes e ferramentas

Política adaptada da orientação atual da OpenAI para modelos agentic:

- pedido de revisar/explicar/diagnosticar/planejar autoriza leitura e análise, não escrita;
- pedido de mudar/construir/corrigir autoriza alterações em escopo e validação não destrutiva relevante;
- confirmação humana é necessária antes de ações destrutivas, escrita externa não implícita no pedido, alteração de produção/credenciais, gasto ou expansão material de escopo.

Acesso deve seguir least privilege. Sandbox de shell não deve ser assumido como proteção de ferramentas externas/MCP.

## Regras arquiteturais de execução

- modular monolith primeiro;
- um módulo não importa implementação de outro módulo;
- contratos intermodulares devem ser explícitos;
- uma ação de negócio usa transação consistente quando isso é possível dentro do mesmo banco/UoW;
- DB + provider externo não deve ser tratado como transação ACID única;
- concorrência crítica escolhe explicitamente optimistic concurrency, row lock ou distributed lock conforme evidência;
- side effects críticos exigem idempotência persistente quando repetição possa causar dano;
- nenhuma tecnologia extra entra por antecipação.

## Processo de mudança

1. localizar a fonte de verdade afetada;
2. definir comportamento/critério de aceite;
3. identificar decisões já congeladas e decisões abertas;
4. implementar a menor mudança coerente;
5. rodar validação proporcional ao risco em `QUALITY.md`;
6. atualizar docs/ADR/MDV quando a verdade do projeto mudar;
7. registrar nova dívida ou decisão pendente em vez de escondê-la no código.

## Proibições

- não inventar requisitos técnicos ou números de performance;
- não promover preferência a requisito sem evidência;
- não desabilitar teste, autorização ou validação para obter verde;
- não migrar tecnologia do BPT1 por sunk cost;
- não introduzir abstração/infra “para o futuro” sem caso atual demonstrável.

## Fontes externas desta política

Rastreabilidade da orientação OpenAI usada neste modelo de trabalho: `references/OPENAI_ENGINEERING_GUIDANCE.md`.

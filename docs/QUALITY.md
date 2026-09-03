# Qualidade — validação, evidência executada e Definition of Done

Esta é a fonte canônica para **como provar que uma mudança está pronta**.

## Princípio

Validação deve ser proporcional ao risco e, quando possível, mecânica. Prosa descreve intenção; testes, linters, builds, migrations e CI comprovam invariantes executáveis.

Não crie suites por ritual e não pule um check relevante por conveniência.

## Matriz mínima

| Mudança | Validação mínima |
|---|---|
| harness/documentação | `python3 scripts/check-harness.py` |
| domínio/aplicação | build + teste focado |
| boundary/dependência modular | `python3 scripts/check-boundaries.py` + ataque negativo relevante |
| schema/persistência | migration aplicável + fresh database quando afetar baseline |
| auth/ownership | caso permitido + caso negado |
| visibilidade pública | estado publicável + estado proibido invisível |
| optimistic concurrency | update válido + stale explicitamente rejeitado |
| upload/media | válido + bytes/tipo inválido conforme risco |
| side effect externo | falha intermediária + retry/idempotência/recuperação |
| bug | regressão que falha antes e passa depois, quando viável |

## Evidência empírica para recomendações

Quando uma conclusão técnica depende de observação — performance, manutenção, complexidade, confiabilidade, produtividade, qualidade, segurança, escalabilidade, custo ou comportamento comparativo — a prova deve seguir um desenho empírico adequado à pergunta e ser reproduzível na medida necessária para sustentar a decisão.

A referência metodológica do projeto está em [`references/EMPIRICAL_SOFTWARE_ENGINEERING.md`](references/EMPIRICAL_SOFTWARE_ENGINEERING.md), baseada nos ACM SIGSOFT Empirical Standards e em critérios ACM de artifact review/reproducibility.

Antes de aceitar uma recomendação empírica como evidência A/B, verificar conforme aplicável:

- pergunta, hipótese ou afirmação explicitada antes da conclusão;
- objetos de estudo, população/amostra ou workload definidos;
- baseline e alternativas comparáveis;
- ambiente, versões e configuração material registradas;
- métrica e unidade adequadas à afirmação;
- critérios de inclusão/exclusão documentados;
- regra de decisão ou threshold predefinido quando houver risco de escolha pós-resultado;
- repetições/amostra suficientes para o tipo de variabilidade observada;
- artefatos e comandos suficientes para repetir a execução;
- resultados brutos ou intermediários suficientes para rechecagem;
- limitações e ameaças à validade explicitadas;
- conclusão limitada ao que foi efetivamente medido.

Falha em um item não invalida automaticamente todo estudo; reduz a força da evidência conforme sua relevância para a afirmação. Quando a lacuna impedir uma conclusão factual, classificar o resultado como inferência/hipótese e propor o menor experimento capaz de resolvê-la.

Não usar popularidade, preferência de framework, opinião de comunidade, contagem de estrelas, benchmark de terceiros incompatível, exemplo de documentação ou experiência isolada como prova de superioridade no BPT2. Essas fontes podem gerar hipóteses ou orientar desenho experimental, mas não substituem evidência compatível com o contexto do projeto.

## Validação de capacidades transplantadas ou inspiradas em outro projeto

Para BPT1 → BPT2 e qualquer donor futuro, não validar por equivalência visual nem por contagem de arquivos. Validar o **comportamento e o risco**.

Antes de implementar:

- provar se a capacidade existe de fato no donor por código/teste/execução, distinguindo implementação de intenção documental;
- provar o estado equivalente no BPT2 para evitar duplicação;
- identificar invariantes, casos negativos e efeitos colaterais relevantes;
- confrontar decisões técnicas do donor com documentação oficial atual, standards aplicáveis e limitações do BPT2;
- definir acceptance criterion independente da tecnologia usada no donor.

Durante a implementação, selecionar testes por risco. Sempre que aplicável, cobrir:

| Risco da migração | Evidência esperada |
|---|---|
| comportamento divergente | characterization/contract test do comportamento desejado + teste focado no BPT2 |
| perda ou transformação de dados | fixtures representativas + contagem/reconciliação + invariantes antes/depois |
| autorização/ownership | allowed + denied + tentativa de owner controlado pelo cliente |
| visibilidade/estado | estados permitidos e proibidos |
| idempotência/retry | repetição, falha intermediária e recuperação |
| integração externa | contrato documentado + failure modes; não depender só de happy path |
| ranking/scoring/recomendação | dataset/workload fixado, métrica explícita, baseline e comparação reproduzível |
| performance | workload, ambiente, método, warm-up quando aplicável, distribuição/percentis e threshold definidos antes da conclusão |
| UX/valor de produto | hipótese e métrica observável; não converter preferência de interface em requisito técnico |

### Characterization antes de redesign

Quando o comportamento do BPT1 for relevante mas sua implementação não for desejável, primeiro capture o comportamento que merece sobreviver em exemplos, fixtures ou contratos. Depois implemente a solução nativa do BPT2 contra esses critérios. Isso reduz o risco de reescrever a solução e, sem perceber, mudar a regra de produto.

### Benchmark e experimento

Benchmark só sustenta decisão quando é reproduzível e comparável. Registrar, conforme o caso:

- hipótese;
- dataset/workload e origem;
- baseline e alternativa;
- ambiente e versões relevantes;
- métrica e unidade;
- número de execuções/amostra quando material;
- critérios de inclusão/exclusão;
- threshold ou regra de decisão definidos antes de interpretar o resultado;
- resultado bruto suficiente para rechecagem.

Não usar um benchmark para provar o que ele não mediu. Resultado local sintético não vira requisito de produção sem justificar representatividade.

### Migração de dados

Quando o slice mover ou transformar dados reais/canônicos, usar abordagem baseada em risco: identificar riscos de perda, truncamento, duplicação, alteração semântica, quebra referencial e irreversibilidade; associar cada risco a uma prova estática ou executada adequada. Dry-run, reconciliação e rollback/recuperação devem ser exigidos quando o impacto justificar.

## Evidência executada

- Resultado de CI/comando no commit corrente é evidência; descrição manual de que “está verde” não é fonte persistente de readiness.
- Runtime readiness é derivada dos checks aplicáveis ao commit/PR atual.
- Contagens de projetos, módulos, workflows, planos e versões detectáveis são geradas em `generated/repository-facts.md`.
- Não manter counters científicos ou inventários computáveis em `CURRENT-WORK`, `AGENTS.md` ou prompts.
- Se um número de performance virar requisito, registrar workload, ambiente, método e resultado do benchmark.

## Definition of Done

Uma mudança está pronta quando, conforme seu risco:

1. outcome e acceptance criterion foram satisfeitos;
2. checks relevantes passam no estado que será integrado;
3. self-review não encontrou mudança fora de escopo, segredo ou weakening de guardrail;
4. arquitetura/segurança/concurrency/migration foram verificadas quando afetadas;
5. docs canônicos refletem a nova verdade;
6. plano/estado/dívida foram atualizados quando necessário;
7. PR/CI está pronto para integração segundo `ENGINEERING.md`.

## Falhas

- Corrija a causa; não remova o check para obter verde.
- Diferencie falha de código, falha de teste e falha externa.
- Flake confirmado é dívida do sistema de verificação.
- Se um check não mede mais um requisito válido, altere o requisito e o check de forma explícita e rastreável.

## Harness

`python3 scripts/check-harness.py` valida, entre outros:

- `AGENTS.md` curto e com função de mapa;
- documentos/diretórios obrigatórios;
- links Markdown locais;
- freshness de estado/referências operacionais;
- forma mínima de execution plans;
- fatos gerados sincronizados com o repositório.

O gate do harness não substitui os gates de arquitetura, build, migration ou produto; ele garante que agentes consigam descobrir corretamente quais deles usar.

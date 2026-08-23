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

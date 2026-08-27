# Current work

Last verified: **2026-08-27**

Este arquivo é um snapshot curto do trabalho corrente. Não é histórico, changelog nem inventário de CI.

## Active outcome

Fechar o gap de consentimento explícito para alertas de Saved Search no public web: o backend já persiste `AlertEnabled`/`AlertEnabledAtUtc` e expõe `SetAlertEnabledAsync`, mas a experiência Buyer ainda não mostra nem aciona esse opt-in.

O slice tornará a preferência explicitamente **alerta por e-mail**, sem afirmar que delivery externo já está operacional. Provider, resolução/verificação do destinatário, retry e scheduler permanecem boundaries separados.

## Active plan

[`../exec-plans/active/0054-saved-search-email-opt-in.md`](../exec-plans/active/0054-saved-search-email-opt-in.md)

## Acceptance target

- client model reflete o estado de alerta já publicado pelo backend;
- Buyer habilita/desabilita alertas por e-mail em busca própria;
- estado da UI acompanha a resposta persistida;
- copy distingue preferência registrada de delivery efetivamente enviado;
- prova focada + Public Web Gate verdes no head exato.

## Próximos gatilhos independentes

- delivery de e-mail de Saved Search somente após consentimento explícito, destinatário verificável e estado durável/recovery do side effect;
- deployment/locking reproduzível para claim/retry/restart do runner de Saved Search;
- medição executável de `powertrain`/`transmission`/`body_style` no Podium para decidir projeção BPT2;
- enrichment técnico publicado suficiente para Comparator;
- corpus + baseline + métrica para discovery avançado;
- dataset/licença/metodologia/provenance para inteligência de mercado;
- evidência operacional suficiente para trust/moderação avançada;
- tese comercial/parceria concreta para complementares.

## Source of runtime truth

- Estado de branch/PR/checks: Git e GitHub Actions do commit corrente.
- Produto: [`../PRODUCT.md`](../PRODUCT.md).
- Fatos derivados: [`../generated/repository-facts.md`](../generated/repository-facts.md).
- Decisões: [`../MDV.md`](../MDV.md) e [`../adr/`](../adr/).
- Cobertura funcional: [`../audits/2026-08-27-unified-functional-coverage-matrix.md`](../audits/2026-08-27-unified-functional-coverage-matrix.md).
- Consumer contract técnico: [`../contracts/vehicle-technical-sheet-consumer-contract.md`](../contracts/vehicle-technical-sheet-consumer-contract.md).

## Open blockers

- Saved Search runner: sem distributed-lock provider/configuração e sem deployment contract cross-instance.
- Saved Search e-mail delivery: ainda sem destinatário verificado + durable delivery/recovery contract comprovado.
- Comparator/ficha técnica ampla: enrichment técnico publicado suficiente do Podium ainda não existe como consumer contract estável.
- Discovery avançado: sem corpus/baseline/métrica.
- Inteligência de mercado: sem dataset/licença/metodologia/provenance.
- Carros na Web: inventário público atual ainda não reproduzível; acesso direto continua falhando.

## Update rule

Atualize este snapshot somente quando mudar outcome, plano, acceptance target ou blocker real.

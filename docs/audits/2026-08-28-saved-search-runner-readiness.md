# Saved Search runner readiness audit — 2026-08-28

## Pergunta

O estado atual do BPT2 já fornece evidência suficiente para implementar automaticamente o runner de `SavedSearchAlertDetectionRequest` sem inventar uma topologia de deployment ou uma estratégia de locking?

## Resultado

**NÃO PASSA — BLOQUEADO.**

O repositório atual prova a necessidade de coordenação durável, mas não fixa as pré-condições operacionais necessárias para escolher com segurança a execução automática.

## Evidência do repositório

- `ARCHITECTURE.md` define que side effects externos exigem coordenação durável e que infraestrutura extra só entra com evidência de necessidade.
- ADR-0003 exige estado durável, idempotência, retry e coordenação explícita para efeitos externos.
- ADR-0010 exige avaliar soluções maduras antes de adotar ou construir nova infraestrutura como background jobs ou distributed locks.
- `main/BomPraTi/BomPraTi.csproj` não referencia `Volo.Abp.DistributedLocking` nem outro provider de distributed lock/background-job escolhido como decisão arquitetural do BPT2.
- O repositório não contém contrato de deployment que fixe single-instance, número de réplicas, executor dedicado ou política equivalente de exclusão mútua para o runner.
- A matriz funcional atual já classifica o runner automático como `BLOQUEADO` até existir contrato de deployment/claim/concurrency/retry/restart/locking.

## Evidência oficial ABP

Documentação oficial atual:

- Background Jobs: https://abp.io/docs/latest/framework/infrastructure/background-jobs
- Distributed Locking: https://abp.io/docs/latest/framework/infrastructure/distributed-locking

Pontos relevantes do contrato oficial:

- o Background Job Manager default usa distributed lock para coordenar execução em ambientes com múltiplas instâncias;
- o lock default é apenas in-process até que um provider realmente distribuído seja configurado;
- em cluster, a alternativa sem provider distribuído é garantir operacionalmente um único executor ou usar uma aplicação/worker dedicado;
- adicionar distributed locking/provider é uma decisão de infraestrutura, não uma propriedade que o BPT2 possa presumir a partir do framework.

## Decisão

`SAVED_SEARCH_AUTOMATIC_RUNNER = BLOQUEADO`

Motivo: falta uma decisão observável de deployment/executor e, em cenário multi-instância, falta provider real de distributed lock. O BPT2 não deve escolher Redis, Hangfire, Quartz, worker dedicado ou implementação customizada antes de conhecer as restrições reais de deployment e cumprir ADR-0010.

## O que desbloqueia

O próximo gate válido é um contrato operacional mínimo que responda, com evidência:

1. o host será executado como uma única instância, múltiplas réplicas ou haverá worker dedicado?
2. qual componente será autorizado a executar o runner?
3. qual é a política de claim/concurrency para evitar processamento simultâneo do mesmo request?
4. quais são as regras de retry, restart/recovery e idempotência observável?
5. se houver múltiplos executores possíveis, qual provider de distributed lock é escolhido após avaliação ADR-0010?

Somente depois disso cabe um execution plan de implementação.

## Não autorizado por este audit

- adicionar package/provider de distributed lock;
- introduzir Redis, Hangfire, Quartz, broker ou worker separado;
- implementar polling/runner automático;
- escolher frequência, batch size ou SLA por preferência;
- reclassificar external delivery como entregue.

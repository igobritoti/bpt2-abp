# Qualidade — definição de pronto e validação proporcional ao risco

## Princípio

Qualidade deve ser **verificável**. Documentação descreve intenção e regras; checks executáveis provam comportamento quando isso for possível.

Não rodar suites ou criar infraestrutura de teste por ritual. Rodar o conjunto mínimo que demonstra que a mudança não quebrou o fluxo relevante e que decisões caras continuam verdadeiras.

## Checks por tipo de mudança

| Mudança | Validação mínima esperada |
|---|---|
| documentação apenas | links/caminhos coerentes; nenhuma afirmação contradiz decisão/código conhecido |
| código de domínio/aplicação | build + teste focado do comportamento alterado |
| boundary/dependência modular | architecture checker + ataque negativo relevante |
| schema/persistência | migration gerável/aplicável + fresh database quando o baseline for afetado |
| auth/ownership | teste positivo + negativo de acesso indevido |
| visibilidade pública | teste de estado permitido + rejeição/invisibilidade de estado proibido |
| optimistic concurrency | update válido + tentativa stale rejeitada explicitamente |
| upload/media | casos válidos + input malformado/tipo declarado falso conforme risco |
| side effect externo | falha entre persistência e efeito + retry/idempotência/recuperação |
| bug corrigido | regressão que falhava antes e passa depois, quando economicamente viável |

## Gate 01 — regressões fundacionais

O Gate 01 já provou:

- boundaries arquiteturais;
- host ABP 10.6 + módulos + build;
- fresh PostgreSQL migration;
- Draft invisível ao público;
- ownership Seller A/B;
- optimistic concurrency por application service;
- rollback multi-módulo no mesmo PostgreSQL/ABP UoW.

Não é necessário rerodar todo o Gate 01 para qualquer alteração. Rerodar os checks afetados pelo risco da mudança. O CI completo pode continuar funcionando como rede adicional, mas não deve justificar testes irrelevantes no desenvolvimento local.

## Definition of Done

Uma mudança está pronta quando, conforme seu risco:

1. comportamento e critério de aceite estão claros;
2. build relevante passa;
3. testes focados relevantes passam;
4. boundary/security/concurrency/migration foram verificados quando afetados;
5. nenhuma decisão documentada foi contradita silenciosamente;
6. documentação/ADR/MDV foram atualizados se a verdade do projeto mudou;
7. dívida ou decisão aberta ficou explícita em vez de escondida em TODO ambíguo;
8. não há segredo novo ou artefato sensível versionado.

## Performance

- Não congelar SLA, throughput, latência ou volume por estimativa sem medição/requisito real.
- Benchmark deve representar workload do BPT e registrar ambiente/entrada/resultado.
- Engine de busca externo, cache distribuído e outras otimizações só entram quando benchmark/requisito demonstrar necessidade.

## Falhas de CI

- Corrigir a causa; não remover o check para obter verde sem uma decisão explícita.
- Diferenciar falha do código, falha do teste e falha de infraestrutura.
- Flake confirmado deve ser tratado como defeito do sistema de verificação, não como evidência de comportamento de produto.

## Evidência

Resultados executados no CI do BPT2 podem ser classificados como evidência B quando reproduzem diretamente o comportamento em questão. Capacidade documentada sem teste específico continua sendo evidência de mecanismo, não necessariamente decisão de adoção.

# Lead attribution readiness — BPT2

Data: 2026-08-27

Status: decisão de prontidão; não autoriza implementação.

## Pergunta

Existe evidência suficiente para promover attribution mínima de marketing (`source` / `medium` / `campaign` ou equivalente) para `Lead` como próximo slice funcional?

## Evidência observada

O `Lead` atual registra apenas:

- `ListingId`;
- `UserId?` quando há sessão Buyer válida;
- `Channel`;
- `CreatedAtUtc`;
- `ContactedAtUtc?`;
- `ClosedAtUtc?`;
- `Outcome?`.

Não há hoje contrato de `source`, `medium`, `campaign`, referrer, click id ou taxonomia equivalente no domínio Marketplace.

O produto já preserva a atribuição de identidade Buyer quando existe sessão autenticada e mantém `Channel` para o contato. Isso responde quem iniciou o Lead e por qual canal de contato, mas não responde uma pergunta de aquisição de marketing.

A matriz funcional anterior marcava attribution como `GAP REAL`, condicionada a uma pergunta concreta de aquisição + privacy contract.

## Teste de prontidão

Para transformar attribution em slice implementável, as seguintes perguntas precisam ter respostas falsificáveis antes de schema/UI:

1. Qual pergunta operacional será respondida?
2. Qual é a taxonomia mínima e sua autoridade?
3. O que acontece quando parâmetros estão ausentes, conflitantes ou manipulados pelo cliente?
4. Qual dado precisa ser persistido versus apenas agregado/telemetria?
5. Qual política de retenção/privacidade se aplica a referrer, click ids ou outros identificadores externos?
6. Attribution será first-touch, last-touch ou apenas contexto do evento de Lead?
7. Como o dado será consumido operacionalmente?

## Resultado

**NÃO PASSA PARA IMPLEMENTAÇÃO AGORA.**

A ausência técnica existe, mas não há déficit de produto comprovado nem pergunta operacional concreta que permita desenhar o menor contrato correto. Portanto o estado mais preciso é **ADIADO**, não `GAP REAL` elegível.

Isso evita:

- importar a taxonomia do BPT1 por paridade histórica;
- persistir parâmetros UTM arbitrários sem consumidor;
- transformar dados controlados pelo cliente em verdade de domínio;
- criar retenção de identificadores/referrers sem necessidade definida;
- ampliar schema antes de uma hipótese mensurável.

## Próximo gatilho válido

Reabrir somente quando existir ao menos uma pergunta de aquisição concreta com consumidor identificado. Nesse momento, definir antes do código:

`pergunta → evento/atribuição desejada → taxonomia mínima → trust boundary → retenção/privacy → teste de aceite`

## Decisão

- `LEAD_MARKETING_ATTRIBUTION_NOW = ADIADO`
- `UTM_FIELDS_AS_DOMAIN_BY_DEFAULT = NÃO AUTORIZADO`
- `CLIENT_SUPPLIED_ATTRIBUTION_AS_TRUTH = NÃO AUTORIZADO`
- `NEXT_TRIGGER = PERGUNTA CONCRETA DE AQUISIÇÃO + CONSUMIDOR + PRIVACY/RETENTION CONTRACT`

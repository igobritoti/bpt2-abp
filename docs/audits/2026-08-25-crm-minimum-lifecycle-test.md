# CRM / Lead lifecycle — minimum-state test

Data: 2026-08-25

Status: auditoria do Plan 0046; não autoriza mudança de domínio ainda.

## Pergunta

O BPT2 precisa transplantar o pipeline BPT1 de cinco estados (`NOVO`, `CONTATADO`, `NEGOCIACAO`, `VENDIDO`, `PERDIDO`) para ganhar utilidade operacional real?

## Evidência donor

O BPT1 possui enum/pipeline com cinco estados e timestamps de contacted/negotiation/won/lost/closed.

Porém, o serviço Seller encontrado no donor restringe atualização do Seller a:

- `CONTATADO`;
- `VENDIDO`.

O fluxo genérico/admin consegue representar mais estados, mas a própria fronteira Seller do donor não prova que `NEGOCIACAO` e `PERDIDO` sejam necessários no primeiro contrato operacional do vendedor.

## Evidência BPT2

O BPT2 já possui:

- Lead persistido antes do redirect de WhatsApp;
- ownership Seller server-side;
- `CreatedAtUtc`;
- `ContactedAtUtc?`;
- `MarkContacted()` monotônico e idempotente;
- histórico do Lead preservado mesmo após Listing deixar de ser público.

O problema atual não é ausência total de CRM; é saber qual próximo estado gera decisão operacional útil.

## Hipóteses concorrentes

### H1 — copiar cinco estados

`Novo → Contatado → Negociação → Vendido/Perdido`

Vantagem: mais granularidade.

Risco: estados sem ação/critério claro, reversões e métricas artificiais.

### H2 — lifecycle mínimo com fechamento

Manter `ContactedAtUtc` e acrescentar apenas conceito de fechamento + resultado, por exemplo:

- aberto/não contatado;
- aberto/contatado;
- fechado com outcome explícito (`Won`/`Lost`).

A forma concreta pode ser timestamps/outcome e não necessariamente um enum de status.

Vantagem: mede atendimento e conversão sem inventar estágio intermediário.

### H3 — apenas Won inicialmente

Adicionar somente marcação de venda ganha.

Vantagem: menor mudança.

Risco: Leads sem interesse não têm forma explícita de sair da fila operacional.

## Resultado atual

**REPROVADO copiar cinco estados por evidência insuficiente.**

A evidência do donor favorece testar H2 antes: o Seller do próprio BPT1 não precisava da superfície completa de cinco estados para suas mutações principais.

## Recomendação proativa

Classificação: **EDITAR/SIMPLIFICAR**.

Primeiro contrato candidato deve ser orientado às perguntas operacionais:

1. este Lead já foi contatado?
2. ainda exige ação?
3. foi fechado?
4. qual foi o resultado do fechamento?

`NEGOCIACAO` só deve entrar se existir uma ação, fila, SLA ou decisão do Seller que dependa desse estágio.

## Testes antes do slice funcional

- ownership: somente Seller dono do Listing altera lifecycle;
- `MarkContacted` permanece idempotente;
- fechamento repetido com mesmo outcome é idempotente;
- outcome conflitante não pode sobrescrever silenciosamente histórico;
- definir explicitamente se reabrir é permitido; default do teste é não permitir;
- Leads históricos continuam visíveis após Pause/Archive do Listing;
- fila `precisa de ação` deve ser derivável deterministicamente;
- conversion rate `won / closed` e contact rate `contacted / total` devem ser calculáveis sem estado `NEGOCIACAO`;
- nenhuma attribution de marketing precisa entrar no agregado para provar o lifecycle operacional.

## Critério que promoveria `NEGOCIACAO`

Somente adicionar o estágio quando houver pelo menos uma necessidade reproduzível, como:

- fila Seller específica de negociações em andamento;
- SLA/follow-up diferente de Lead apenas contatado;
- ação/automação condicionada ao estágio;
- métrica de produto cuja decisão não possa ser respondida por contact/close/outcome.

Até lá, `NEGOCIACAO` permanece complexidade não promovida.

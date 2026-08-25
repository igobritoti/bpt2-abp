# Plan 0047 — Minimal Lead closing

Status: **CONCLUÍDO**

## Objetivo

Fechar o menor gap operacional de CRM promovido pelo Plan 0046: permitir que o Seller encerre um Lead próprio com resultado explícito `Won` ou `Lost`, preservando o estado mínimo já comprovado de contato e sem transplantar o pipeline de cinco estados do BPT1.

## Base congelada

- branch criada de `main` em `4a5e1d75aeddfb21412dbef4cb614fe4b6af78e8`;
- Plan 0046 concluído e integrado pelo PR #66;
- `Lead` anterior possuía `CreatedAtUtc` e `ContactedAtUtc?`;
- `MarkContacted()` já era monotônico/idempotente;
- `ISellerLeadCommandService` expunha apenas `MarkContactedAsync`;
- `SellerLeadDto` ainda não representava fechamento/outcome.

## Problema

O Seller conseguia registrar que um Lead foi atendido, mas não conseguia representar deterministicamente que o trabalho terminou nem o resultado do fechamento. Isso impedia distinguir Leads ainda acionáveis de Leads encerrados e impedia medir fechamento sem inventar um pipeline mais complexo.

## Hipótese falsificável

> Acrescentar apenas fechamento + outcome `Won/Lost` é suficiente para representar o lifecycle operacional imediato do Seller, mantendo ownership e idempotência e sem exigir `NEGOCIACAO`, notes, attribution, dashboard ou automação.

## Escopo entregue

1. `LeadOutcome` contém somente `Won` e `Lost`;
2. `Lead` persiste `ClosedAtUtc?` e `Outcome?`;
3. `MarkContacted` foi preservado monotônico/idempotente;
4. Seller dono do Listing pode fechar Lead como `Won` ou `Lost`;
5. repetição do mesmo fechamento é idempotente e preserva timestamp;
6. outcome conflitante é rejeitado deterministicamente;
7. `SellerLeadDto` e UI Seller expõem fechamento/outcome;
8. Lead continua visível no histórico após Archive do Listing;
9. ownership continua aplicado server-side pelo boundary Seller existente;
10. fixture/smoke HTTP existente foi estendido em vez de criar novo framework de teste.

## Não escopo preservado

- estado `NEGOCIACAO`;
- pipeline genérico de cinco estados;
- reabertura de Lead;
- notas/comentários/follow-up;
- attribution de marketing;
- analytics/dashboard;
- automações ou notificações;
- alteração de Buyer/contact flow;
- CRM/admin novo.

## Critérios de aceite

Um Seller autenticado consegue, somente sobre Leads dos próprios Listings:

1. manter `MarkContacted` monotônico/idempotente;
2. fechar Lead com outcome `Won` ou `Lost`;
3. repetir exatamente o mesmo fechamento sem duplicar efeito nem alterar timestamps;
4. receber erro determinístico ao tentar outcome conflitante depois de fechado;
5. não fechar Lead de outro Seller;
6. ler `ClosedAtUtc?` e outcome no histórico Seller;
7. continuar lendo Lead fechado quando o Listing estiver Archived;
8. derivar `needs action` como Lead ainda não fechado e métricas simples de contacted/closed/won sem estado `NEGOCIACAO`.

## Checkpoints

- [x] CP1 — contrato/domínio mínimo definido;
- [x] CP2 — persistência/fresh migration consistente;
- [x] CP3 — command/read Seller com ownership e idempotência comprovados por HTTP;
- [x] CP4 — superfície Seller necessária atualizada sem ampliar escopo;
- [x] CP5 — docs/fatos derivados reconciliados;
- [x] CP6 — evidência funcional crítica verde; fechamento documental iniciado antes do CI final/review/merge.

## Decision log

- outcome inicial contém somente `Won` e `Lost`;
- Lead fechado não reabre neste slice;
- conflito de outcome não é last-write-wins;
- fechamento não marca contato implicitamente porque contato e outcome são fatos distintos;
- ownership continua sendo aplicado pelo boundary Seller existente via Listing do Seller;
- `NEGOCIACAO` só poderá ser promovido futuramente com ação/SLA/fila real que dependa desse estágio;
- facts de domínio não dependem de analytics events;
- o Seller Shell HTTP smoke existente foi estendido em vez de criar um novo framework de teste.

## Progress log

- 2026-08-25 — branch `feat/minimal-lead-closing` criada do `main` integrado pelo PR #66 e draft PR #67 aberto.
- 2026-08-25 — domínio/contrato implementados com `LeadOutcome`, `ClosedAtUtc`, fechamento idempotente e conflito determinístico.
- 2026-08-25 — leitura e UI Seller atualizadas para estados `Novo`, `Atendido` e `Fechado` com `Won/Lost`.
- 2026-08-25 — fixture e Seller Shell HTTP smoke estendidos para contato idempotente, fechamento idempotente, conflito, histórico após Archive e ownership.
- 2026-08-25 — Harness Gate #458 falhou somente por headings canônicos ausentes; plano normalizado e Harness Gate #459 passou no head `d12dec4455422964d8b526f43fce409faef10823`.
- 2026-08-25 — Architecture, Host, Seller Auth e Public Web passaram no mesmo head; Seller Auth incluiu geração/aplicação de fresh migrations.
- 2026-08-25 — Fresh Migration Gate #205 passou no mesmo head.
- 2026-08-25 — Seller Shell HTTP Gate #286 passou no mesmo head, incluindo o smoke estendido de Lead.
- 2026-08-25 — plano arquivado; o próximo passo do PR é CI final fresco no head documental, review/base refresh e merge somente verde.

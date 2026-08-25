# Plan 0047 — Minimal Lead closing

Status: **ATIVO**

## Outcome

Fechar o menor gap operacional de CRM promovido pelo Plan 0046: permitir que o Seller encerre um Lead próprio com resultado explícito `Won` ou `Lost`, preservando o estado mínimo já comprovado de contato e sem transplantar o pipeline de cinco estados do BPT1.

## Base congelada

- branch criada de `main` em `4a5e1d75aeddfb21412dbef4cb614fe4b6af78e8`;
- Plan 0046 concluído e integrado pelo PR #66;
- `Lead` atual possui `CreatedAtUtc` e `ContactedAtUtc?`;
- `MarkContacted()` é monotônico/idempotente;
- `ISellerLeadCommandService` expõe apenas `MarkContactedAsync`;
- `SellerLeadDto` expõe `ContactedAtUtc?` e ainda não representa fechamento/outcome.

## Problema

O Seller consegue registrar que um Lead foi atendido, mas não consegue representar deterministicamente que o trabalho terminou nem o resultado do fechamento. Isso impede distinguir Leads ainda acionáveis de Leads encerrados e impede calcular conversão de fechamento sem inventar um pipeline mais complexo.

## Hipótese falsificável

> Acrescentar apenas fechamento + outcome `Won/Lost` é suficiente para representar o lifecycle operacional imediato do Seller, mantendo ownership e idempotência e sem exigir `NEGOCIACAO`, notes, attribution, dashboard ou automação.

## Escopo

1. modelar o menor contrato de outcome/fechamento no Marketplace;
2. preservar `MarkContacted` atual;
3. permitir Seller dono do Listing fechar Lead como `Won` ou `Lost`;
4. tornar repetição do mesmo fechamento idempotente;
5. rejeitar alteração silenciosa para outcome conflitante;
6. expor fechamento/outcome na leitura Seller necessária para a UI/operação;
7. preservar histórico de Lead após Pause/Archive;
8. adicionar somente migration/testes/checks necessários ao risco real.

## Não escopo

- estado `NEGOCIACAO`;
- pipeline genérico de cinco estados;
- reabertura de Lead;
- notas/comentários/follow-up;
- attribution de marketing;
- analytics/dashboard;
- automações ou notificações;
- alteração de Buyer/contact flow;
- CRM/admin novo.

## Acceptance criteria

Um Seller autenticado consegue, somente sobre Leads dos próprios Listings:

1. manter `MarkContacted` monotônico/idempotente;
2. fechar Lead com outcome `Won` ou `Lost`;
3. repetir exatamente o mesmo fechamento sem duplicar efeito nem alterar timestamps;
4. receber erro determinístico ao tentar outcome conflitante depois de fechado;
5. não fechar Lead de outro Seller;
6. ler `ClosedAtUtc?` e outcome no histórico Seller;
7. continuar lendo Lead fechado quando o Listing estiver Paused/Archived;
8. derivar `needs action` como Lead ainda não fechado e métricas simples de contacted/closed/won sem estado `NEGOCIACAO`.

## Estratégia de testes

Executar só os gates necessários:

- testes de domínio para fechamento/idempotência/conflito;
- teste de application/service para ownership, se já houver harness focal reutilizável;
- migration/fresh migration apenas se schema persistido mudar;
- Seller HTTP gate somente se a superfície HTTP correspondente for alterada e o gate existente cobrir o caminho;
- harness gate para docs/fatos derivados.

Quando um gate falhar, investigar um por vez.

## Checkpoints

- [ ] CP1 — contrato/domínio mínimo definido e testado.
- [ ] CP2 — persistência/migration consistente.
- [ ] CP3 — command/read Seller com ownership e idempotência comprovados.
- [ ] CP4 — superfície Seller necessária atualizada sem ampliar escopo.
- [ ] CP5 — docs/fatos derivados reconciliados.
- [ ] CP6 — CI final fresco, review/base refresh e merge somente verde.

## Decisões congeladas

- outcome inicial contém somente `Won` e `Lost`;
- Lead fechado não reabre neste slice;
- conflito de outcome não é last-write-wins;
- `NEGOCIACAO` só poderá ser promovido futuramente com ação/SLA/fila real que dependa desse estágio;
- facts de domínio não dependerão de analytics events.

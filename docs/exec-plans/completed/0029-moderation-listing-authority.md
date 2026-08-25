# Execution Plan 0029 — Moderation Listing Authority

Status: **COMPLETO**

## Objetivo

Fechar o blocker `MVP-02` com uma autoridade administrativa explícita para retirar e restaurar a visibilidade de um Listing denunciado sem permitir que o Seller desfaça a decisão de moderação.

Outcome vertical comprovado:

`Buyer report → admin withdraw → Listing Moderated → invisível publicamente → Seller bloqueado → admin restore → Published`

## Contexto congelado

- Base original: `main` em `600342ea67aec05a4079dea2a574d0a17292a28c`, merge do Plan 0028.
- Durante o fechamento, `main` avançou para `8c3f75fd0877ce7bbc5210ea53663131c3261b8a` pelo merge do PR #1; o refresh foi incorporado em `c96b86cef1b4f453507c76cee4923e1a3ede3576` sem alterar o boundary funcional deste slice.
- `ListingVisibility` considera público somente `ListingStatus.Published`.
- `Paused` permanece pausa voluntária do Seller; `Moderated` representa retirada administrativa.
- `ListingStatus` é persistido como enum inteiro; o novo estado não exigiu alteração de schema.

## Escopo entregue

- estado `Moderated` no lifecycle persistido;
- transições de domínio explícitas `Published → Moderated → Published` reservadas à moderação;
- bloqueio de mutações Seller enquanto `Moderated`;
- contrato/serviço admin-only separado do `IListingCommandService` Seller;
- ações Retirar/Restaurar na página `/moderacao`;
- smoke HTTP focal para autorização, retirada, invisibilidade pública, bloqueio Seller, restauração e retorno à visibilidade;
- workflow focal dedicado.

## Fora de escopo preservado

- resolução/fechamento de report;
- motivo administrativo, notas internas ou trilha de auditoria adicional;
- automação de moderação;
- alteração da política de report;
- suspensão de usuário/Seller;
- nova migration ou coluna de banco.

## Critérios de aceite

1. [x] somente `admin` executa withdraw/restore;
2. [x] withdraw de Listing `Published` muda status para `Moderated`;
3. [x] Listing `Moderated` desaparece de detalhe/listagem públicos;
4. [x] Seller não consegue publicar nem editar o Listing enquanto `Moderated`;
5. [x] admin restaura `Moderated` para `Published`;
6. [x] Listing restaurado volta à descoberta pública;
7. [x] `/moderacao` expõe ações coerentes com o estado sem revelar PII Buyer;
8. [x] nenhum schema/migration novo foi necessário;
9. [x] gate focal e regressões aplicáveis ficaram verdes no head funcional integrado.

## Evidência executada

- `BPT2 Moderation Listing Authority HTTP Gate` run `32813359877`: **success** no head funcional `67fe3724d9b87c0bc8b2d5753fb27bcc739bbf00`.
- O gate focal comprovou banco fresco, seed Identity/OpenIddict, fixture canônica, boundary admin-only, `Published → Moderated`, invisibilidade pública, bloqueio de publish/update Seller, inbox sem PII, página operacional, `Moderated → Published` e retorno ao público.
- No mesmo head funcional ficaram verdes Architecture, Harness, Host, Gate 01, Fresh Migration, Listing Lifecycle, Listing Photo, Seller Draft/Edit, Seller Auth, Seller Shell, Seller Photos Publish, Admin Canonical Catalog, Public Discovery, Public Buyer, Buyer Favorites e Product API.
- A primeira execução focal falhou somente por uma expectativa incorreta do smoke sobre a rota de update; o Swagger mostrou o contrato existente `PUT /api/app/listing-command?listingId=...`, o smoke foi alinhado e a segunda execução passou sem mudança no código de produto.

## Resultado

O blocker `MVP-02` da auditoria 0027 está resolvido. Junto com o Plan 0028, não resta blocker funcional classificado como `BLOQUEIA MVP` naquela auditoria. Os demais gaps permanecem pós-MVP até nova evidência alterar essa classificação.

## Decision log

- **DECIDIDO:** `Moderated` é estado distinto de `Paused`.
- **DECIDIDO:** withdraw aceita `Published`; restore aceita `Moderated` e retorna a `Published`.
- **DECIDIDO:** o Seller não pode editar/publicar/pausar um Listing `Moderated`; a restauração pertence ao boundary admin.
- **DECIDIDO:** não foi criada coluna/flag separada porque o estado discreto satisfez a prova funcional sem perda da semântica MVP.
- **DECIDIDO por evidência:** com MVP-01 e MVP-02 resolvidos, a auditoria 0027 não contém blocker funcional restante.

## Progress log

- 2026-08-25: PR #47 / Plan 0028 mergeado; `main` refetchado em `600342ea67aec05a4079dea2a574d0a17292a28c`.
- 2026-08-25: confirmado que `Paused` não serve como autoridade de moderação porque o Seller poderia voltar a `Published`.
- 2026-08-25: domínio, serviço admin-only, UI, smoke e workflow focal implementados.
- 2026-08-25: focal corrigido uma única vez por divergência de rota do próprio smoke; produto permaneceu inalterado.
- 2026-08-25: gate focal e todas as regressões aplicáveis concluíram com sucesso no head funcional `67fe3724d9b87c0bc8b2d5753fb27bcc739bbf00`.
- 2026-08-25: `main` avançou por PR externo; base refresh incorporado em merge commit `c96b86cef1b4f453507c76cee4923e1a3ede3576` antes do fechamento documental final.

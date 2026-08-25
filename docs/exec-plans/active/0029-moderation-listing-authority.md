# Execution Plan 0029 — Moderation Listing Authority

Status: **ATIVO**

## Objetivo

Fechar o blocker `MVP-02` com uma autoridade administrativa explícita para retirar e restaurar a visibilidade de um Listing denunciado sem permitir que o Seller desfaça a decisão de moderação.

Outcome vertical:

`Buyer report → admin withdraw → Listing Moderated → invisível publicamente → Seller bloqueado → admin restore → Published`

## Contexto congelado

- Base: `main` em `600342ea67aec05a4079dea2a574d0a17292a28c`, merge do Plan 0028.
- `ListingVisibility` considera público somente `ListingStatus.Published`.
- `Listing.Publish()` hoje permite republicar qualquer estado não `Archived`; por isso `Paused` não representa autoridade de moderação.
- `/moderacao` já é admin-only e mostra a fila de reports, mas é somente leitura.
- `ListingStatus` é persistido como enum inteiro; adicionar um novo valor não exige alteração de schema.

## Escopo

- adicionar estado `Moderated` ao lifecycle persistido;
- transições de domínio explícitas `Published → Moderated → Published` reservadas à moderação;
- impedir mutações Seller que possam desfazer/modificar Listing enquanto `Moderated`;
- contrato/serviço admin-only separado do `IListingCommandService` Seller;
- ações Retirar/Restaurar na página `/moderacao`;
- smoke HTTP focal que prova autorização, retirada, invisibilidade pública, bloqueio Seller, restauração e visibilidade pública recuperada;
- workflow focal e documentação final.

## Não escopo

- resolução/fechamento de report;
- motivo administrativo, notas internas ou trilha de auditoria adicional;
- automação de moderação;
- alteração da política de report;
- suspensão de usuário/Seller;
- nova migration ou coluna de banco.

## Critérios de aceite

1. [ ] somente `admin` executa withdraw/restore;
2. [ ] withdraw de Listing `Published` muda status para `Moderated`;
3. [ ] Listing `Moderated` desaparece de detalhe/listagem públicos;
4. [ ] Seller não consegue publicar nem editar o Listing enquanto `Moderated`;
5. [ ] admin restaura `Moderated` para `Published`;
6. [ ] Listing restaurado volta à descoberta pública;
7. [ ] `/moderacao` expõe ações coerentes com o estado sem revelar PII Buyer;
8. [ ] nenhum schema/migration novo é necessário;
9. [ ] gate focal e regressões aplicáveis ficam verdes no head integrado.

## Checkpoints

1. [x] evidência e representação de estado definidas;
2. [ ] domínio + contrato + serviço admin;
3. [ ] página operacional;
4. [ ] smoke/workflow focal;
5. [ ] documentação final, CI fresco, review e merge.

## Progress log

- 2026-08-25: PR #47 / Plan 0028 mergeado; `main` refetchado em `600342ea67aec05a4079dea2a574d0a17292a28c`.
- 2026-08-25: confirmado que `Paused` não é autoridade de moderação porque `Publish()` atual permite Seller voltar a `Published`.
- 2026-08-25: confirmado que visibilidade pública é exatamente `Status == Published`, permitindo `Moderated` sem mudança de query pública.

## Decision log

- **DECIDIDO:** `Moderated` será um estado distinto de `Paused`.
- **DECIDIDO:** withdraw só aceita `Published`; restore só aceita `Moderated` e retorna a `Published`.
- **DECIDIDO:** o Seller não pode editar/publicar/pausar um Listing `Moderated`; a restauração pertence ao boundary admin.
- **DECIDIDO:** não será criada coluna/flag separada enquanto o estado discreto satisfizer a prova funcional sem perda de semântica do MVP.

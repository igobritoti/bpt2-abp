# Execution Plan 0011 — Buyer Listing Report

Status: **ATIVO**

## Objetivo

Abrir a primeira fatia real de moderação permitindo que um Buyer autenticado sinalize um Listing atualmente público, com persistência server-side e sem política de moderação prematura.

Fluxo:

`Public Listing → Buyer autenticado → sinalizar anúncio → sinal persistido`

## Evidência que abre o slice

- `docs/PRODUCT.md` mantém moderação como capacidade central ainda não implementada.
- Os ciclos públicos, Buyer, Seller e Lead já estão comprovados.
- Marketplace já possui identidade Buyer por `ICurrentUser` e autoridade de visibilidade pública por `IPublicListingQuery`.

## Escopo

- `ListingReport` no Marketplace com `UserId`, `ListingId` e `CreatedAtUtc`.
- Um único sinal por Buyer+Listing.
- criação permitida somente para Listing atualmente público;
- ownership do sinal derivado de `ICurrentUser`, sem `UserId` enviado pelo cliente;
- estado consultável pelo próprio Buyer;
- ação no detalhe público reutilizando a sessão `BomPraTi_BuyerWeb`;
- prova HTTP real no gate Buyer existente.

## Fora de escopo

- motivo/taxonomia de denúncia;
- texto livre;
- painel ou fila administrativa;
- remoção/suspensão automática de Listing;
- scoring, threshold, rate limiting distribuído ou jobs;
- resolução de perfil/PII do Buyer;
- notificação ao Seller.

## Critérios de aceite

- [ ] rota convencional de report existe e exige autenticação;
- [ ] Draft/private não pode ser reportado;
- [ ] report de Listing público persiste;
- [ ] repetição pelo mesmo Buyer é idempotente;
- [ ] outro Buyer não herda o estado do primeiro;
- [ ] sinal persistido continua registrado após o Listing deixar de ser público;
- [ ] Public Web compila com a ação de sinalizar;
- [ ] todos os workflows aplicáveis ficam verdes.

## Progress log

- 2026-08-23: slice aberto a partir do menor gap central ainda ausente: moderação.
- 2026-08-23: implementados aggregate, service, UI e smoke HTTP; aguardando evidência de CI.
- 2026-08-23: primeiro Harness Gate falhou apenas por formato obrigatório deste plan; produto não foi alterado por essa falha.
- 2026-08-23: o primeiro smoke funcional observou no Swagger a rota ABP `POST /api/app/listing-report/report/{listingId}`; cliente e teste foram alinhados à rota convencional sem controller customizado nem alteração de domínio.

## Decision log

- 2026-08-23: o primeiro sinal de moderação não recebe motivo nem efeito automático. Isso evita elevar preferências de taxonomia/política a requisito antes de existir evidência operacional.
- 2026-08-23: o sinal é autenticado, pertence ao `ICurrentUser` e é idempotente por Buyer+Listing.
- 2026-08-23: criação exige Listing atualmente público; sinal já persistido é histórico e não é apagado quando a publicação muda.

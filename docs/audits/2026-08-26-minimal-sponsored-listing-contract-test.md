# Teste de contrato — promoção mínima de Listing patrocinada

Data: 2026-08-26
Plano: 0049 — Bloco D
Status: **EM TESTE**

## Objetivo

Provar o menor contrato de promoção patrocinada que possa existir no Bom Pra Ti sem alterar silenciosamente o ranking orgânico da busca pública.

## Evidência BPT2 observada

- `PublicListingQuery` filtra apenas Listings públicas e aplica ordenação orgânica por `Id`, `price-asc` ou `price-desc`.
- Não existe hoje conceito publicado de sponsorship/promotion na Listing ou no `PublicListingDto`.
- O Plan 0049 exige que sponsored seja separado de ranking orgânico, identificado visualmente e temporalmente elegível antes de ampliar comercialização.

## Hipóteses falsificáveis

P1. Uma promoção deve ser estado separado da identidade/lifecycle orgânico da Listing.

P2. Ativar promoção não pode modificar `OrderListings` nem promover uma Listing para cima da lista orgânica.

P3. Só uma Listing pública pode ser apresentada como patrocinada; Draft/Paused/Archived/Hidden continuam fora da superfície pública independentemente de promoção.

P4. O intervalo de promoção deve ser explícito (`StartsAtUtc`, `EndsAtUtc`) e só é ativo quando `StartsAtUtc <= now < EndsAtUtc`.

P5. A superfície pública deve expor sponsorship de forma inequívoca para que a UI possa rotular `Patrocinado`.

P6. Promoção expirada ou futura deve ser tratada como não patrocinada sem apagar o registro histórico.

P7. Billing, plano comercial, auction, score, boost orgânico, impressão, click e Lead attribution não entram neste slice.

## Modelo mínimo candidato

`ListingPromotion`

- `Id`
- `ListingId`
- `StartsAtUtc`
- `EndsAtUtc`
- `CreatedAtUtc`

Invariantes:

- `EndsAtUtc > StartsAtUtc`;
- no máximo uma promoção ativa por Listing no instante observado;
- promoção não muda `Listing.Status`;
- consulta orgânica não ordena por promoção;
- DTO público deriva `IsSponsored` somente de promoção ativa + Listing pública.

## Casos mínimos

1. Listing pública sem promoção → `IsSponsored=false`.
2. Promoção futura → `IsSponsored=false`.
3. Promoção ativa → `IsSponsored=true`.
4. Promoção expirada → `IsSponsored=false`.
5. Listing não pública com promoção ativa → não aparece na busca pública.
6. Duas Listings com ordem orgânica conhecida mantêm a mesma ordem antes/depois de ativar promoção em uma delas.
7. `price-asc` e `price-desc` permanecem invariantes com promoção ativa.
8. UI pública renderiza rótulo explícito `Patrocinado` somente para `IsSponsored=true`.
9. Nenhum `HighlightScore`, sponsored-first ou fallback implícito é introduzido.

## Critério de decisão

**PASSA** se os casos 1–9 forem reproduzidos sem alterar o ranking orgânico.

**NÃO PASSA** se sponsorship for implementado como score/rank oculto, se Listing privada puder ser exibida, se janela temporal for ambígua ou se a UI não distinguir conteúdo patrocinado.

## Ainda não decidido

- quem pode ativar promoção em produção;
- preço/plano/créditos/pagamento;
- prioridade entre múltiplos formatos patrocinados;
- inventário/slot específico de sponsored;
- impressão/click/Lead attribution;
- regras comerciais e moderação adicionais.

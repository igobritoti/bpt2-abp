# Contrato mínimo — histórico de preço de Listing publicada

Data: 2026-08-26
Plano: 0049 / Bloco C3
Status: **PASSA para histórico; price-drop delivery continua pendente**

## Problema

O BPT2 permite alterar `Listing.Price`, inclusive quando a Listing está `Published`, mas antes deste slice preservava apenas o valor atual. Sem transição anterior→novo não existe base confiável para detectar price-drop sem inventar histórico.

## Contrato decidido

1. Uma edição de preço enquanto a Listing ainda é `Draft` não é histórico de preço de mercado e não gera registro.
2. Se a Listing já estava `Published` e o preço muda, persistir uma `ListingPriceChange` com:
   - `ListingId`;
   - `PreviousPrice`;
   - `NewPrice`;
   - `ChangedAtUtc` em UTC.
3. Update com preço idêntico não cria registro.
4. O histórico é evidência de transição de preço pedido da Listing; não representa preço de transação nem valor de mercado.
5. Nenhum provider, canal, template, Favorite notification ou policy de threshold entra neste slice.

## Prova executável

O Seller Draft/Edit HTTP gate cobre a mesma Listing ao longo do lifecycle:

- cria Draft em `148500`;
- edita Draft para `149900` e comprova zero histórico;
- publica a Listing;
- reduz preço publicado para `139900` e comprova exatamente `149900.00>139900.00`;
- repete update com `139900` e comprova que não surge segunda transição;
- preserva ownership e optimistic concurrency já existentes.

Na rodada do head `e339cde2d426df5351684f67300f0550cabe249d`, o `BPT2 Seller Draft Edit HTTP Gate` passou integralmente, e o `BPT2 Fresh Migration Gate` também passou.

## Resultado epistemológico

- **A/B:** o domínio atual aceita update de Listing publicada e o gate HTTP reproduz a transição persistida.
- **DECIDIDO:** histórico mínimo de preço pedido passa a ser persistido somente para Listings já publicadas.
- **NÃO DECIDIDO:** o que constitui price-drop notificável (qualquer redução vs threshold), canal/provider, frequência, digest e política de unsubscribe específica de price-drop.

## Próxima boundary de C3

Com histórico confiável disponível, um próximo slice pode testar detecção de queda para Favorites/Buyer separadamente do delivery. Ele deve provar temporal eligibility, dedup e comportamento para pause/archive/moderação antes de escolher provider.

# Execution Plan 0022 — Public Seller Hub

Status: **ATIVO**

## Objetivo

Fechar o menor gap público comprovado após o Plan 0021, transformando o Seller já projetado no detalhe em um destino navegável baseado exclusivamente em Listings públicos:

`Public Listing → Seller exibido → /vendedores/{sellerId} → anúncios públicos desse Seller`

## Evidência de partida

- `PublicListingDto` já projeta `SellerId`, `DisplayName` e `WhatsAppNumber` via `Sellers.Contracts`.
- O detalhe público já exibe o `DisplayName` do Seller, mas não oferece destino para conhecer os outros anúncios públicos desse vendedor.
- `PublicListingSearchInput` já concentra os filtros públicos e `PublicListingQuery` já aplica `ListingVisibility.PublicOnly` antes de qualquer filtro.
- `ISellerPublicReader.GetAsync/GetManyAsync` e a projeção pública existente demonstram que nenhuma nova entidade/perfil público é necessária para esta fatia.
- Sort exigiria escolher sem evidência uma semântica de ordenação; metadata da home é acabamento menor, mas não fecha um loop de navegação de produto.

Classificação inicial:

- **PASSA:** SellerId/nome já chegam à projeção pública e Listing publicável já é a autoridade de visibilidade.
- **NÃO PASSA:** Seller exibido no detalhe não possui vitrine pública navegável.
- **DECIDIDO:** o primeiro Seller Hub é derivado somente de Listings atualmente públicos do Seller.
- **NÃO DECIDIDO:** reputação, avaliações, selo/verificação, endereço, perfil editorial, estoque total privado, slug semântico, contato genérico e analytics do Seller.

## Escopo

- adicionar `SellerId` ao contrato de busca pública de Listings;
- aplicar filtro server-side por `Listing.SellerId`, mantendo `ListingVisibility.PublicOnly` como autoridade;
- serializar `SellerId` no cliente HTTP do public web;
- criar `/vendedores/{sellerId}` no Next.js usando somente `getPublicListings({ sellerId })`;
- derivar nome do Seller do primeiro Listing público retornado;
- ligar o Seller exibido no detalhe do anúncio ao novo Hub;
- provar por HTTP real que Listings de outro Seller não vazam e que Seller sem Listing público retorna 404.

## Fora de escopo

- novo aggregate, tabela, migration ou schema;
- endpoint dedicado de perfil público de Seller;
- PII/perfil Buyer;
- reputação, avaliações, verificação, endereço ou dados empresariais;
- WhatsApp genérico sem Listing/Lead;
- slug semântico ou página agregada por localização;
- sort/ranking novo;
- paginação sofisticada além de `Skip/Take` já existentes;
- SEO/social metadata específica do Seller Hub além do mínimo necessário à página.

## Critérios de aceite

1. [ ] `PublicListingSearchInput` aceita `SellerId` e a query pública filtra por ownership do Listing.
2. [ ] Draft/Pause/Archive continuam invisíveis no filtro por Seller.
3. [ ] `/vendedores/{sellerId}` retorna somente Listings públicos desse Seller.
4. [ ] Seller diferente não vaza para a página nem para a API filtrada.
5. [ ] O detalhe público liga o nome do Seller ao Hub correspondente.
6. [ ] SellerId inválido ou Seller sem Listing público não produz página pública válida.
7. [ ] Nenhum novo domínio, schema, migration, perfil público ou contato genérico é criado.
8. [ ] Gate focal e regressões diretamente afetadas passam no head funcional e no head documental final.

## Checkpoints

- [x] Refetch do `main` e auditoria de gaps.
- [x] Seleção do Seller Hub por implementação parcial comprovada.
- [ ] Implementar filtro `SellerId` backend/client.
- [ ] Implementar rota e link público.
- [ ] Executar prova HTTP real com dois Sellers.
- [ ] Atualizar documentação canônica e encerrar o plano.
- [ ] Rodar CI fresco final, review/base refresh e merge.

## Decisões

### Autoridade da vitrine

**DECIDIDO:** o primeiro Seller Hub existe somente enquanto há pelo menos um Listing atualmente público para o Seller e é derivado da mesma projeção pública usada na home/detalhe. Não será criado endpoint paralelo de perfil público neste plano.

### Contato

**DECIDIDO:** o Hub não abre WhatsApp genérico. O contato continua vinculado a um Listing para preservar a captura de Lead já comprovada.

### Identidade pública do Seller

**NÃO DECIDIDO:** slug, reputação, verificação, endereço, descrição editorial, logo/avatar e demais enriquecimentos exigem necessidade e modelo próprios antes de entrar.

## Progress log

- 2026-08-24: `main` refetched no merge do Plan 0021; auditoria comparou Seller Hub, sort e metadata da home.
- 2026-08-24: Seller Hub selecionado porque SellerId/DisplayName já estão no contrato e UI, enquanto o nome exibido no detalhe ainda é um beco sem saída.

## Decision log

- Reutilizar `PublicListingSearchInput`/`PublicListingQuery` e `ListingVisibility.PublicOnly`.
- Não criar endpoint dedicado de Seller profile para a primeira vitrine.
- Não criar WhatsApp genérico no Hub; Lead continua associado a Listing.
- Manter reputação, verificação, slugs e enriquecimento fora deste slice.

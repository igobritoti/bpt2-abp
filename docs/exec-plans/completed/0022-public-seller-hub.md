# Execution Plan 0022 — Public Seller Hub

Status: **CONCLUÍDO**

## Objetivo

Fechar o menor gap público comprovado após o Plan 0021, transformando o Seller já projetado no detalhe em um destino navegável baseado exclusivamente em Listings públicos:

`Public Listing → Seller exibido → /vendedores/{sellerId} → anúncios públicos desse Seller`

## Evidência que abriu o slice

- `PublicListingDto` já projetava `SellerId`, `DisplayName` e `WhatsAppNumber` via `Sellers.Contracts`;
- o detalhe público já exibia o `DisplayName` do Seller, mas o nome não levava a nenhum destino público;
- `PublicListingSearchInput` já concentrava filtros públicos e `PublicListingQuery` já aplicava `ListingVisibility.PublicOnly` antes dos filtros;
- `ISellerPublicReader.GetAsync/GetManyAsync` e a projeção existente mostravam que não era necessário criar nova entidade ou perfil público para esta fatia;
- sort exigiria escolher sem evidência uma semântica de ordenação, enquanto metadata da home seria acabamento sem fechar um novo loop de navegação.

## Escopo executado

- `PublicListingSearchInput` ganhou `SellerId`;
- `PublicListingQuery.SearchPageAsync` filtra por `Listing.SellerId` somente depois de partir de `ListingVisibility.PublicOnly`;
- `getPublicListings` serializa `SellerId` para a API pública;
- o detalhe público liga o nome do Seller a `/vendedores/{sellerId}`;
- `/vendedores/{sellerId}` usa somente `getPublicListings({ sellerId })`, deriva o nome do Seller da própria projeção pública e pagina por `Skip/Take` existente;
- Seller sem Listing público e identificador inválido retornam 404;
- a página publica title/canonical mínimos derivados do mesmo SellerId/DisplayName já presentes nos Listings públicos;
- o smoke focal cria dois Sellers reais, um Draft e dois Listings publicados, provando isolamento e invisibilidade de Draft;
- o smoke limpa as ofertas auxiliares antes de entregar a base aos smokes seguintes do mesmo job.

## Fora de escopo

- novo aggregate, tabela, migration ou schema;
- endpoint dedicado de perfil público de Seller;
- PII/perfil Buyer;
- reputação, avaliações, verificação, endereço ou dados empresariais;
- WhatsApp genérico sem Listing/Lead;
- slug semântico ou página agregada por localização;
- sort/ranking novo;
- engine de busca externa;
- contato ou Lead desacoplado de Listing.

## Critérios de aceite

1. [x] `PublicListingSearchInput` aceita `SellerId` e a query pública filtra por ownership do Listing.
2. [x] Draft/Pause/Archive continuam invisíveis no filtro por Seller.
3. [x] `/vendedores/{sellerId}` retorna somente Listings públicos desse Seller.
4. [x] Seller diferente não vaza para a página nem para a API filtrada.
5. [x] O detalhe público liga o nome do Seller ao Hub correspondente.
6. [x] SellerId inválido ou Seller sem Listing público não produz página pública válida.
7. [x] Nenhum novo domínio, schema, migration, perfil público ou contato genérico foi criado.
8. [x] Gate focal e todos os 16 workflows aplicáveis passaram no head funcional.

## Checkpoints

- [x] `main` remoto confirmado em `90ddf1cbb04fbc641a3941de5e8d920044284930` após o Plan 0021.
- [x] Seller Hub comparado com sort e metadata da home e selecionado por implementação parcial comprovada.
- [x] branch `feat/public-seller-hub` criada.
- [x] draft PR #41 aberto.
- [x] filtro `SellerId` backend/client implementado.
- [x] rota e link público implementados.
- [x] prova HTTP real executada com dois Sellers.
- [x] falha de guard UUID investigada e corrigida sem ampliar o produto.
- [x] contaminação de fixture entre smokes investigada e corrigida somente no harness.
- [x] head funcional passou 16/16 workflows aplicáveis.
- [x] documentação preparada para CI final fresco.

## Evidência executada

Head funcional final: `ab383fde27ca03c4187c4541b2f41171db0ea2f4`.

Todos os **16/16 workflows aplicáveis** passaram nesse SHA, incluindo Architecture, Harness, Host, Public Web, Fresh Migration, Product API, Public Discovery e as regressões HTTP de Buyer/Seller/Listing.

O gate focal **BPT2 Public Buyer HTTP Gate** executou no run `32761390808`, job `97540805710`, contra PostgreSQL 17 fresco, host ABP real e build/start de produção do Next.js.

Marcadores exatos do Seller Hub:

- `FRESH MIGRATION GATE: PASSED`
- build .NET: `0 Warning(s)` / `0 Error(s)`
- `PUBLIC_SELLER_HUB_SELLERS: PASS`
- `PUBLIC_SELLER_HUB_FIXTURES: PASS`
- `PUBLIC_SELLER_HUB_API_FILTER: PASS`
- `PUBLIC_SELLER_HUB_DETAIL_LINK: PASS`
- `PUBLIC_SELLER_HUB_VISIBLE: PASS`
- `PUBLIC_SELLER_HUB_ISOLATED: PASS`
- `PUBLIC_SELLER_HUB_UNKNOWN_HIDDEN: PASS`
- `PUBLIC_SELLER_HUB_EMPTY_HIDDEN: PASS`
- `PUBLIC_SELLER_HUB_FIXTURES_CLEANED: PASS`
- `PUBLIC SELLER HUB HTTP: PASSED`

No mesmo job, depois do smoke novo, também passaram integralmente:

- `PUBLIC VEHICLE HUB HTTP: PASSED`
- `PUBLIC SEO HTTP: PASSED`
- `AUTHENTICATED_LEAD_FORWARDING: PASS`

A fixture comprovou:

- dois Sellers distintos criados via Identity API e autenticados por token real;
- um Listing público e um Draft para o Seller owner;
- um Listing público para outro Seller;
- API filtrada por `SellerId` retornando apenas o Listing público do owner;
- detalhe público apontando para `/vendedores/{sellerId}`;
- Hub retornando nome + Listing do owner sem Draft nem Listing do outro Seller;
- SellerId inexistente e formato inválido retornando 404;
- Pause do último Listing público fazendo o Hub deixar de existir publicamente;
- cleanup do Listing auxiliar preservando independência dos smokes Vehicle Hub/SEO seguintes.

Classe da evidência: **B — comportamento reproduzido em CI contra aplicação real**.

## Falhas observadas e correções focadas

### 1. Guard de UUID excessivamente restritivo

No head `60dbc839ec424bc75a890daac2931d593b9f733d`, o backend já provava `PUBLIC_SELLER_HUB_API_FILTER: PASS` e o detalhe já provava o link correto, mas `/vendedores/{sellerId}` retornava 404. A causa era um regex da página que aceitava apenas UUID versões 1–5, enquanto o identificador real gerado pela stack ABP não atendia essa restrição.

Correção: validar somente o formato textual de `Guid` de 36 caracteres. Nenhuma regra de domínio, filtro ou autoridade mudou.

### 2. Fixture do smoke contaminando Vehicle Hub subsequente

No head `f37ba14aa6208bd0c236a102052b17b806b5dfe5`, o Seller Hub passou integralmente, mas o smoke Vehicle Hub seguinte não encontrou seu estado vazio após Pause. O Seller Hub havia deixado o Listing público do segundo Seller ativo no mesmo Vehicle fixture.

Correção: o smoke Seller Hub passou a pausar também a oferta pública auxiliar antes de terminar. Nenhum código de produto mudou. No head `ab383fde...`, Seller Hub → Vehicle Hub → SEO → authenticated Lead forwarding passaram sequencialmente.

## Decision log

- **DECIDIDO:** o primeiro Seller Hub existe somente enquanto há ao menos um Listing atualmente público para o Seller.
- **DECIDIDO:** a autoridade de visibilidade continua sendo `ListingVisibility.PublicOnly`; `SellerId` é apenas mais um filtro da query pública existente.
- **DECIDIDO:** nome/identidade mínima do Seller no Hub vêm da mesma projeção pública de Listing; não há endpoint paralelo de profile.
- **DECIDIDO:** o Hub não abre WhatsApp genérico; contato e Lead continuam associados a Listing.
- **NÃO DECIDIDO:** slug, reputação, avaliações, verificação, endereço, descrição editorial, logo/avatar, dados empresariais, ranking e analytics do Seller.

## Progress log

- 2026-08-24: `main` remoto confirmado em `90ddf1cbb04fbc641a3941de5e8d920044284930` após merge do Plan 0021.
- 2026-08-24: auditoria comparou Seller Hub, sort e metadata da home; Seller Hub selecionado por fechar um loop com SellerId/DisplayName já projetados.
- 2026-08-24: branch `feat/public-seller-hub` criada e draft PR #41 aberto.
- 2026-08-24: filtro público, cliente HTTP, link no detalhe, rota SSR e smoke focal implementados.
- 2026-08-24: primeira execução comprovou backend/filter e expôs guard UUID restritivo na rota; correção limitada ao guard.
- 2026-08-24: segunda execução comprovou Seller Hub integralmente e expôs contaminação de fixture no smoke Vehicle Hub seguinte; correção limitada ao cleanup do harness.
- 2026-08-24: head `ab383fde27ca03c4187c4541b2f41171db0ea2f4` passou 16/16 workflows; focal comprovou Seller Hub e regressões subsequentes na mesma base.
- 2026-08-24: documentação preparada para fechamento e CI final fresco.

## Resultado

**PASSA / CONCLUÍDO.** A navegação pública agora fecha:

`Public Listing → Seller → Seller Hub → outros Listings públicos do mesmo Seller`

O fechamento reutilizou integralmente a projeção pública existente e a autoridade de visibilidade do Marketplace, sem criar aggregate, schema, migration, perfil público paralelo ou contato genérico.

## Gaps futuros

Slug público do Seller, reputação/avaliações, verificação, endereço/dados empresariais, descrição editorial, logo/avatar, analytics, ranking/sort específico e qualquer contato desacoplado de Listing permanecem abertos e só devem ser considerados mediante necessidade e evidência.

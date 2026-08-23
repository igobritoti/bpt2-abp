# Execution Plan 0004 — Seller Self-Service

Status: **ATIVO**

## Objetivo

Transformar a superfície autenticada já existente no backend no primeiro fluxo operacional real do vendedor:

`Seller login → Seller profile → My Listings → Draft/Edit → Vehicle selection → Photos → Publish → Public Listing`

O plano deve provar a experiência Seller sem duplicar regras de domínio no frontend e sem reabrir decisões já comprovadas no Product Baseline e no Plan 0003.

## Contexto congelado

- Product Baseline e Plan 0003 concluídos; Buyer já percorre `Public Listing → Public Detail → Photo → WhatsApp Contact`.
- `SellerProfileService` já é autenticado, deriva o Seller de `ICurrentUser` e permite leitura/upsert do perfil.
- `SellerListingQuery.GetMineAsync` já retorna somente Listings do usuário autenticado.
- `ListingCommandService` já cobre Create, Update com `ConcurrencyStamp`, Publish, Pause e Archive, sempre com ownership server-side e validação de Vehicle canônico.
- `ListingPhotoService` já cobre Attach, Reorder e Remove com ownership server-side.
- `MediaUploadAppService` já é autenticado.
- `VehicleCatalogAppService` já expõe Get/Search de Vehicle canônico; não é necessário criar catálogo paralelo para o formulário Seller.
- O host já contém Account/OpenIddict/Identity e a infraestrutura de autenticação usada pelos smokes.
- Para browser interativo, a baseline de segurança é Authorization Code + PKCE. O password grant usado em fixtures/smokes legados não deve virar formulário de login do produto.
- A leitura autenticada de edição foi resolvida pelo contrato mínimo `SellerListingQuery.GetMineByIdAsync`, que filtra `listingId + CurrentUser` e devolve o Listing com a galeria ordenada atual. Nenhum novo aggregate, regra de domínio ou dependência entre implementações de módulos foi necessário.
- BPT1 continua sendo donor, não chassis. Nenhum repositório/código BPT1 foi encontrado nas fontes GitHub acessíveis nesta auditoria nem em busca pública identificável com segurança; portanto nenhuma regra, tela ou componente do BPT1 será presumido. Quando uma fonte real estiver acessível, ela poderá ser auditada como donor sem bloquear este plano.
- O Seller Auth HTTP Gate comprovou um cliente OpenIddict público dedicado `BomPraTi_SellerWeb`, PKCE obrigatório e redirect válido para o Account login do ABP; o Public Web Gate comprovou as rotas Seller no cliente Next existente.
- O Seller Shell HTTP Gate comprovou em PostgreSQL fresco o fluxo `Account login → Authorization Code + PKCE → SellerWeb access token → Profile → Draft → My Listings → logout`, usando o mesmo cliente OIDC do produto para as APIs autenticadas.
- O Seller Draft Edit HTTP Gate comprovou Vehicle canônico, criação Draft, leitura apenas do owner, estado/galeria atuais, update com rotação de `ConcurrencyStamp`, conflito stale 409 e reread do estado canônico.

## Escopo

### Fase 0 — provar a fronteira autenticada do Seller

- decidir, por prova mínima, onde vive a UI Seller: extensão do cliente Next.js existente ou cliente autenticado separado;
- registrar cliente OpenIddict/redirects necessários;
- provar o mecanismo de login por Authorization Code + PKCE contra o Auth Server BPT2;
- manter senha fora do frontend BPT2 e não usar ROPC/password grant como UX do produto;
- preservar o boundary HTTP/API: frontend não referencia assemblies, DbContexts ou implementação dos módulos.

### Fase 1 — Seller shell mínimo

- concluir login/logout de usuário real pelo fluxo já provado em protocolo;
- perfil do Seller com `DisplayName` e WhatsApp canônico;
- página `Meus anúncios` consumindo a query autenticada existente;
- estados de Listing apresentados sem inventar transições no frontend.

### Fase 2 — edição de Listing

- adicionar somente a leitura autenticada necessária para abrir um Listing próprio em modo de edição, incluindo a galeria/ordem atual ou contrato equivalente mínimo;
- selecionar Vehicle usando a API canônica já existente;
- criar Draft;
- editar campos existentes respeitando `ConcurrencyStamp` e conflito 409;
- não permitir que o cliente escolha/forje `SellerId`.

### Fase 3 — fotos e publicação

- upload usando Media autenticado existente;
- attach/remove/reorder usando Marketplace existente;
- primeira foto/ordem derivada da ordenação já modelada, sem provider key no frontend;
- publicar, pausar e arquivar apenas pelas transições existentes no backend;
- após Publish, comprovar presença no public web já existente.

### Fase 4 — prova operacional

- gate reproduzível com autenticação real do Seller e chamadas HTTP reais;
- provar ownership negativo com segundo usuário;
- provar stale concurrency na edição;
- provar Draft privado antes de Publish e anúncio público depois de Publish;
- manter Harness/Public Web e regressões diretamente afetadas verdes.

## Fora de escopo

- buyer account e Favorites;
- Lead/CRM/analytics/chat;
- moderação/administração completa;
- promoções, pagamentos ou créditos;
- Vehicle Hub;
- ingestão/reconciliation;
- novo object storage provider;
- Redis, broker, distributed locks ou background jobs sem caso real;
- engine de busca externo;
- expansão do modelo de Listing ou de filtros públicos sem necessidade desta UI;
- clonagem integral do BPT1;
- mudança de framework do public web apenas para acomodar este plano.

## Critérios de aceite

1. [x] Seller consegue entrar e sair da experiência autenticada usando Authorization Code + PKCE; password grant não é usado como login de produto.
2. [x] A UI Seller continua cliente HTTP da aplicação e não referencia implementação/DbContext dos módulos.
3. [x] Seller consegue ler e atualizar o próprio perfil, preservando normalização de WhatsApp no backend.
4. [x] `Meus anúncios` mostra somente Listings do usuário autenticado.
5. [x] Seller consegue criar Draft escolhendo um Vehicle da API canônica existente.
6. [x] Seller consegue reabrir e editar um Listing próprio com estado e fotos atuais; o backend expõe apenas o contrato adicional mínimo necessário.
7. [x] Edição usa `ConcurrencyStamp`; stale update continua resultando em conflito em vez de overwrite silencioso.
8. [ ] Upload/attach/remove/reorder de fotos funciona pela UI sem expor storage provider key e respeita ownership.
9. [ ] Publish torna o anúncio visível no public web; Draft continua invisível e segundo Seller continua impedido de mutar o anúncio.
10. [ ] Fluxo `login → perfil/meus anúncios → Draft → edição/fotos → Publish → public web` é comprovado por gate reproduzível e documentação canônica é atualizada no fechamento.

## Checkpoints

- [x] Auditar a superfície Seller atual do BPT2.
- [x] Confirmar que Vehicle search, commands, upload e photo mutations já existem.
- [x] Identificar o gap mínimo de leitura para tela de edição/galeria.
- [x] Verificar disponibilidade do donor BPT1 nas fontes acessíveis — fonte não disponível; não bloquear o plano nem inferir conteúdo.
- [x] Confirmar baseline de autenticação interativa: Authorization Code + PKCE.
- [x] Provar a menor opção de UI/auth e registrar a decisão antes de construir telas de negócio.
- [x] Implementar Seller shell mínimo: login/logout, perfil e Meus anúncios.
- [x] Implementar query de edição mínima + Draft/Edit/Vehicle.
- [ ] Implementar fotos + Publish/Pause/Archive.
- [ ] Provar fluxo end-to-end e regressões relevantes.
- [x] Revisar necessidade de ADR/MDV após a prova — MDV atualizado; nenhum novo ADR necessário porque ADR-0004/0009 continuam descrevendo os boundaries duráveis e a escolha `/vender` é uma composição de cliente reversível.
- [ ] Encerrar o plano com resultado, evidência e gaps futuros explícitos.

## Decisões

### UI Seller: mesmo `public-web` ou cliente separado

**DECIDIDO para a primeira implementação:** reutilizar o `public-web` existente com rotas Seller isoladas sob `/vender`, sessão OIDC dedicada e cliente `BomPraTi_SellerWeb`.

Evidência B reproduzida no CI:

- `BomPraTi_SellerWeb` é semeado como cliente público de Authorization Code;
- PKCE é requisito do cliente no OpenIddict;
- requisição sem PKCE é recusada;
- requisição com S256 PKCE é encaminhada ao Account login do ABP;
- o Seller Shell troca o authorization code por token e usa esse access token nas APIs autenticadas;
- perfil é salvo/lido com WhatsApp canônico devolvido pelo backend;
- `My Listings` é consultado sem `SellerId` fornecido pelo cliente e o backend continua derivando ownership de `ICurrentUser`;
- as rotas Seller passam lint, typecheck e production build;
- regressões públicas continuam exercitadas pelo Public Buyer HTTP Gate.

A decisão não acopla React/Next aos módulos do backend e permanece reversível porque a integração durável continua HTTP/OIDC conforme ADR-0004 e ADR-0009.

### Contrato de leitura para edição

**DECIDIDO:** `ISellerListingQuery.GetMineByIdAsync(Guid listingId)` retorna `SellerListingDetailDto(ListingDto Listing, IReadOnlyList<ListingPhotoDto> Photos)`.

A implementação:

- deriva o Seller de `ICurrentUser`;
- filtra `Listing.Id + SellerId` no servidor;
- retorna `null` para Listing inexistente ou pertencente a outro Seller, sem expor existência pela query de edição;
- devolve a galeria do Listing ordenada por `SortOrder` e `Id`;
- reutiliza `ListingDto` e `ListingPhotoDto`, sem novo aggregate ou referência a outro módulo de implementação.

O Vehicle é selecionado na criação do Draft pela API canônica existente. A edição respeita o contrato atual de `UpdateListingInput`, que não altera `VehicleId`; não foi expandido o comando apenas por conveniência de UI.

## Evidência externa usada no planejamento

- ABP React UI atual documenta Authorization Code + PKCE como o fluxo do browser e configura Auth Server/OpenIddict, route guards e cliente OIDC para aplicações React modernas.
- OpenIddict recomenda Authorization Code para aplicações com usuário final e suporta PKCE; resource owner password credentials não é recomendado para novas aplicações interativas.

Essas fontes definem a baseline de segurança do login do browser. A escolha específica do container de UI do BPT2 foi resolvida empiricamente pelo Seller Auth spike.

## Progress log

- 2026-08-23: após Plan 0003 e fechamento do guia de desenvolvimento local, Seller Self-Service foi selecionado como menor gap operacional que fecha o ciclo vendedor→comprador pela experiência real.
- 2026-08-23: auditoria do backend confirmou SellerProfile autenticado, My Listings, Listing commands, Vehicle search, Media upload e photo mutations já existentes.
- 2026-08-23: auditoria identificou como gap de backend uma leitura autenticada de detalhe/galeria para reabrir edição, não uma nova modelagem de Listing.
- 2026-08-23: donor BPT1 não estava disponível nas fontes GitHub conectadas nem foi identificado com segurança em busca pública; nenhuma clonagem/adaptação foi presumida.
- 2026-08-23: documentação atual ABP/OpenIddict confirmou Authorization Code + PKCE como baseline para login interativo; password grant permanece restrito a fixtures/smokes existentes.
- 2026-08-23: primeiro Seller Auth CI detectou que um novo `[UnitOfWork]` contributor `sealed` não podia ser interceptado pelo ABP/Autofac; a correção mínima tornou a classe proxyable e o método interceptado `virtual`.
- 2026-08-23: Seller Auth HTTP Gate corrigido passou discovery, PKCE obrigatório e redirect ao Account login; as regressões diretamente afetadas também passaram.
- 2026-08-23: Seller shell implementado no `/vender` usando o access token OIDC para carregar Seller Profile e `Meus anúncios`; o frontend não recebe `SellerId` nem normaliza WhatsApp por conta própria.
- 2026-08-23: a auditoria do primeiro Seller Shell gate identificou evidência insuficiente porque as APIs eram exercitadas com o password grant do cliente de fixture. O gate foi reforçado para obter token real de `BomPraTi_SellerWeb` via Account login + Authorization Code + PKCE.
- 2026-08-23: o primeiro reforço do smoke falhou por erro de sintaxe no próprio Bash antes de atingir Profile/My Listings; corrigido o script e adicionado `bash -n` como fail-fast antes do bootstrap de banco.
- 2026-08-23: Seller Shell HTTP Gate corrigido comprovou `OIDC discovery → Account login → PKCE token → Profile upsert/current → Draft → My Listings → logout`; Public Web, Seller Auth, Harness e Public Buyer permaneceram verdes no mesmo runtime head.
- 2026-08-23: implementado o read model mínimo `GetMineByIdAsync` e as rotas Seller para escolher Vehicle canônico, criar Draft e reabrir/editar Listing próprio.
- 2026-08-23: o primeiro Seller Draft Edit gate mostrou que `UpdateAsync` existente é `PUT /api/app/listing-command?listingId=...`, e não uma rota path-param; o cliente foi alinhado ao Swagger real sem mudar o backend.
- 2026-08-23: o segundo run do gate encontrou um erro no próprio fixture Bash (`local` com expansão sob `set -u`) antes do token; as declarações foram separadas sem alteração de produto.
- 2026-08-23: Seller Draft Edit HTTP Gate corrigido passou routes, Vehicle canônico, Draft create, owned read, cross-Seller hidden read, update, rotação do `ConcurrencyStamp`, stale 409 e reread do estado atualizado.

## Decision log

- Plan 0004 selecionado como próximo slice de produto.
- Reutilizar as regras e APIs BPT2 existentes antes de criar qualquer backend novo.
- BPT1 só será donor quando houver fonte concreta auditável; indisponibilidade do donor não bloqueia o desenvolvimento do Seller Self-Service.
- Login interativo não usará password grant.
- Primeira UI Seller será implementada no `public-web` existente sob `/vender`, usando cliente OIDC dedicado e Authorization Code + PKCE.
- Seller shell não exigiu novo serviço, aggregate ou regra de domínio no backend; reutilizou Seller Profile e My Listings existentes.
- A edição usa um único read contract adicional no Marketplace; ownership permanece server-side e a galeria atual é parte da projeção de edição.
- Vehicle é escolhido na criação do Draft; o contrato de update não foi ampliado para trocar Vehicle sem necessidade de domínio comprovada.
- Nenhum ADR novo foi criado para esta composição: ADR-0004 preserva o boundary HTTP e ADR-0009 já fixa o cliente Next inicial; as decisões Seller continuam reversíveis e registradas neste plano + MDV.

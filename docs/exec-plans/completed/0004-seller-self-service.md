# Execution Plan 0004 — Seller Self-Service

Status: **CONCLUÍDO**

## Objetivo

Transformar a superfície autenticada já existente no backend no primeiro fluxo operacional real do vendedor:

`Seller login → Seller profile → My Listings → Draft/Edit → Vehicle selection → Photos → Publish → Public Listing`

O plano prova a experiência Seller sem duplicar regras de domínio no frontend e sem reabrir decisões já comprovadas no Product Baseline e no Plan 0003.

## Contexto congelado

- Product Baseline e Plan 0003 concluídos; Buyer já percorre `Public Listing → Public Detail → Photo → WhatsApp Contact`.
- `SellerProfileService` já é autenticado, deriva o Seller de `ICurrentUser` e permite leitura/upsert do perfil.
- `SellerListingQuery.GetMineAsync` já retorna somente Listings do usuário autenticado.
- `ListingCommandService` cobre Create, Update com `ConcurrencyStamp`, Publish, Pause e Archive, sempre com ownership server-side e validação de Vehicle canônico.
- `ListingPhotoService` cobre Attach, Reorder e Remove com ownership server-side.
- `MediaUploadAppService` é autenticado; Media valida bytes de JPEG/PNG/WebP e não expõe storage key/provider ao cliente.
- `VehicleCatalogAppService` expõe Get/Search de Vehicle canônico; não foi criado catálogo paralelo para o formulário Seller.
- O host contém Account/OpenIddict/Identity e a infraestrutura de autenticação usada pelo produto e pelos smokes.
- Para browser interativo, a baseline é Authorization Code + PKCE. O password grant usado em fixtures legados não virou formulário de login do produto.
- A leitura autenticada de edição foi resolvida pelo contrato mínimo `SellerListingQuery.GetMineByIdAsync`, que filtra `listingId + CurrentUser` e devolve o Listing com a galeria ordenada atual.
- A visualização de fotos privadas do próprio anúncio foi resolvida por `SellerListingQuery.GetMinePhotoAsync`, que valida Listing + Seller no Marketplace e lê os bytes por `IMediaContentReader` de Media.Contracts; o frontend não recebe storage key/provider.
- BPT1 continua sendo donor, não chassis. Nenhum repositório/código BPT1 foi encontrado nas fontes GitHub acessíveis durante o plano; nenhuma regra, tela ou componente do BPT1 foi presumido.
- O Seller Auth HTTP Gate comprovou o cliente público `BomPraTi_SellerWeb`, PKCE obrigatório e redirect válido para o Account login do ABP.
- O Seller Shell HTTP Gate comprovou em PostgreSQL fresco `Account login → Authorization Code + PKCE → SellerWeb access token → Profile → Draft → My Listings → logout`.
- O Seller Draft Edit HTTP Gate comprovou Vehicle canônico, criação Draft, leitura apenas do owner, estado/galeria atuais, update com rotação de `ConcurrencyStamp`, conflito stale 409 e reread do estado canônico.
- O Seller Photos Publish HTTP Gate comprovou upload/preview privado/attach/reorder/remove, ownership negativo, Draft privado, Publish público, Pause privado, republish público e Archive privado contra host real + PostgreSQL fresco + Next de produção.

## Escopo executado

### Fase 0 — fronteira autenticada do Seller

- [x] UI Seller no `public-web` existente sob `/vender`;
- [x] cliente OpenIddict dedicado;
- [x] login por Authorization Code + PKCE;
- [x] senha fora do frontend BPT2;
- [x] boundary HTTP/API preservado.

### Fase 1 — Seller shell mínimo

- [x] login/logout real;
- [x] perfil do Seller com `DisplayName` e WhatsApp canônico;
- [x] `Meus anúncios` via query autenticada;
- [x] estados apresentados sem inventar transições no frontend.

### Fase 2 — edição de Listing

- [x] leitura autenticada de Listing próprio com galeria/ordem atual;
- [x] seleção de Vehicle pela API canônica;
- [x] criação Draft;
- [x] edição com `ConcurrencyStamp` e conflito 409;
- [x] ausência de `SellerId` forjável no cliente.

### Fase 3 — fotos e publicação

- [x] upload via Media autenticado existente;
- [x] preview autenticado das fotos do próprio Listing, inclusive em Draft, sem tornar mídia privada pública;
- [x] attach/remove/reorder via Marketplace existente;
- [x] primeira foto/capa derivada da ordenação modelada, sem novo campo e sem provider key no frontend;
- [x] Publish/Pause/Archive apenas pelos commands existentes;
- [x] após Publish, presença comprovada no public web.

### Fase 4 — prova operacional

- [x] gate reproduzível com autenticação real SellerWeb/PKCE e chamadas HTTP reais;
- [x] ownership negativo com segundo usuário, inclusive leitura privada de foto ocultada com 404;
- [x] stale concurrency na edição;
- [x] Draft privado antes de Publish e anúncio público depois de Publish;
- [x] regressões Seller/Public diretamente afetadas verdes.

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
- expansão do modelo de Listing ou de filtros públicos sem necessidade comprovada;
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
8. [x] Upload/preview/attach/remove/reorder de fotos funciona pela UI sem expor storage provider key e respeita ownership.
9. [x] Publish torna o anúncio visível no public web; Draft continua invisível e segundo Seller continua impedido de mutar ou ler foto privada do anúncio.
10. [x] Fluxo `login → perfil/meus anúncios → Draft → edição/fotos → Publish → public web` é comprovado por gate reproduzível e documentação canônica atualizada no fechamento.

## Checkpoints

- [x] Auditar a superfície Seller atual do BPT2.
- [x] Confirmar que Vehicle search, commands, upload e photo mutations já existem.
- [x] Identificar o gap mínimo de leitura para tela de edição/galeria.
- [x] Verificar disponibilidade do donor BPT1 nas fontes acessíveis — fonte não disponível; não bloquear o plano nem inferir conteúdo.
- [x] Confirmar baseline de autenticação interativa: Authorization Code + PKCE.
- [x] Provar a menor opção de UI/auth e registrar a decisão antes de construir telas de negócio.
- [x] Implementar Seller shell mínimo: login/logout, perfil e Meus anúncios.
- [x] Implementar query de edição mínima + Draft/Edit/Vehicle.
- [x] Implementar fotos + Publish/Pause/Archive.
- [x] Provar fluxo end-to-end e regressões relevantes.
- [x] Revisar necessidade de ADR/MDV — nenhum novo ADR necessário; ADR-0004/0007/0009 continuam cobrindo os boundaries duráveis.
- [x] Encerrar o plano com resultado, evidência e gaps futuros explícitos.

## Decisões

### UI Seller

**DECIDIDO:** reutilizar o `public-web` existente com rotas Seller isoladas sob `/vender`, sessão OIDC dedicada e cliente `BomPraTi_SellerWeb`.

A decisão não acopla React/Next aos módulos do backend e permanece reversível porque a integração durável continua HTTP/OIDC conforme ADR-0004 e ADR-0009.

### Contrato de leitura para edição

**DECIDIDO:** `ISellerListingQuery.GetMineByIdAsync(Guid listingId)` retorna `SellerListingDetailDto(ListingDto Listing, IReadOnlyList<ListingPhotoDto> Photos)`.

A implementação deriva o Seller de `ICurrentUser`, filtra `Listing.Id + SellerId`, oculta Listings de outro Seller e devolve galeria ordenada por `SortOrder`/`Id`, reutilizando Contracts existentes.

### Fotos e publicação

**DECIDIDO por reutilização dos contratos existentes:**

- upload permanece responsabilidade de Media;
- Marketplace recebe somente `MediaAssetId` no attach;
- a galeria é ordenada pelo `SortOrder` já modelado;
- a primeira posição é a capa derivada da galeria, sem novo campo de domínio;
- o frontend não recebe storage key/provider;
- fotos de Listing privado são visualizadas pelo owner via `SellerListingQuery.GetMinePhotoAsync`, com ownership verificado no Marketplace e bytes lidos via Media.Contracts;
- o Swagger expõe essa leitura como `GET /api/app/seller-listing-query/mine-photo?listingId=...&photoId=...`; cliente e gate seguem o contrato observado em vez de introduzir rota artificial;
- Publish/Pause/Archive são commands do backend; o React não replica regras de transição.

## Evidência executada

O Seller Photos Publish HTTP Gate usa PostgreSQL fresco, host ABP real, Node 22.13.0 e Next.js de produção. No run final do checkpoint passaram:

- `SELLER_PUBLISH_ROUTES: PASS`;
- `SELLER_PUBLISH_PKCE_LOGIN: PASS`;
- `SELLER_PUBLISH_PROFILE: PASS`;
- `SELLER_PUBLISH_DRAFT_MY_LISTINGS: PASS`;
- `SELLER_PUBLISH_EDIT: PASS`;
- `SELLER_PUBLISH_UPLOAD: PASS`;
- `SELLER_PUBLISH_REORDER: PASS`;
- `SELLER_PUBLISH_PRIVATE_PHOTO: PASS`;
- `SELLER_PUBLISH_REMOVE: PASS`;
- `SELLER_PUBLISH_OWNERSHIP: PASS`;
- `SELLER_PUBLISH_DRAFT_PRIVATE_API: PASS`;
- `SELLER_PUBLISH_DRAFT_PRIVATE_WEB: PASS`;
- `SELLER_PUBLISH_PUBLIC: PASS`;
- `SELLER_PUBLISH_PAUSE: PASS`;
- `SELLER_PUBLISH_REPUBLISH: PASS`;
- `SELLER_PUBLISH_ARCHIVE: PASS`;
- `SELLER PHOTOS PUBLISH HTTP: PASSED`.

O gate valida via Swagger os endpoints usados pelo frontend, inclusive multipart de Media, `DELETE /api/app/listing-photo` com `listingId`/`photoId` em query e a leitura privada Seller com os mesmos parâmetros em query. A foto Draft do owner e a foto pública após Publish são comparadas byte a byte com o upload; o segundo Seller recebe 404 ao tentar ler a foto privada.

Classe da evidência: **B — comportamento reproduzido em CI contra a aplicação real**.

## Progress log

- 2026-08-23: Plan 0004 selecionado como menor gap operacional após o ciclo Buyer → WhatsApp.
- 2026-08-23: auditoria confirmou SellerProfile, My Listings, Listing commands, Vehicle search, Media upload e photo mutations existentes.
- 2026-08-23: fronteira de login Seller resolvida com Authorization Code + PKCE e cliente `BomPraTi_SellerWeb`.
- 2026-08-23: Seller shell comprovou login real, Profile, My Listings e logout.
- 2026-08-23: read model `GetMineByIdAsync` implementado como única extensão mínima de backend para edição.
- 2026-08-23: primeiro Seller Draft Edit gate revelou que Update usa `PUT /api/app/listing-command?listingId=...`; cliente foi alinhado ao Swagger sem mudar o backend por conveniência.
- 2026-08-23: segundo run Draft/Edit encontrou bug no fixture Bash sob `set -u`; fixture corrigido sem alteração de produto.
- 2026-08-23: Draft/Edit comprovou Vehicle canônico, Draft, owned read, cross-Seller hidden, rotação de stamp e stale 409.
- 2026-08-23: checkpoint final reutilizou Media, ListingPhoto e ListingCommand existentes; nenhum novo aggregate, serviço de domínio ou regra de transição foi adicionado.
- 2026-08-23: UI Seller passou a enviar imagens multipart, anexar/remover/reordenar galeria e chamar Publish/Pause/Archive; upload evita `Content-Type: application/json` quando o corpo é `FormData`.
- 2026-08-23: auto-revisão detectou que IDs de mídia não eram UX suficiente para ordenar/remover com segurança; foi adicionada leitura privada ownership-safe de foto para thumbnails do Seller em Draft.
- 2026-08-23: React 19 lint e TypeScript detectaram dois problemas locais na implementação de object URLs; ambos foram corrigidos sem mudança de contrato de produto.
- 2026-08-23: o gate detectou que o Swagger convencional gerou `mine-photo` com `listingId`/`photoId` em query; cliente e smoke foram alinhados ao runtime real sem criar rota artificial.
- 2026-08-23: Seller Photos Publish HTTP Gate final passou, incluindo preview privado byte a byte para owner, 404 cross-Seller e todo o ciclo até o public web de produção.

## Resultado

**PASSA / CONCLUÍDO.** O BPT2 possui agora um primeiro ciclo operacional de marketplace de duas pontas comprovado:

`Seller login → Profile → My Listings → Vehicle canônico → Draft → Edit → Photos → Publish → Public Listing → Public Detail/Photo → WhatsApp`

O fechamento não exigiu nova infraestrutura, novo storage provider, novo aggregate nem mudança de boundary arquitetural.

## Gaps futuros explícitos

Continuam fora deste plano e devem ser priorizados somente por necessidade real de produto:

- Public Discovery interativo: busca/filtros/paginação usando primeiro o contrato público já existente;
- buyer account/Favorites;
- ativação de comportamento de Lead/analytics/CRM para contatos, se houver requisito;
- moderação/admin operacional;
- promoções;
- Vehicle Hub;
- ingestão/reconciliation em escala;
- provider final de object storage;
- estratégia final de busca baseada em benchmark;
- decisões ainda abertas de schemas/FKs cross-module, distributed locks e background jobs.

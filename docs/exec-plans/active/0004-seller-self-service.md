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
- Para browser interativo, a baseline de segurança é Authorization Code + PKCE. O password grant usado nos smokes antigos é ferramenta de teste e não deve virar formulário de login do produto.
- A superfície Seller ainda não possui query dedicada para reabrir um Listing específico com sua galeria atual. `GetMine` é listagem; mutações de foto não substituem uma leitura de edição. Essa é a extensão mínima de backend já identificada.
- BPT1 continua sendo donor, não chassis. Nenhum repositório/código BPT1 foi encontrado nas fontes GitHub acessíveis nesta auditoria nem em busca pública identificável com segurança; portanto nenhuma regra, tela ou componente do BPT1 será presumido. Quando uma fonte real estiver acessível, ela poderá ser auditada como donor sem bloquear este plano.

## Escopo

### Fase 0 — provar a fronteira autenticada do Seller — CONCLUÍDA

- UI Seller vive inicialmente no `public-web`, sob `/vender`, preservando as páginas públicas SSR existentes;
- cliente OpenIddict dedicado `BomPraTi_SellerWeb` é público, permite apenas Authorization Code e exige PKCE;
- login retorna por `/auth/callback`; logout usa o end-session endpoint e `/auth/logout-callback`;
- `oidc-client-ts` executa o fluxo browser sem expor senha ao frontend BPT2;
- password grant não é permitido para `BomPraTi_SellerWeb`;
- boundary HTTP/API permanece intacto: frontend não referencia assemblies, DbContexts ou implementação dos módulos;
- `BPT2 Seller Auth PKCE Gate` reproduz o protocolo real contra host ABP e PostgreSQL frescos.

### Fase 1 — Seller shell mínimo

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

1. [ ] Seller consegue entrar e sair da experiência autenticada usando Authorization Code + PKCE; password grant não é usado como login de produto. A fronteira/protocolo já está provada por HTTP real; o critério permanece aberto até a prova operacional final da UX completa.
2. [x] A UI Seller continua cliente HTTP da aplicação e não referencia implementação/DbContext dos módulos.
3. [ ] Seller consegue ler e atualizar o próprio perfil, preservando normalização de WhatsApp no backend.
4. [ ] `Meus anúncios` mostra somente Listings do usuário autenticado.
5. [ ] Seller consegue criar Draft escolhendo um Vehicle da API canônica existente.
6. [ ] Seller consegue reabrir e editar um Listing próprio com estado e fotos atuais; o backend expõe apenas o contrato adicional mínimo necessário.
7. [ ] Edição usa `ConcurrencyStamp`; stale update continua resultando em conflito em vez de overwrite silencioso.
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
- [ ] Implementar Seller shell mínimo: login/logout, perfil e Meus anúncios.
- [ ] Implementar query de edição mínima + Draft/Edit/Vehicle.
- [ ] Implementar fotos + Publish/Pause/Archive.
- [ ] Provar fluxo end-to-end e regressões relevantes.
- [x] Revisar necessidade de ADR/MDV após a prova da fronteira de UI/auth — nenhum novo ADR necessário; a decisão é uma implementação reversível dentro do boundary já congelado no ADR-0004.
- [ ] Encerrar o plano com resultado, evidência e gaps futuros explícitos.

## Decisões abertas necessárias

### UI Seller: mesmo `public-web` ou cliente separado

**DECIDIDO: usar o mesmo `public-web` no primeiro Seller Self-Service.**

Evidência executada:

- o Next.js existente compilou `/vender`, `/auth/callback` e `/auth/logout-callback` sem alterar as páginas públicas SSR;
- o novo gate realizou Authorization Code + PKCE contra o Auth Server real e usou o access token em uma API Seller autenticada;
- Public Web Gate e Public Buyer HTTP Gate permaneceram verdes, portanto o acréscimo da área autenticada não regrediu o consumidor público existente;
- criar outro frontend agora adicionaria segunda toolchain/deploy sem necessidade demonstrada.

A decisão é reversível porque o boundary durável continua HTTP/API conforme ADR-0004. Separar a UI Seller futuramente continua permitido se isolamento, escala de equipe, deploy ou segurança produzirem evidência concreta.

### Contrato de leitura para edição

**NÃO DECIDIDO no formato exato.** A necessidade é comprovada; o desenho deve ser mínimo. Candidatos aceitáveis incluem uma query `GetMineById` com fotos/ordem ou composição equivalente que preserve ownership server-side e boundaries existentes.

## Evidência externa usada no planejamento

- ABP React UI atual documenta Authorization Code + PKCE como o fluxo recomendado para browser e usa `oidc-client-ts` como implementação OIDC subjacente: https://abp.io/docs/10.4/framework/ui/react/authorization
- OpenIddict recomenda Authorization Code para fluxos interativos e documenta enforcement de PKCE por cliente: https://documentation.openiddict.com/guides/choosing-the-right-flow.html e https://documentation.openiddict.com/configuration/proof-key-for-code-exchange

Essas fontes definem a baseline de segurança. A escolha de manter a UI Seller no `public-web` foi decidida pela prova do BPT2, não pela preferência de framework.

## Progress log

- 2026-08-23: após Plan 0003 e fechamento do guia de desenvolvimento local, Seller Self-Service foi selecionado como menor gap operacional que fecha o ciclo vendedor→comprador pela experiência real.
- 2026-08-23: auditoria do backend confirmou SellerProfile autenticado, My Listings, Listing commands, Vehicle search, Media upload e photo mutations já existentes.
- 2026-08-23: auditoria identificou como gap de backend uma leitura autenticada de detalhe/galeria para reabrir edição, não uma nova modelagem de Listing.
- 2026-08-23: donor BPT1 não estava disponível nas fontes GitHub conectadas nem foi identificado com segurança em busca pública; nenhuma clonagem/adaptação foi presumida.
- 2026-08-23: documentação atual ABP/OpenIddict confirmou Authorization Code + PKCE como baseline para login interativo; password grant permanece restrito a smokes/fixtures existentes.
- 2026-08-23: spike implementou `/vender` no `public-web`, cliente `BomPraTi_SellerWeb` público/Authorization Code-only, PKCE obrigatório e callbacks de login/logout.
- 2026-08-23: `BPT2 Seller Auth PKCE Gate` provou discovery S256, login via ABP Account, code exchange com verifier, bearer Seller API, rejeição sem PKCE, rejeição do password grant e end-session endpoint.
- 2026-08-23: Host, Public Web, Listing Lifecycle, Listing Photo, Product API e Public Buyer regressions permaneceram verdes no mesmo head da prova inicial.

## Decision log

- Plan 0004 selecionado como próximo slice de produto.
- Reutilizar as regras e APIs BPT2 existentes antes de criar qualquer backend novo.
- BPT1 só será donor quando houver fonte concreta auditável; indisponibilidade do donor não bloqueia o desenvolvimento do Seller Self-Service.
- Login interativo não usará password grant.
- A primeira UI Seller vive no `public-web` existente sob `/vender`; essa escolha é reversível e não altera o boundary HTTP/API.
- Nenhum ADR novo é necessário para esta decisão porque ADR-0004 já congela o desacoplamento por HTTP e não separa Buyer/Seller em deploys obrigatórios.

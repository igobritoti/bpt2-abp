# Produto — BPT2 / Bom Pra Ti

## Objetivo

Bom Pra Ti é um marketplace/classificados automotivo brasileiro. O núcleo do produto é conectar vendedores e compradores em torno de anúncios de veículos com identidade automotiva canônica, busca pública, confiança, conteúdo e contato — não reproduzir um e-commerce tradicional.

## Capacidades centrais

- usuários e identidade;
- vendedores;
- catálogo automotivo canônico;
- veículos;
- anúncios/listings;
- fotos e mídia;
- busca e filtros;
- detalhe público do anúncio;
- favoritos;
- leads e contato/WhatsApp;
- moderação;
- promoções;
- SEO;
- Vehicle Hub;
- administração;
- ingestão de fontes externas.

Algumas dessas capacidades ainda estão adiadas. Estar no produto-alvo não significa estar no slice corrente.

## Não objetivos do baseline

Não modelar prematuramente como requisito central:

- carrinho e checkout de mercadorias;
- fulfillment e shipping;
- tax engine de e-commerce;
- order management tradicional;
- escrow;
- split de pagamento da venda do veículo;
- microservices, broker, Redis, Kubernetes ou engine de busca externo sem evidência de necessidade.

## Catálogo canônico

BPT é a autoridade canônica do catálogo automotivo. Fontes externas, Buscador e integrações são **doadores de dados**, não fonte de verdade.

Fluxo conceitual:

`fonte externa → ingestão/conectividade → validação → normalização → reconciliação → provenance/confidence → aprovação automática/humana → catálogo canônico BPT`

Separações conceituais:

- **Structure:** Brand, Model, Generation, Version, Vehicle.
- **Enrichment:** specs, equipamentos, segurança, consumo, preço/mercado, editorial, imagens enriquecidas.
- **Connectivity/Ingestion:** sources, jobs de importação, APIs, provenance, confidence, reconciliation e validação.

## Slices concluídos

O Product Baseline de backend foi concluído até:

`Seller → Vehicle → Listing → Publish → Public Listing Query → Media/ListingPhoto → detalhe/listagem pública mínima`

O primeiro ciclo real do comprador foi concluído e comprovado por HTTP real:

`Public Listing → Public Detail → Photo → WhatsApp Contact`

O primeiro ciclo operacional real do vendedor também foi concluído no Plan 0004:

`Seller login → Seller profile → My Listings → Vehicle canônico → Draft/Edit → Photos → Publish → Public Listing`

A prova Seller usa Authorization Code + PKCE com o cliente `BomPraTi_SellerWeb`, mantém ownership no servidor, usa `ConcurrencyStamp` na edição, reutiliza Media/ListingPhoto para galeria e chama Publish/Pause/Archive somente pelos commands do backend. O gate final comprovou Draft privado, bloqueio de segundo Seller, publicação real no Next, Pause/Archive removendo visibilidade pública e republish restaurando-a.

O Plan 0005 concluiu a primeira experiência interativa de descoberta pública sem ampliar o contrato backend:

`Public Listings → busca/filtros → paginação → Public Detail → Photo → WhatsApp`

A home pública usa query string como estado da descoberta e oferece Query, Brand, Model, faixas de ano/preço e paginação anterior/próxima. O gate real comprovou filtros, total/paginação, preservação do estado na URL, range invertido retornando vazio e Draft permanecendo invisível. Ranking, novos filtros e engine externa continuam fora do slice.

O Plan 0006 concluiu o primeiro ciclo autenticado de Favorites do Buyer:

`Public Detail → Buyer login → Favorite/Unfavorite → Meus favoritos`

O Buyer usa `BomPraTi_BuyerWeb`, cliente OpenIddict público dedicado com Authorization Code + PKCE. Marketplace deriva o proprietário do Favorite de `ICurrentUser`; o browser não informa `UserId`. Só Listing atualmente público pode ser adicionado, e `Meus favoritos` reutiliza a projeção pública existente: Pause oculta o item sem apagar a relação, republish o restaura e unfavorite remove a intenção persistida.

O Plan 0007 concluiu a ativação mínima de Lead no contato WhatsApp:

`Public Detail → WhatsApp CTA → persist Lead → abrir conversa`

Marketplace reutiliza o aggregate e a tabela `Lead` já existentes. O servidor aceita contato anônimo, persiste `UserId` apenas quando houver identidade corrente, fixa o canal como `WhatsApp` e só cria Lead quando o Listing continua público no momento do POST. Draft, Pause e Archive são bloqueados pela mesma projeção pública usada pelo restante do produto. O public web envia somente `listingId`; o número de destino continua vindo do contato canônico de Sellers e o redirect ocorre depois da persistência.

O Plan 0008 conectou essa capacidade à sessão Buyer já existente sem tornar autenticação requisito do contato:

`Buyer autenticado → WhatsApp CTA → identidade opcional encaminhada ao Lead → abrir conversa`

O CTA preserva o formulário anônimo e o fallback 303 do Plan 0007. Quando o browser já possui uma sessão válida `BomPraTi_BuyerWeb`, o componente reutiliza seu access token e o envia somente ao route handler same-origin; o handler o encaminha ao endpoint de Lead. O token não é enviado ao WhatsApp, e o número de destino continua sendo calculado no servidor a partir do contato canônico do Listing. Não foi criado perfil Buyer, role, migration, endpoint backend ou infraestrutura nova.

O Plan 0009 fechou o primeiro ciclo operacional de Leads para o Seller:

`WhatsApp Lead persistido → Seller autenticado → Leads dos próprios anúncios`

Marketplace expõe uma query autenticada que deriva o Seller de `ICurrentUser` e filtra Leads por JOIN com Listings pertencentes a esse Seller; o cliente não informa `SellerId`. A inbox exibe somente metadados já existentes do Lead, título do Listing e `BuyerUserId` opcional, sem resolver PII/perfil Buyer. Leads já ocorridos permanecem como histórico quando o Listing é pausado ou arquivado. O shell `/vender` consome a rota por HTTP/OIDC existente, sem migration, módulo ou infraestrutura nova.

O Plan 0010 adicionou o primeiro estado operacional mínimo de atendimento sem transformar Leads em CRM:

`Lead novo → Seller owner marca como atendido → inbox preserva ContactedAtUtc`

`Lead.ContactedAtUtc` é nulo enquanto o contato está novo e recebe o primeiro instante UTC quando o Seller owner marca o atendimento. O command deriva o Seller de `ICurrentUser` e só encontra Leads ligados a Listings próprios; outro Seller recebe 404 e o browser nunca informa `SellerId`. A operação é monotônica/idempotente: chamadas repetidas preservam o primeiro timestamp. O shell `/vender` exibe Novo/Atendido e oferece a ação apenas para Leads ainda não atendidos. Notas, pipeline comercial, CRM, scoring e resolução de PII Buyer continuam fora do slice.

O Plan 0011 abriu a primeira capacidade real de moderação sem inventar política operacional prematura:

`Public Listing → Buyer autenticado → sinalizar anúncio → sinal persistido`

Marketplace persiste `ListingReport` com `UserId`, `ListingId` e `CreatedAtUtc`. O Buyer é sempre derivado de `ICurrentUser`; o browser não escolhe owner. Um mesmo Buyer gera no máximo um sinal por Listing, de forma idempotente. Um novo sinal só pode ser criado enquanto o Listing está público; depois de Pause/Archive o sinal já ocorrido permanece como histórico. O detalhe público expõe “Sinalizar anúncio” reutilizando a sessão `BomPraTi_BuyerWeb`. Motivo/taxonomia, texto livre, fila administrativa, suspensão automática, scoring e notificações permanecem fora deste slice.

O Plan 0012 fechou o primeiro consumo operacional dos sinais de moderação sem introduzir política de decisão:

`Buyer sinaliza Listing → report persistido → operador admin autenticado consulta fila`

Marketplace expõe `IModerationListingReportQuery` como application service read-only restrito à role `admin` já existente no baseline ABP. A projeção retorna somente `ReportId`, `ListingId`, título/status do Listing e `CreatedAtUtc`; não expõe `UserId` nem resolve perfil/PII Buyer. Reports já ocorridos permanecem visíveis quando o Listing deixa de estar público e refletem o status corrente do anúncio. Aprovar/rejeitar, motivo/taxonomia, suspensão/remoção, workflow, scoring, notificações e novo frontend admin continuam fora do slice.

O Plan 0013 fechou a primeira fatia explícita de SEO técnico público:

`Listing público → sitemap/robots → crawler descobre URL → detalhe publica canonical`

O public web reutiliza a API pública como autoridade de indexabilidade. `robots.txt` referencia o sitemap e bloqueia superfícies utilitárias/autenticadas; `sitemap.xml` contém home e Listings atualmente públicos; Draft/private não entra, Publish inclui e Pause remove. O detalhe público publica canonical absoluto configurável por `BPT_PUBLIC_BASE_URL`. JSON-LD, landing pages, estratégia de conteúdo, Search Console/analytics, cache/revalidation específica e ranking continuam abertos.

O Plan 0014 fechou o primeiro loop operacional real de Ingestion sem introduzir connector ou automação prematura:

`candidate externo → registro persistido → fila pendente → operador admin reconcilia com Vehicle canônico`

Ingestion expõe application service restrito à role `admin`, reutiliza `(Source, ExternalId)` como identidade externa deduplicada já expressa no schema e lista apenas registros ainda não reconciliados. A reconciliação só persiste `ReconciledVehicleId` depois que `IVehicleCatalogReader`, via `Catalog.Contracts`, confirma que o Vehicle canônico existe. O primeiro payload permanece imutável porque o aggregate existente só oferece `ReconcileTo`; connector/source concreto, matching automático, threshold de confidence, workflow de aprovação e background jobs continuam não decididos.

O Plan 0015 abriu a primeira fatia real de Vehicle Hub sem criar novo contrato backend:

`Listing público → Vehicle canônico → Hub público do Vehicle → Listings publicados desse Vehicle`

O public web carrega a identidade automotiva exclusivamente pelo `Vehicle` do Catalog e usa o filtro público já existente por `VehicleId` para disponibilidade. `/veiculos/{id}` continua 200 mesmo sem oferta ativa; Draft não aparece, Publish inclui o Listing e Pause o remove sem remover o Hub. O detalhe público liga a identidade do veículo ao Hub, e o Hub publica title/canonical para Vehicle existente e 404/noindex para id inexistente. Specs, equipamentos, consumo, preço de mercado, conteúdo editorial, páginas agregadas, slugs semânticos e sitemap completo do catálogo continuam abertos.

O Plan 0016 fechou a primeira fatia explícita de metadata de compartilhamento do Listing público:

`Listing publicado → metadata social SSR → link compartilhado com título/descrição/foto`

O detalhe público reutiliza exatamente title, description e canonical já derivados da projeção pública para Open Graph e Twitter. Quando existe foto, a primeira foto pública do Listing é reutilizada como imagem social e o Twitter usa `summary_large_image`; sem foto não se inventa asset paralelo. Draft/Pause/Archive continuam sem detalhe público e sem URL social indexável do Listing. JSON-LD, metadata social do Vehicle Hub/home/páginas agregadas, geração dedicada de social image, conteúdo/keywords e analytics continuam abertos.

O Plan 0017 fechou a primeira superfície visual operacional de moderação sem introduzir política de decisão:

`Buyer sinaliza Listing → report persistido → admin login no host → /moderacao → reports read-only`

A Razor Page `/moderacao` vive no host ABP já autenticado, exige role `admin` e consome exclusivamente `IModerationListingReportQuery`. Anônimo é enviado ao Account Login; usuário autenticado sem `admin` é bloqueado pelo fluxo de AccessDenied; admin autenticado pelo Account Web real vê somente ReportId, ListingId, título/status corrente e CreatedAtUtc, sem identidade/PII Buyer. Reports históricos continuam visíveis após Pause. Aprovar/rejeitar, taxonomia/motivo, política de suspensão/remoção, workflow, scoring, notificações e um shell administrativo genérico continuam abertos.

O Plan 0018 fechou a primeira superfície visual operacional de Ingestion sem criar autoridade ou workflow paralelo:

`candidate externo → fila pendente → admin login no host → /ingestao → reconciliar com Vehicle canônico`

A Razor Page `/ingestao` vive no host ABP já autenticado, exige role `admin` e consome exclusivamente `IIngestionCandidateAppService`. A fila exibe os campos já persistidos de identity/provenance/confidence; o operador informa um `VehicleId`, mas a validade canônica continua sendo decidida pelo backend via Catalog. Vehicle inexistente mantém o candidate pendente e mostra erro de validação; Vehicle canônico reconciliado remove o registro da fila pendente. Connector/source concreto, matching automático, threshold de confidence, workflow de aprovação, background jobs, autocomplete/busca de Vehicle e shell administrativo genérico continuam abertos.

O Plan 0019 fechou a metadata social mínima do Vehicle Hub público sem criar fonte de verdade ou imagem paralela:

`Vehicle canônico → /veiculos/{id} → metadata social SSR → link compartilhável coerente`

O Hub reutiliza exatamente title, description e canonical já derivados da identidade canônica do Catalog para Open Graph e Twitter. Como ainda não existe asset canônico próprio do Vehicle Hub, a primeira versão usa `summary` sem `og:image`/`twitter:image` e não reaproveita foto de Listing como se fosse identidade visual do Vehicle. Vehicle inexistente continua 404/noindex sem URL social válida. JSON-LD, imagem social dedicada, metadata social da home/páginas agregadas e estratégia editorial continuam abertos.

O Plan 0020 fechou o primeiro ponto de entrada comum das superfícies administrativas já existentes:

`admin login no host → /admin → Moderação / Ingestão`

A Razor Page `/admin` vive no mesmo host e exige a mesma role `admin` das superfícies que agrega. Ela não consulta dados nem duplica application services: apenas liga o operador a `/moderacao` e `/ingestao`. Anônimo é enviado ao Account Login, usuário autenticado sem `admin` é bloqueado e admin acessa o hub e os dois destinos com a mesma sessão. Menu global do tema, layout compartilhado, dashboard/métricas, permissões granulares e frontend admin separado continuam abertos.

A experiência pública, a experiência Buyer autenticada e a experiência Seller continuam clientes da aplicação por HTTP conforme ADR-0004. A primeira implementação permanece no Next.js 16 Active LTS/App Router conforme ADR-0009, mantendo os boundaries OIDC/HTTP reversíveis.

O domínio Sellers modela e normaliza `WhatsAppNumber`; a projeção pública de Listing entrega esse valor ao public web. O contato WhatsApp registra o Lead mínimo no Marketplace antes de abrir `https://wa.me/{digits}` e pode preservar a identidade Buyer quando já houver sessão. O Seller autenticado consulta o histórico de Leads dos próprios anúncios e pode registrar o primeiro instante de atendimento. O Buyer autenticado pode registrar um sinal mínimo de moderação sobre Listing público; um operador admin autenticado possui um hub comum para acessar as superfícies de Moderação e Ingestão sem receber nova autoridade de negócio. O public web publica descoberta SEO técnica mínima, metadata social do Listing público e do Vehicle Hub público, e um primeiro Vehicle Hub derivado da autoridade do Catalog; Ingestion possui fila e superfície visual interna para reconciliar identidades externas com Vehicle canônico. Analytics agregados, CRM, deduplicação/scoring comercial, resolução de perfil/PII Buyer, política operacional de moderação, enrichment do Vehicle Hub e ingestão automática continuam fora do baseline até necessidade comprovada.

## Slice ativo

Nenhum execution plan está ativo após o fechamento do Plan 0020. O próximo slice deve ser escolhido como o menor gap real de produto por evidência, sem presumir continuação de administração, SEO, Vehicle Hub, Ingestion, moderação ou qualquer candidato específico.

## Requisitos já congelados

- Listing nasce não público.
- Seller só altera anúncio de sua propriedade.
- Público nunca recebe Draft/private.
- Listing usa optimistic concurrency com `ConcurrencyStamp` no caminho da application service.
- Catálogo automotivo é autoridade canônica e Marketplace consome seus contratos.
- Fotos referenciam `MediaAssetId`; storage key/provider não é identidade de domínio do Marketplace.
- Public web é desacoplado do host ABP e consome a aplicação por HTTP/API.
- A primeira implementação do public web usa Next.js 16 Active LTS/App Router sem criar dependência de frontend nos módulos de backend.
- A primeira experiência Seller usa o mesmo cliente Next sob `/vender`, isolada por HTTP/OIDC e autenticada por Authorization Code + PKCE.
- A primeira experiência autenticada Buyer usa cliente OIDC público dedicado `BomPraTi_BuyerWeb`, também com Authorization Code + PKCE.
- Favorite pertence ao usuário autenticado derivado no servidor; o cliente não escolhe `UserId`.
- Favorite só é criado para Listing atualmente público e a lista do Buyer só projeta Listings que continuam públicos.
- A primeira experiência de discovery usa somente o contrato público já existente e mantém query string como estado SSR/compartilhável.
- O primeiro contato público Buyer → Seller usa o WhatsApp canônico pertencente a Sellers.
- O contato WhatsApp persiste Lead no Marketplace somente para Listing atualmente público; `UserId` continua opcional para contato anônimo.
- Se uma sessão Buyer válida já existir, o CTA pode encaminhá-la ao Lead API para que `ICurrentUser` atribua o `UserId`; login não é iniciado nem exigido pelo contato.
- Credencial Buyer usada no contato permanece restrita ao boundary same-origin/public-web → API BPT e nunca é enviada ao domínio do WhatsApp.
- Seller Lead inbox deriva ownership de `ICurrentUser` + `Listing.SellerId`; o cliente não escolhe Seller.
- Lead já persistido é histórico do contato e continua visível ao Seller owner mesmo se o Listing deixar de estar público.
- O estado operacional mínimo de atendimento é `ContactedAtUtc?`: nulo significa novo; o primeiro timestamp UTC significa atendido.
- Somente o Seller owner do Listing pode marcar o Lead como atendido, e chamadas repetidas preservam o primeiro instante.
- ListingReport pertence ao Buyer autenticado derivado no servidor; o cliente não escolhe `UserId`.
- Novo ListingReport só é criado para Listing atualmente público, é idempotente por Buyer+Listing e permanece como histórico depois que o Listing deixa de estar público.
- A primeira inbox de moderação é read-only, restrita à role `admin`, não expõe identidade/PII Buyer e preserva reports históricos mesmo quando o Listing deixa de estar público.
- A primeira superfície visual de moderação vive no host ABP existente em `/moderacao`, exige role `admin`, consome somente a inbox read-only já existente e não expõe identidade/PII Buyer.
- A primeira fatia de SEO técnico reutiliza a API pública como autoridade de indexabilidade: Draft/private não entra no sitemap, Publish inclui, Pause remove e o detalhe público publica canonical absoluto.
- A primeira superfície operacional de Ingestion é interna e restrita a `admin`; `(Source, ExternalId)` identifica o registro externo sem duplicação e reconciliation só aceita `Vehicle` confirmado por `Catalog.Contracts`.
- A primeira superfície visual de Ingestion vive no host ABP existente em `/ingestao`, exige role `admin`, consome somente `IIngestionCandidateAppService` e não substitui a validação canônica do Catalog.
- O primeiro Vehicle Hub usa `/veiculos/{id}` para um `Vehicle` canônico, lê sua identidade somente do Catalog e deriva ofertas somente da projeção pública filtrada por `VehicleId`; ausência de oferta não remove o Hub.
- Metadata social do Listing público deriva exclusivamente da mesma projeção pública e dos mesmos title/description/canonical; a primeira foto pública pode ser reutilizada como imagem social e ausência de foto não cria asset paralelo.
- Metadata social do Vehicle Hub deriva exclusivamente dos mesmos title/description/canonical da identidade canônica do Catalog; sem asset canônico próprio, não inventa imagem nem reutiliza foto de Listing como imagem do Vehicle.
- O primeiro hub administrativo vive em `/admin`, exige a role `admin` já existente e apenas navega para `/moderacao` e `/ingestao`; não consulta dados nem cria autoridade de negócio paralela.

O estado formal e a evidência dessas decisões ficam em `MDV.md` e `adr/` quando uma decisão exigir formalização adicional.

## Decisões ainda abertas

Só devem ser resolvidas quando houver necessidade de produto e evidência suficiente, por exemplo:

- analytics agregados, CRM, deduplicação, scoring, atribuição de marketing, notas/etapas de atendimento, exportação e resolução de perfil/PII Buyer para Leads;
- perfil Buyer, alertas e extensões de Favorites;
- taxonomia/motivo de denúncia, workflow e política de suspensão/remoção, scoring e notificações de moderação;
- menu/layout administrativo compartilhado, dashboard/métricas, permissões administrativas granulares e eventual frontend admin separado;
- JSON-LD/schema.org, metadata social da home/páginas agregadas, geração dedicada de social image, landing pages, estratégia de keywords/conteúdo, Search Console/analytics, cache/revalidation específica de sitemap e ranking SEO/search;
- connector/source concreto de ingestão, scraping/polling, matching automático, threshold de confidence, workflow de aprovação, background jobs e autocomplete/busca de Vehicle;
- promoções;
- enrichment do Vehicle Hub (specs, equipamentos, segurança, consumo, preço/mercado, editorial e imagens enriquecidas), páginas agregadas, slug final e sitemap completo do catálogo;
- schemas PostgreSQL separados por módulo;
- FK física entre módulos;
- estratégia final de busca quando benchmark exigir;
- distributed locks quando surgir disputa real que optimistic concurrency/UoW não resolvam;
- background jobs quando houver caso assíncrono real;
- object storage/provider final;
- eventual troca do framework do public web, se houver evidência que justifique — o boundary HTTP preserva essa reversibilidade.

## Regra de evolução

O BPT1 é donor, não chassis. Código, UX, dados ou regras do sistema anterior só entram quando demonstrarem valor para o produto atual. Sunk cost não é evidência arquitetural.
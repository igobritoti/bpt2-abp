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
- buscas salvas;
- leads e contato/WhatsApp;
- moderação;
- promoções;
- SEO;
- Vehicle Hub;
- administração;
- ingestão de fontes externas.

Estar no produto-alvo não significa estar no slice corrente. Capacidades adiadas só são promovidas quando houver necessidade e evidência.

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

## Estado entregue do produto

O histórico detalhado e a evidência executada de cada slice ficam em `exec-plans/completed/`. Este documento registra o estado de produto consolidado, não um changelog.

### Seller

O ciclo Seller está comprovado por HTTP/OIDC real:

`self-registration/login → profile → My Listings → Vehicle canônico → Draft/Edit → Photos → Publish/Pause/Archive → Leads próprios → marcar atendido`

Regras consolidadas:

- autenticação browser usa Authorization Code + PKCE pelo cliente `BomPraTi_SellerWeb`;
- ownership é decidido no servidor; o cliente não escolhe Seller;
- edição usa optimistic concurrency com `ConcurrencyStamp`;
- fotos usam Media/ListingPhoto sem expor storage key/provider como identidade de domínio;
- Draft/private nunca aparece ao público;
- Publish/Pause/Archive permanecem commands do backend;
- Leads históricos dos Listings próprios permanecem disponíveis mesmo depois de Pause/Archive;
- `ContactedAtUtc?` é o estado operacional mínimo de atendimento, monotônico e idempotente.

### Buyer e contato

O ciclo Buyer público/autenticado está comprovado por HTTP real:

`discovery → detalhe público → foto → favorito/busca salva/sinalização opcional → WhatsApp → Lead persistido`

Regras consolidadas:

- Favorites, SavedSearches e ListingReports pertencem ao usuário autenticado derivado no servidor;
- usuário auto-cadastrado consegue completar Favorites e ListingReports;
- Saved Search persiste somente critérios semânticos já suportados pela busca pública e permite listar/excluir apenas itens do próprio Buyer;
- critérios equivalentes são deduplicados; `Skip`, `Take`, página e `Sort` não compõem a identidade da busca salva;
- busca salva reabre resultados pelos filtros públicos atuais e não introduz matching privado, alerta, job ou canal de entrega por si só;
- contato WhatsApp pode ser anônimo; se já existir sessão Buyer válida, o Lead preserva o `UserId` autenticado sem tornar login obrigatório;
- token Buyer permanece restrito ao boundary same-origin/public-web → API BPT e nunca é enviado ao WhatsApp;
- novo Lead ou ListingReport só nasce para Listing atualmente público;
- histórico persistido não é apagado quando a oferta deixa de ser pública.

### Discovery público e SEO

A experiência pública permanece um cliente desacoplado do host ABP, em Next.js 16 Active LTS/App Router, consumindo a aplicação por HTTP.

Capacidades comprovadas:

- busca textual por título e identidade canônica Brand/Model/Generation/Version;
- filtros Brand, Model, ano, preço, quilometragem, City e StateCode;
- filtros combinados, paginação e preservação de estado pela query string;
- ordenação pública por preço;
- zero-results explícito;
- salvar a intenção semântica da busca para Buyer autenticado e reabrir resultados;
- detalhe público, galeria e CTA de WhatsApp;
- Seller Hub público;
- Vehicle Hub público;
- canonical, robots e sitemap;
- sitemap paginado de Vehicle Hubs e sitemap de Seller Hubs;
- metadata social de Listing, Vehicle Hub, Seller Hub e home;
- structured data de Listing e Vehicle Hub.

A auditoria de qualidade do Plan 0035 concluiu que fuzzy search, autocomplete, facets, ranking por relevância e engine externa não possuem evidência suficiente para promoção agora.

### Catálogo e Vehicle Hub

O Catalog é a autoridade de Brand → Model → Generation → Version → Vehicle.

Além da leitura canônica, existe superfície administrativa mínima para carga operacional da identidade automotiva, fechando o blocker de bootstrap identificado no Plan 0027.

O Vehicle Hub:

- lê identidade exclusivamente do Catalog;
- existe independentemente de oferta ativa;
- lista somente ofertas públicas daquele Vehicle;
- possui sitemap e structured data já comprovados.

Enrichment de specs/equipamentos/consumo/preço editorial/imagens continua separado da Structure e não é requisito do marketplace básico.

### Moderação

O fluxo mínimo operacional está fechado:

`Buyer sinaliza Listing público → report persistido → admin consulta fila → admin retira/restaura visibilidade pela autoridade mínima comprovada`

Regras consolidadas:

- Buyer é derivado de `ICurrentUser`;
- report é idempotente por Buyer+Listing;
- fila administrativa não expõe identidade/PII Buyer;
- reports permanecem como histórico;
- existe autoridade humana mínima para intervenção sobre visibilidade do Listing;
- taxonomia, scoring, notificações e workflow sofisticado continuam adiados.

### Ingestion

O fluxo manual mínimo está fechado:

`candidate externo → fila pendente → operador admin → lookup de Vehicle → reconciliação com Vehicle canônico`

Regras consolidadas:

- `(Source, ExternalId)` identifica o registro externo;
- primeiro payload/provenance permanece preservado;
- reconciliação só aceita Vehicle validado pelo Catalog;
- a UI administrativa possui lookup do catálogo em vez de exigir UUID cego;
- connector/source concreto, matching automático, threshold de confidence e background jobs continuam não decididos.

### Administração

O host ABP/LeptonXLite contém a superfície administrativa corrente:

`admin login → menu principal Operações → /admin`

O hub `/admin`:

- exige role `admin`;
- liga as superfícies operacionais já existentes;
- apresenta resumo operacional mínimo sem virar um dashboard analítico paralelo;
- usa navegação nativa ABP via `IMenuContributor`/`AbpNavigationOptions`;
- não substitui autorização server-side;
- não cria permission nova, override de tema/layout ou frontend administrativo separado.

A role `admin` continua suficiente para o baseline atual. Permissões administrativas granulares só devem ser promovidas quando aparecer necessidade real de separar autoridades.

## Requisitos congelados

- Listing nasce não público.
- Seller só altera anúncio de sua propriedade.
- Público nunca recebe Draft/private.
- Listing usa optimistic concurrency com `ConcurrencyStamp` no caminho da application service.
- Catálogo automotivo é autoridade canônica e Marketplace/Ingestion consomem seus contratos, não sua implementação.
- Fotos referenciam `MediaAssetId`; storage key/provider não é identidade de domínio do Marketplace.
- Public web é desacoplado do host ABP e consome a aplicação por HTTP/API.
- Seller e Buyer usam clientes OIDC públicos dedicados com Authorization Code + PKCE.
- Favorite, SavedSearch, ListingReport e ownership Seller derivam identidade do servidor; o browser não escolhe owner.
- A busca pública preserva query string como estado compartilhável e não expõe Draft/private.
- Saved Search não persiste paginação/ordenação como identidade semântica e não implica alerta automaticamente.
- City/StateCode são filtros textuais canônicos atuais; isso não implica geocoding, radius ou autoridade geográfica nova.
- WhatsApp canônico pertence a Sellers e o Lead é persistido antes do redirect externo.
- Lead já ocorrido é histórico e não desaparece quando o Listing deixa de ser público.
- A moderação mínima é humana e server-side; esconder/mostrar UI não cria autoridade.
- A carga operacional mínima do catálogo usa os aggregates canônicos atuais; fonte externa não vira fonte de verdade.
- Ingestion reconcilia para Vehicle canônico somente após validação pelo Catalog.
- O hub `/admin` e o item global `Operações` usam a role `admin` existente; permission granular permanece adiada.
- IA, engine externa, jobs e infraestrutura distribuída não entram no core sem caso real.

O estado formal das decisões e a força da evidência ficam em `MDV.md` e `adr/`; detalhes de execução ficam nos plans concluídos.

## Slice ativo

O Plan 0049 permanece ativo para concluir progressivamente as capabilities pós-MVP.

O Saved Search baseline está entregue. A próxima boundary é testar o contrato mínimo de **alerta de nova oferta compatível** reutilizando a intenção persistida da busca salva. Isso não autoriza presumir background job, scheduler, provider ou canal antes de provar o requisito.

Comparator continua bloqueado por enrichment técnico publicado suficiente do Podium; esse blocker não impede a trilha independente de retenção Buyer.

## Decisões ainda abertas

Só devem ser resolvidas quando houver necessidade de produto e evidência suficiente:

- analytics agregados, CRM, deduplicação, scoring, atribuição de marketing, notas/etapas, exportação e resolução de perfil/PII Buyer para Leads;
- perfil Buyer, alertas de nova oferta compatível, price-drop e preferências/opt-in/unsubscribe;
- taxonomia/motivo de denúncia, workflow multiestado, scoring e notificações de moderação;
- permissões administrativas granulares e eventual frontend admin separado;
- geração dedicada de social image, landing pages, estratégia editorial/keywords, Search Console/analytics e ranking SEO/search;
- geocoding/GPS, raio/distância, bairros/CEP, autocomplete/facets de localização, ranking por proximidade e landing pages/SEO locais;
- connector/source concreto de ingestão, scraping/polling, matching automático, threshold de confidence, workflow de aprovação e background jobs;
- promoções/boost comercial;
- enrichment do Vehicle Hub — specs, equipamentos, segurança, consumo, preço/mercado, editorial e imagens enriquecidas — além de páginas agregadas e slugs semânticos;
- schemas PostgreSQL separados por módulo;
- FK física entre módulos;
- estratégia final de busca quando benchmark/carga justificar;
- distributed locks quando surgir disputa real que optimistic concurrency/UoW não resolvam;
- background jobs quando houver caso assíncrono real;
- object storage/provider final quando a topologia exigir;
- eventual troca do framework do public web se houver evidência que justifique — o boundary HTTP preserva a reversibilidade.

## Regra de evolução

O BPT1 é donor, não chassis. Código, UX, dados ou regras do sistema anterior só entram quando demonstrarem valor para o produto atual. Sunk cost não é evidência arquitetural.

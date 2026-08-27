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
- ingestão/publicação de conhecimento externo.

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

BPT é a autoridade do catálogo publicado consumido pelo marketplace. Podium 7 é o bounded context produtor/feed de conhecimento automotivo externo; acquisition, evidence, normalization, entity resolution e reconciliation não devem ser duplicados no BPT2.

Separações conceituais:

- **Structure:** Brand, Model, Generation, Version, Vehicle.
- **Enrichment:** specs, equipamentos, segurança, consumo, preço/mercado, editorial, imagens enriquecidas.
- **Knowledge producer/feed:** aquisição, evidence, normalization, reconciliation, provenance e conflitos pertencem ao Podium; o BPT2 projeta somente contratos publicados suficientemente definidos.

A identidade Podium não é assumida 1:1 com `VehicleId` BPT2. Uma identidade externa pode projetar zero, um ou vários Vehicles publicados; labels não são chave de integração.

## Estado entregue do produto

O histórico detalhado e a evidência executada de cada slice ficam em `exec-plans/completed/` e `audits/`. Este documento registra o estado de produto consolidado, não um changelog.

### Seller

O ciclo Seller está comprovado por HTTP/OIDC real:

`self-registration/login → profile → My Listings → Vehicle canônico → Draft/Edit → Photos → Publish/Pause/Archive → Leads próprios → marcar atendido → fechar Won/Lost`

Regras consolidadas:

- autenticação browser usa Authorization Code + PKCE pelo cliente `BomPraTi_SellerWeb`;
- ownership é decidido no servidor; o cliente não escolhe Seller;
- edição usa optimistic concurrency com `ConcurrencyStamp`;
- fotos usam Media/ListingPhoto sem expor storage key/provider como identidade de domínio;
- Draft/private nunca aparece ao público;
- Publish/Pause/Archive permanecem commands do backend;
- Leads históricos dos Listings próprios permanecem disponíveis mesmo depois de Pause/Archive;
- `ContactedAtUtc?` representa o atendimento mínimo, monotônico e idempotente;
- Lead pode ser fechado como `Won` ou `Lost`; repetir o mesmo outcome é idempotente e outcome conflitante é rejeitado.

### Buyer e contato

O ciclo Buyer público/autenticado está comprovado por HTTP real:

`discovery → detalhe público → foto → favorito/busca salva/sinalização opcional → WhatsApp → Lead persistido`

Regras consolidadas:

- Favorites, SavedSearches e ListingReports pertencem ao usuário autenticado derivado no servidor;
- usuário auto-cadastrado consegue completar Favorites e ListingReports;
- Saved Search persiste somente critérios semânticos já suportados pela busca pública e permite listar/excluir apenas itens do próprio Buyer;
- critérios equivalentes são deduplicados; `Skip`, `Take`, página e `Sort` não compõem a identidade da busca salva;
- busca salva reabre resultados pelos filtros públicos atuais;
- Saved Search possui opt-in explícito de alerta, timestamp de habilitação e ledger idempotente `(SavedSearchId, ListingId)` para detecção;
- matching de nova oferta reutiliza a mesma semântica da busca pública e considera apenas Listing pública;
- primeira publicação persiste uma `SavedSearchAlertDetectionRequest` durável e única por Listing no mesmo UoW, sem varrer todas as buscas no request de publicação;
- runner automático e delivery de alertas permanecem não entregues; nenhum provider/canal foi escolhido;
- histórico seguro de preço de Listing publicada é persistido; Draft e preço sem alteração não criam histórico;
- detector de price-drop de Favorite está entregue: queda de preço em Listing publicada cria ledger apenas para Buyers que já tinham favoritado antes da queda; replay é idempotente, Favorite posterior não recebe retroativo, aumento é ignorado e unfavorite impede match futuro;
- contato WhatsApp pode ser anônimo; se já existir sessão Buyer válida, o Lead preserva o `UserId` autenticado sem tornar login obrigatório;
- token Buyer permanece restrito ao boundary same-origin/public-web → API BPT e nunca é enviado ao WhatsApp;
- novo Lead ou ListingReport só nasce para Listing atualmente público;
- histórico persistido não é apagado quando a oferta deixa de ser pública.

### Discovery público e SEO

A experiência pública permanece um cliente desacoplado do host ABP, em Next.js 16/App Router, consumindo a aplicação por HTTP.

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

Fuzzy search, autocomplete, facets, ranking por relevância, geo/radius, similaridade e engine externa não possuem hoje corpus + baseline + métrica suficientes para promoção.

### Catálogo e Vehicle Hub

O Catalog é a autoridade de Brand → Model → Generation → Version → Vehicle publicados no BPT2.

Além da leitura canônica, existe superfície administrativa mínima para carga operacional da identidade automotiva.

O Vehicle Hub:

- lê identidade exclusivamente do Catalog;
- existe independentemente de oferta ativa;
- lista somente ofertas públicas daquele Vehicle;
- possui sitemap e structured data comprovados.

Enrichment técnico amplo continua separado da Structure. O contrato consumer de identidade do Podium é insuficiente, por si só, para uma ficha comparável de potência/torque/consumo/dimensões/equipamentos; Comparator 2–4 permanece bloqueado até existir enrichment publicado com unidade, null/unknown, revision e provenance suficientes.

### Moderação

O fluxo mínimo operacional está fechado:

`Buyer sinaliza Listing público → report persistido → admin consulta fila → admin retira/restaura visibilidade pela autoridade mínima comprovada`

Regras consolidadas:

- Buyer é derivado de `ICurrentUser`;
- report é idempotente por Buyer+Listing;
- fila administrativa não expõe identidade/PII Buyer;
- reports permanecem como histórico;
- existe autoridade humana mínima para intervenção sobre visibilidade do Listing;
- taxonomia, anexos/evidence, SLA, scoring, notificações e trust signals de provider continuam adiados até problema operacional ou contrato externo justificá-los.

### Promoções

Existe baseline patrocinado separado do ranking orgânico:

- promoção possui janela temporal explícita;
- Listing ativa dentro da janela projeta `IsSponsored=true`;
- futura/expirada não projeta patrocínio ativo;
- Draft/private permanece invisível mesmo com promoção;
- UI pública identifica visualmente `Patrocinado`;
- ordenação orgânica padrão, `price-asc` e `price-desc` não é alterada pela promoção;
- não foi portado `HighlightScore` do BPT1.

Planos comerciais, eligibility avançada, prioridade entre campanhas e instrumentação dedicada de impressão/click/Lead continuam dependentes de tese comercial e hipótese mensurável.

### Ingestion / knowledge feed

O BPT2 mantém os contratos legados de ingestão manual já existentes, mas a direção arquitetural corrente para conhecimento automotivo externo é:

`Podium producer/feed → contrato versionado publicado → projeção BPT2 → catálogo publicado BPT2`

Regras consolidadas:

- BPT2 não deve duplicar aquisição/evidence/reconciliation já pertencentes ao Podium;
- integração consome contrato, não persistence/shared DB;
- correções preservam identidade externa estável e redirects/historical IDs não devem ser resolvidos por labels;
- public marketplace read path não depende de Podium online;
- connector/source, polling/scraping e matching automático dentro do BPT2 não são promovidos sem novo requisito.

### Administração

O host ABP/LeptonXLite contém a superfície administrativa corrente:

`admin login → menu principal Operações → /admin`

O hub `/admin`:

- exige role `admin`;
- liga as superfícies operacionais existentes;
- apresenta resumo operacional mínimo sem virar dashboard analítico paralelo;
- usa navegação nativa ABP via `IMenuContributor`/`AbpNavigationOptions`;
- não substitui autorização server-side;
- não cria permission nova, override de tema/layout ou frontend administrativo separado.

A role `admin` continua suficiente para o baseline atual. Permissões granulares só devem ser promovidas quando aparecer necessidade real de separar autoridades.

## Requisitos congelados

- Listing nasce não público.
- Seller só altera anúncio de sua propriedade.
- Público nunca recebe Draft/private.
- Listing usa optimistic concurrency com `ConcurrencyStamp` no caminho da application service.
- Catálogo automotivo publicado é autoridade do BPT2; Marketplace consome contratos do Catalog.
- Podium é knowledge producer/feed e não entra no request path público.
- Fotos referenciam `MediaAssetId`; storage key/provider não é identidade de domínio do Marketplace.
- Public web é desacoplado do host ABP e consome a aplicação por HTTP/API.
- Seller e Buyer usam clientes OIDC públicos dedicados com Authorization Code + PKCE.
- Favorite, SavedSearch, ListingReport e ownership Seller derivam identidade do servidor; o browser não escolhe owner.
- A busca pública preserva query string como estado compartilhável e não expõe Draft/private.
- Saved Search não persiste paginação/ordenação como identidade semântica.
- Alert opt-in é explícito; detecção e delivery são boundaries separados.
- City/StateCode são filtros textuais canônicos atuais; isso não implica geocoding, radius ou autoridade geográfica nova.
- WhatsApp canônico pertence a Sellers e o Lead é persistido antes do redirect externo.
- Lead já ocorrido é histórico e não desaparece quando o Listing deixa de ser público.
- A moderação mínima é humana e server-side; esconder/mostrar UI não cria autoridade.
- Promoção patrocinada não altera ranking orgânico no baseline.
- IA, engine externa, jobs e infraestrutura distribuída não entram no core sem caso real.

O estado formal das decisões e a força da evidência ficam em `MDV.md` e `adr/`; detalhes de execução ficam nos plans/audits.

## Slice ativo

**Nenhum execution plan funcional está ativo.**

O último roadmap amplo, Plan 0049, foi concluído por classificação. O Plan 0051/PR #82 fechou o probe de Favorite price-drop e foi mergeado após o contrato congelado passar integralmente no CI do head exato.

O snapshot corrente de trabalho e blockers está em `agent/CURRENT-WORK.md`; o checkpoint histórico anterior permanece em `audits/2026-08-26-post-plan0050-trigger-sweep.md`.

## Decisões ainda abertas / gatilhos

Só resolver quando houver necessidade de produto e evidência suficiente:

- deployment/locking + claim/concurrency/retry/restart para runner de Saved Search; ABP Background Jobs não elimina a necessidade de distributed lock real em cluster;
- enrichment técnico publicado do Podium para Comparator e Vehicle Hub enriquecido;
- analytics agregados, scoring, atribuição de marketing, notas/etapas adicionais e exportação de Leads somente se houver pergunta operacional concreta;
- taxonomia/motivo de denúncia, workflow multiestado, SLA, anexos/evidence, scoring e notificações de moderação;
- permissões administrativas granulares e eventual frontend admin separado;
- geração dedicada de social image, landing pages, estratégia editorial/keywords, Search Console/analytics e ranking SEO/search;
- geocoding/GPS, raio/distância, bairros/CEP, autocomplete/facets, ranking por proximidade e SEO local;
- corpus + baseline + métrica para relevance/ranking, similar vehicles e upgrade suggestions;
- instrumentação comercial de promoções e planos/pagamentos de promoção quando houver tese comercial;
- inteligência de mercado quando houver dataset/licença/metodologia/provenance exibível;
- Compra Assistida, financiamento, seguros e credits/payments quando parceria/modelo comercial justificar;
- schemas PostgreSQL separados por módulo e FK física entre módulos somente se houver necessidade medida;
- object storage/provider final quando a topologia exigir;
- eventual troca do framework do public web se houver evidência que justifique — o boundary HTTP preserva reversibilidade;
- inventário Carros na Web quando o acesso atual for reproduzível o suficiente para calcular cobertura sem denominador artificial.

## Regra de evolução

O BPT1 é donor, não chassis. Código, UX, dados ou regras do sistema anterior só entram quando demonstrarem valor para o produto atual. Sunk cost não é evidência arquitetural.

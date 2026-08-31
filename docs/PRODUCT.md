# Produto — BPT2 / Bom Pra Ti

## Objetivo

Bom Pra Ti é um marketplace/classificados automotivo brasileiro. O núcleo do produto é conectar vendedores e compradores em torno de anúncios de veículos com identidade automotiva canônica, discovery público, confiança, conteúdo e contato. Não é objetivo transformar o baseline em um e-commerce tradicional de mercadorias.

## Regra de evolução

O estado entregue é decidido por código/teste executado e evidência consolidada. Uma capacidade mencionada em donor, benchmark ou issue não vira requisito automaticamente. O BPT1 é donor, não chassis; sunk cost não é evidência arquitetural.

Podium 7 é o knowledge producer/feed para conhecimento automotivo externo. Aquisição, evidence, normalization, entity resolution, reconciliation e provenance pertencem ao produtor; o BPT2 consome contratos versionados e preserva sua própria autoridade de publicação/IDs.

## Estado entregue do produto

### Seller

O ciclo Seller está comprovado por HTTP/OIDC real:

`self-registration/login → profile → My Listings → Vehicle canônico → Draft/Edit → Photos → Publish/Pause/Archive → Leads próprios → marcar atendido → fechar Won/Lost`

Regras consolidadas:

- browser usa Authorization Code + PKCE pelo cliente Seller público dedicado;
- ownership é derivado no servidor;
- edição usa `ConcurrencyStamp`/optimistic concurrency;
- fotos referenciam `MediaAssetId`; storage provider/key não é identidade de domínio;
- Draft/private nunca aparece ao público;
- Publish/Pause/Archive permanecem commands do backend;
- Leads históricos dos Listings próprios permanecem consultáveis depois de Pause/Archive;
- `ContactedAtUtc?` é monotônico/idempotente;
- Lead pode fechar `Won` ou `Lost`; replay do mesmo outcome é idempotente e conflito é rejeitado.

### Buyer, favoritos e contato

O ciclo Buyer público/autenticado está comprovado por HTTP real:

`discovery → detalhe público → favorito/busca salva/sinalização opcional → WhatsApp → Lead persistido`

- Favorite, Saved Search e Listing Report pertencem ao usuário autenticado derivado no servidor;
- Buyer auto-cadastrado completa Favorites e Listing Reports;
- WhatsApp pode ser usado anonimamente; sessão Buyer válida preserva `UserId` no Lead sem tornar login obrigatório;
- Lead é persistido antes do redirect externo;
- novo Lead/Report só nasce para Listing atualmente pública;
- histórico já persistido não é apagado quando a oferta deixa de ser pública;
- detector de price-drop de Favorite está entregue com temporal eligibility e replay idempotente;
- `/favoritos` expõe histórico ownership-safe de price-drops detectados, inclusive depois de unfavorite;
- delivery externo de price-drop continua capability separada e não está autorizada apenas pelo ato de favoritar.

### Saved Search

Saved Search está entregue além da simples persistência de filtros:

- persiste somente critérios semânticos suportados pela busca pública;
- critérios equivalentes são deduplicados; paginação/ordenação não compõem identidade da busca salva;
- busca salva pode ser reaberta pelos filtros públicos atuais;
- `AlertEnabled` é opt-in explícito de monitoramento e continua separado de autorização de canal externo;
- primeira publicação cria `SavedSearchAlertDetectionRequest` durável e única por Listing no mesmo UoW;
- runner automático de detecção está entregue com claim PostgreSQL, `FOR UPDATE SKIP LOCKED`, retry diferido, non-starvation e cancellation correctness;
- matching reutiliza a semântica da busca pública e considera somente Listing pública;
- ledger ownership-safe de novas ofertas é exposto em `/buscas-salvas`;
- email externo usa autorização explícita por busca `EMAIL_EACH_NEW_MATCH`, default OFF e independente de `AlertEnabled`;
- recipient é resolvido no dispatch a partir do Identity atual ativo+confirmado; endereço de email não é copiado para o Marketplace;
- delivery intent é durável, provider-neutral e usa idempotency key estável;
- runner de dispatch preserva `Accepted != Delivered`, transient/permanent/unknown outcomes e suppression por opt-out/deletion/ineligibility;
- primeiro adapter/probe é Resend; webhook é autenticado e replay converge por ledger atômico;
- open/click tracking não é autorizado;
- credenciais, sender/domain, DPA/legal/commercial approval e ativação de produção são deployment externo e não tornam o boundary de engenharia #118 incompleto.

### Discovery público

A experiência pública é um cliente Next.js/App Router desacoplado do host ABP e consome a aplicação por HTTP.

Capacidades comprovadas:

- busca textual por título e identidade canônica Brand/Model/Generation/Version;
- seleção guiada de Vehicle canônico; valor semântico selecionado é `VehicleId`;
- filtros Brand, Model, Color, ano, preço, quilometragem, City e StateCode;
- Color usa trim + igualdade textual case-insensitive, sem taxonomia/sinônimos inventados;
- filtros compõem, preservam query string e paginação;
- ordenação pública por preço e `recent-desc`;
- `FirstPublishedAtUtc?` nasce na primeira publicação; pause/re-publish não cria bump e legado sem evidência permanece `null`;
- zero-results explícito;
- detalhe público, galeria, CTA WhatsApp, Seller Hub e Vehicle Hub;
- Seller Hub usa autoridade pública de seller e permanece válido mesmo sem inventário público, mostrando estado vazio sem vazar contagens privadas;
- apresentação textual agora trata hífen ASCII e espaço como equivalentes no discovery de identidade canônica (`T Cross` ↔ `T-Cross`), após comparação no corpus congelado #112 sem regressão de exact/confusable/prefix/facets;
- typo tolerance continua não entregue: o benchmark atual ainda mede 0 de recall/MRR para os três typos congelados sob a semântica de produção corrente.

Advanced Discovery possui corpus/qrels reproduzíveis. Tecnologia fuzzy, score threshold, aliases, FTS, `pg_trgm`, Levenshtein em produção ou engine externa só podem ser promovidos após experimento pré-declarado sob o mesmo corpus e sem transformar defaults de biblioteca em política de produto.

### SEO

- canonical, robots e sitemaps estão entregues;
- sitemap de Vehicle Hubs e Seller Hubs está comprovado;
- metadata social e structured data existem para as superfícies cobertas;
- social image dedicada, SEO local/editorial e estratégia de keywords permanecem dependentes de pergunta/hypótese própria.

### Catálogo e Vehicle Hub

Catalog é autoridade de Brand → Model → Generation → Version → Vehicle publicados no BPT2.

- Vehicle Hub existe independentemente de oferta ativa e lista somente ofertas públicas do Vehicle;
- identidade do Hub vem exclusivamente do Catalog;
- `powertrain`, `transmission` e `body_style` são projetados como strings opacas nullable do Podium Contract 2.0, sem taxonomia local;
- `external_identifiers` producer-owned são sincronizados como estado corrente, preservando `Authority + Namespace + Value`, replay/correction/clear/redirect e collision fail-closed;
- labels não são chave persistida para provider binding e rematch fuzzy por labels é rejeitado;
- Podium publica `podium7.quantitative-enrichment.v1`;
- benchmark BPT2 #122 provou consumer lossless, revision/provenance/state/shape, replay/correction/conflict e comparabilidade conservadora no corpus delimitado;
- essa prova não autoriza automaticamente ficha técnica quantitativa ampla, filtros públicos ou Comparator: cobertura Brasil/produção e produto concreto continuam necessários.

### Ingestion / knowledge feed

Boundary estrutural entregue:

`Podium producer/feed → contrato versionado → Ingestion BPT2 → Catalog BPT2 → Marketplace/Vehicle Hub`

- `podium7/entity.id` é preservado como identidade externa estável;
- `redirectsFrom` converge para o mesmo `VehicleId`;
- replay é idempotente;
- `variant = null` falha explicitamente porque o domínio exige Version;
- model-year range não é achatado arbitrariamente em valor escalar;
- BPT2 não depende de Podium online no request path público;
- scraping/polling/entity resolution do produtor não são duplicados dentro do BPT2.

### Leads e moderação

- Seller inbox e `MarkContacted` estão entregues;
- Lead fecha Won/Lost sem promover pipeline CRM especulativo;
- Buyer Report é idempotente por Buyer+Listing;
- admin possui fila mínima e autoridade server-side para retirar/restaurar Listing;
- reports permanecem históricos e a fila não expõe PII Buyer;
- taxonomia ampla, SLA, evidence attachments, scoring e notificações dependem de problema operacional/contrato próprio.

### Promoções

Sponsored Listing baseline está entregue:

- janela temporal explícita;
- badge `Patrocinado` na UI;
- Draft/private não fica público por promoção;
- promoção não altera ranking orgânico baseline;
- `HighlightScore` donor não foi portado;
- planos/billing/credits/payments e instrumentação comercial ampla dependem de tese comercial mensurável.

### Administração

- host ABP/LeptonXLite possui hub `/admin` protegido por role `admin`;
- hub liga superfícies operacionais existentes sem criar dashboard analítico paralelo;
- autorização permanece server-side;
- permissões granulares ou frontend admin separado só entram quando houver necessidade real de separar autoridades.

## Requisitos congelados

- Listing nasce não público e Seller só altera anúncio próprio.
- Público nunca recebe Draft/private.
- Listing usa optimistic concurrency no application boundary.
- primeira publicação define `FirstPublishedAtUtc`; republish não renova o instante.
- Catalog publicado é autoridade automotiva do BPT2; Marketplace consome seus contratos.
- Podium é knowledge producer/feed e não entra no request path público.
- fotos referenciam MediaAsset por ID de domínio, não por storage key/provider.
- Seller/Buyer browser usam clientes OIDC públicos dedicados com Authorization Code + PKCE.
- ownership de Seller/Favorite/SavedSearch/Report é derivado no servidor.
- query string é estado compartilhável da busca pública e nunca autoriza exposição de Draft/private.
- Saved Search não transforma paginação/ordenação em identidade semântica.
- monitoramento de Saved Search e autorização de email são decisões distintas; `AlertEnabled` não é consentimento de email.
- City/StateCode e código IBGE de município não implicam ponto físico do veículo.
- moderação mínima é humana/server-side; esconder UI não cria autoridade.
- Sponsored não altera ranking orgânico baseline.
- broker, Redis, Kubernetes, engine externa ou nova infraestrutura não entram no core sem necessidade medida; runners duráveis entram somente quando há work queue/side effect concreto e coordenação provada.

## Boundaries ainda bloqueados / gatilhos válidos

- **Recommendations (#113):** precisa de qrel humano para pergunta explícita ou behavioral data exposure-aware. Favorite/Lead positivos sem exposição não criam negativos válidos.
- **Market intelligence (#114):** stable provider identifier binding já existe; falta definir a quantidade de produto e obter provider/dataset com licença, metodologia, provenance, coverage e direitos de uso verificáveis.
- **Trust/history/inspection (#115):** precisa de provider autorizado, identidade da instância física do Listing, purpose/privacy/retention/correction e semantics verificáveis da assertion.
- **True radius (#116):** município IBGE está resolvido; falta autoridade do ponto físico da Listing, provenance/precision/lifecycle e privacy/minimization. Centroide municipal não é localização do veículo.
- **Typo tolerance:** pode ser investigada por benchmark controlado; nenhum cutoff/default de extensão é requisito de produto por si só.
- **Comparator/ficha técnica ampla:** depende de cobertura Brasil/produção e produto concreto além do consumer/comparability boundary já provado.
- **Favorite price-drop externo:** exige autorização de canal/destinatário e recovery/idempotency próprios.
- **Attribution/analytics, Compra Assistida, financiamento, seguros, billing/credits, SEO editorial/local:** só promovidos com pergunta operacional/comercial concreta e contracts necessários.

## Fonte de estado operacional

O snapshot de trabalho corrente, PRs/checks e próximo experimento fica em `agent/CURRENT-WORK.md`. Evidência detalhada permanece em `audits/`, execution plans concluídos e GitHub Actions do commit correspondente.

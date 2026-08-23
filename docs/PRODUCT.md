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

O primeiro ciclo real do comprador também foi concluído e comprovado por HTTP real:

`Public Listing → Public Detail → Photo → WhatsApp Contact`

A experiência pública é um cliente independente da API conforme ADR-0004. A primeira implementação usa Next.js 16 Active LTS/App Router conforme ADR-0009, mantendo o boundary HTTP reversível.

O domínio Sellers já modela e normaliza `WhatsAppNumber`; a projeção pública de Listing entrega esse valor ao public web e o CTA usa `https://wa.me/{digits}`. Não há requisito comprovado para persistir um agregado de Lead apenas para abrir esse contato inicial. Persistência/analytics de leads será decidida quando houver requisito de registrar, acompanhar ou medir contatos.

## Slice ativo

Execution Plan 0004 fecha a experiência operacional do vendedor sobre APIs e regras já comprovadas:

`Seller login → Seller profile → My Listings → Draft/Edit → Vehicle selection → Photos → Publish → Public Listing`

A primeira decisão do plano é provar a fronteira de UI/auth do Seller com Authorization Code + PKCE. O password grant permanece restrito aos smokes/fixtures e não será usado como login de produto. O BPT1 continua donor, não chassis; código/UX antigo só será transplantado quando houver fonte concreta auditável e valor demonstrado.

## Requisitos já congelados

- Listing nasce não público.
- Seller só altera anúncio de sua propriedade.
- Público nunca recebe Draft/private.
- Listing usa optimistic concurrency com `ConcurrencyStamp` no caminho da application service.
- Catálogo automotivo é autoridade canônica e Marketplace consome seus contratos.
- Fotos referenciam `MediaAssetId`; storage key/provider não é identidade de domínio do Marketplace.
- Public web é desacoplado do host ABP e consome a aplicação por HTTP/API.
- A primeira implementação do public web usa Next.js 16 Active LTS/App Router sem criar dependência de frontend nos módulos de backend.
- O primeiro contato público Buyer → Seller usa o WhatsApp canônico já pertencente a Sellers; isso não implica Lead persistido.

O estado formal e a evidência dessas decisões ficam em `MDV.md` e `adr/`.

## Decisões ainda abertas

Só devem ser resolvidas quando houver necessidade de produto e evidência suficiente, por exemplo:

- persistência/analytics/CRM de Leads;
- schemas PostgreSQL separados por módulo;
- FK física entre módulos;
- estratégia final de busca quando benchmark exigir;
- distributed locks quando surgir disputa real que optimistic concurrency/UoW não resolvam;
- background jobs quando houver caso assíncrono real;
- object storage/provider final;
- eventual troca do framework do public web, se houver evidência que justifique — o boundary HTTP preserva essa reversibilidade.

## Regra de evolução

O BPT1 é donor, não chassis. Código, UX, dados ou regras do sistema anterior só entram quando demonstrarem valor para o produto atual. Sunk cost não é evidência arquitetural.

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

Algumas dessas capacidades ainda estão adiadas no plano de implementação atual. Estar no produto-alvo não significa estar no slice corrente.

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

## Slice de implementação ativo

Sequência principal:

`Seller → Vehicle → Listing → Publish → Public Listing Query`

Primeiro incremento de produto após o Gate 01:

1. consolidar Seller;
2. consolidar Catalog/Vehicle;
3. completar Listing CRUD e publicação pela API real;
4. garantir leitura pública somente de anúncios publicáveis;
5. integrar Media/fotos em seguida.

## Requisitos já congelados

- Listing nasce não público.
- Seller só altera anúncio de sua propriedade.
- Público nunca recebe Draft/private.
- Listing usa optimistic concurrency com `ConcurrencyStamp` no caminho da application service.
- Catálogo automotivo é autoridade canônica e Marketplace consome seus contratos.
- Fotos referenciam `MediaAssetId`; storage key/provider não é identidade de domínio do Marketplace.

O estado formal e a evidência dessas decisões ficam em `MDV.md` e `adr/`.

## Decisões ainda abertas

Só devem ser resolvidas quando houver necessidade de produto e evidência suficiente, por exemplo:

- frontend específico;
- schemas PostgreSQL separados por módulo;
- FK física entre módulos;
- estratégia final de busca quando benchmark exigir;
- distributed locks quando surgir disputa real que optimistic concurrency/UoW não resolvam;
- background jobs quando houver caso assíncrono real;
- object storage/provider final.

## Regra de evolução

O BPT1 é donor, não chassis. Código, UX, dados ou regras do sistema anterior só entram quando demonstrarem valor para o produto atual. Sunk cost não é evidência arquitetural.

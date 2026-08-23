# Execution Plan 0003 — Public Buyer → WhatsApp

Status: **ATIVO**

## Objetivo

Transformar o backend público já comprovado no primeiro fluxo utilizável por um comprador real, mantendo o frontend desacoplado do host ABP:

`Public Listing → Public Detail → WhatsApp Contact`

O objetivo deste plano é provar o primeiro consumidor público e fechar o ciclo mínimo comprador→vendedor. Não é criar toda a experiência final do marketplace.

## Contexto congelado

- Product Baseline 0001 concluído.
- ADR-0004 já decide que a experiência pública/SEO é um cliente independente da API e não vive dentro do host ABP.
- A API pública já expõe listagem paginada, detalhe, Seller, Vehicle, fotos e conteúdo público de fotos.
- `Sellers.Contracts` já modela `SellerPublicContactDto` com `DisplayName` e `WhatsAppNumber`; o Marketplace já consome esse contrato para projetar Seller público, mas hoje omite o WhatsApp do DTO de Listing.
- Draft/private continua estruturalmente indisponível na superfície pública.
- Nenhuma necessidade comprovada exige Lead persistido, chat, broker, background job ou engine de busca externo neste fluxo.
- A escolha do framework público deve permanecer reversível porque a fronteira com o backend é HTTP/API.

## Escopo

### Fase 1 — fundação do public web

- materializar um frontend público independente do host ABP;
- usar Next.js 16 Active LTS com App Router para a primeira implementação;
- consumir o backend somente por HTTP/API;
- renderizar listagem e detalhe públicos sem autenticação do comprador;
- manter código/tipos React/Next fora dos assemblies Catalog, Sellers, Marketplace, Media e Ingestion;
- adicionar gate próprio de build/type/lint do public web.

### Fase 2 — contato por WhatsApp

- expor `WhatsAppNumber` já existente no contrato público de Seller pela projeção pública de Listing;
- usar o formato canônico já imposto por `SellerProfile`: somente dígitos, entre 8 e 15, incluindo country code;
- renderizar CTA de contato no detalhe público;
- não expor contato por associação a Draft/private.

### Fase 3 — prova do fluxo público

- comprovar o caminho real `listagem → detalhe → CTA` contra o backend real;
- manter as regressões existentes relevantes verdes;
- adicionar metadata pública mínima no detalhe para título/descrição e base de SEO;
- registrar explicitamente o que permanece fora do fluxo após a prova.

## Fora de escopo

- Lead persistido, CRM, analytics de conversão ou chat;
- Favorites;
- login/conta do comprador;
- moderação/administração completa;
- promoções/pagamentos;
- Vehicle Hub;
- ingestão/reconciliation de fontes externas;
- object storage provider final;
- engine de busca externo;
- mudança dos boundaries modulares do backend;
- migração da administração ABP para o public web.

## Critérios de aceite

1. [x] Public web é projeto independente e não adiciona dependência de frontend aos módulos de domínio/backend.
2. [x] Build, typecheck/lint e gate do public web passam em CI no commit integrável.
3. [ ] Página pública de listagem consome a API real e apresenta somente anúncios publicáveis.
4. [ ] Página pública de detalhe consome a API real e apresenta Seller + Vehicle + fotos + fatos do anúncio.
5. [ ] Contato WhatsApp vem do contrato público de Seller existente e chega ao detalhe sem expor storage internals nem dados privados adicionais.
6. [ ] CTA de WhatsApp usa número validado/normalizado de forma determinística.
7. [ ] Draft/private continua indisponível pelo site público e por qualquer endpoint usado pelo frontend.
8. [ ] Detalhe público produz metadata mínima coerente com o anúncio.
9. [ ] Fluxo real `listagem → detalhe → CTA` é comprovado por teste mínimo reproduzível.
10. [ ] Gates existentes relevantes permanecem verdes e a documentação canônica reflete o comportamento final.

## Checkpoints

- [x] Selecionar o menor gap de usuário após o Product Baseline.
- [x] Confirmar boundary do frontend público contra ADR-0004.
- [x] Confirmar que contato público de Seller/WhatsApp já existe em `Sellers.Contracts`.
- [x] Materializar public web e gate próprio.
- [ ] Expor WhatsApp na projeção pública mínima.
- [ ] Implementar listagem/detalhe/CTA.
- [ ] Provar fluxo real contra backend.
- [ ] Revisar necessidade de MDV/ADR adicional.
- [ ] Encerrar plano com resultado e pendências explícitas.

## Decisões abertas permitidas durante o plano

Resolver somente quando bloquearem um critério de aceite:

- URL/shape final de navegação pública do anúncio;
- conjunto mínimo de filtros e sorting exigido pelo primeiro consumidor;
- estratégia de cache/revalidation somente se o primeiro fluxo demonstrar necessidade.

Não decidir neste plano Lead persistido, busca externa, object storage, broker ou distribuição sem um blocker real.

## Progress log

- 2026-08-23: Product Baseline 0001 encerrado e movido para histórico.
- 2026-08-23: auditoria do repositório confirmou ausência de public web versionado e confirmou `SellerPublicContactDto`/`ISellerPublicReader` com WhatsApp público já modelado.
- 2026-08-23: ADR-0004 confirmou que o public web deve permanecer independente do host ABP; Razor/MVC dentro do host não é candidato para a experiência pública.
- 2026-08-23: documentação oficial atual de Next.js/ABP revisada para a primeira implementação; Next.js 16 Active LTS/App Router selecionado mantendo a fronteira HTTP reversível.
- 2026-08-23: fundação independente `public-web/` materializada com Next.js 16.2.12, React 19, TypeScript e ESLint. O primeiro `BPT2 Public Web Gate` instalou dependências e passou lint, typecheck e production build; Harness permaneceu verde.
- 2026-08-23: inspeção do aggregate `SellerProfile` confirmou que `WhatsAppNumber` já é persistido canonicamente como 8–15 dígitos, incluindo country code; o frontend não deve duplicar essa normalização.

## Decision log

- O primeiro ciclo de contato será WhatsApp direto usando o contato público já modelado; não criar Lead persistido até existir requisito de armazenamento/medição do contato.
- O primeiro public web usa Next.js 16 Active LTS/App Router conforme ADR-0009. A decisão é de implementação do cliente público, não de arquitetura dos módulos de domínio.
- O frontend não acessa DbContext, assemblies internos nem Contracts .NET diretamente; sua dependência é a API HTTP pública.
- O CTA deve usar diretamente o `WhatsAppNumber` canônico fornecido pelo backend no formato `https://wa.me/{digits}`; não há segunda normalização de domínio no cliente.

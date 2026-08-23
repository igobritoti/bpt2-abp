# Execution Plan 0003 — Public Buyer → WhatsApp

Status: **CONCLUÍDO**

## Objetivo

Transformar o backend público já comprovado no primeiro fluxo utilizável por um comprador real, mantendo o frontend desacoplado do host ABP:

`Public Listing → Public Detail → WhatsApp Contact`

O objetivo deste plano foi provar o primeiro consumidor público e fechar o ciclo mínimo comprador→vendedor, sem tentar criar toda a experiência final do marketplace.

## Contexto congelado

- Product Baseline 0001 concluído.
- ADR-0004 decide que a experiência pública/SEO é um cliente independente da API e não vive dentro do host ABP.
- A API pública já expunha listagem paginada, detalhe, Seller, Vehicle, fotos e conteúdo público de fotos.
- `Sellers.Contracts` já modelava `SellerPublicContactDto` com `DisplayName` e `WhatsAppNumber`.
- Draft/private permanece estruturalmente indisponível na superfície pública.
- Nenhuma necessidade comprovada exigiu Lead persistido, chat, broker, background job ou engine de busca externo neste fluxo.
- A escolha do framework público permanece reversível porque a fronteira com o backend é HTTP/API.

## Escopo executado

### Fase 1 — fundação do public web

- public web materializado como projeto independente do host ABP;
- Next.js 16 Active LTS/App Router usado na primeira implementação;
- consumo do backend somente por HTTP/API;
- código/tipos React/Next mantidos fora dos assemblies de negócio;
- gate próprio de lint, typecheck e production build adicionado.

### Fase 2 — contato por WhatsApp

- `WhatsAppNumber` existente em Sellers passou a compor a projeção pública de Listing;
- formato canônico permaneceu sob responsabilidade de `SellerProfile`: somente dígitos, entre 8 e 15, incluindo country code;
- CTA usa deterministicamente `https://wa.me/{digits}`;
- nenhum agregado de Lead foi criado.

### Fase 3 — prova do fluxo público

- listagem e detalhe públicos implementados contra a API real;
- Seller, Vehicle, fotos e fatos do anúncio renderizados no detalhe;
- metadata mínima de título/descrição implementada;
- gate HTTP end-to-end criado para provar Draft privado, Publish, listagem, detalhe, foto e CTA.

## Fora de escopo preservado

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
3. [x] Página pública de listagem consome a API real e apresenta somente anúncios publicáveis.
4. [x] Página pública de detalhe consome a API real e apresenta Seller + Vehicle + fotos + fatos do anúncio.
5. [x] Contato WhatsApp vem do contrato público de Seller existente e chega ao detalhe sem expor storage internals nem dados privados adicionais.
6. [x] CTA de WhatsApp usa número validado/normalizado de forma determinística.
7. [x] Draft/private continua indisponível pelo site público e por qualquer endpoint usado pelo frontend.
8. [x] Detalhe público produz metadata mínima coerente com o anúncio.
9. [x] Fluxo real `listagem → detalhe → CTA` é comprovado por teste mínimo reproduzível.
10. [x] Gates existentes relevantes permanecem verdes e a documentação canônica reflete o comportamento final.

## Checkpoints

- [x] Selecionar o menor gap de usuário após o Product Baseline.
- [x] Confirmar boundary do frontend público contra ADR-0004.
- [x] Confirmar que contato público de Seller/WhatsApp já existe em `Sellers.Contracts`.
- [x] Materializar public web e gate próprio.
- [x] Expor WhatsApp na projeção pública mínima.
- [x] Implementar listagem/detalhe/CTA.
- [x] Provar fluxo real contra backend.
- [x] Revisar necessidade de MDV/ADR adicional — nenhuma nova decisão arquitetural foi necessária.
- [x] Encerrar plano com resultado e pendências explícitas.

## Progress log

- 2026-08-23: Product Baseline 0001 encerrado e primeiro gap de usuário selecionado.
- 2026-08-23: ADR-0004 confirmou o public web independente do host; Next.js 16 Active LTS/App Router foi registrado em ADR-0009 mantendo a fronteira HTTP reversível.
- 2026-08-23: fundação `public-web/` materializada e comprovada pelo Public Web Gate com lint, typecheck e production build.
- 2026-08-23: `SellerProfile` confirmou o formato canônico de WhatsApp; a projeção pública de Listing passou a expor o valor e o lifecycle HTTP comprovou `+55 (11) 99999-8877 → 5511999998877 → public Listing`.
- 2026-08-23: listagem, detalhe, fotos, CTA e metadata foram implementados no public web.
- 2026-08-23: primeiro run do Buyer HTTP Gate revelou que detalhe não publicável chega ao cliente como HTTP 204; o cliente tratava apenas 404 e produzia 500 ao tentar parsear corpo vazio. A borda HTTP foi corrigida para tratar 204/404 como ausência pública.
- 2026-08-23: run corrigido do Buyer HTTP Gate passou o fluxo completo junto com Harness e Public Web Gate.

## Decision log

- O primeiro ciclo de contato é WhatsApp direto usando o contato público já modelado; Lead persistido continua adiado até existir requisito de armazenamento/medição.
- O primeiro public web usa Next.js 16 Active LTS/App Router conforme ADR-0009; isso não altera os boundaries dos módulos de domínio.
- O frontend depende somente da API HTTP pública, não de DbContext, assemblies internos ou Contracts .NET.
- O CTA usa diretamente o `WhatsAppNumber` canônico do backend no formato `https://wa.me/{digits}`.
- HTTP 204 e 404 no detalhe público são ambos tratados pelo cliente como anúncio indisponível, resultando na página pública de não encontrado.

## Resultado e evidência final

O primeiro consumidor público real foi concluído:

`Public Listing → Public Detail → Photo → WhatsApp Contact`

O `BPT2 Public Buyer HTTP Gate` sobe PostgreSQL vazio, aplica migrations, inicia o host ABP e o build do Next.js, cria Seller/Vehicle/Listing/Media reais e comprova: Draft invisível, detalhe de Draft indisponível, Publish, anúncio presente na listagem, detalhe com Seller + Vehicle, foto pública byte-for-byte, CTA para o número canônico e metadata do anúncio. O Public Web Gate e o Harness Gate também permanecem verdes no head funcional final.

## Pendências explícitas após o plano

Estas capacidades continuam sendo produto futuro ou decisões adiadas, não falhas deste plano:

- persistência/analytics/CRM de Leads e chat;
- Favorites e autenticação do comprador;
- filtros/sorting adicionais somente quando um requisito do consumidor exigir;
- moderação/administração, promoções e Vehicle Hub;
- SEO além da metadata mínima já comprovada;
- ingestão/reconciliation de fontes externas;
- provider final de object storage;
- estratégia final de busca somente mediante benchmark/requisito real;
- schemas PostgreSQL separados por módulo e FK física cross-module permanecem não decididos;
- distributed locks e background jobs permanecem adiados até caso real.

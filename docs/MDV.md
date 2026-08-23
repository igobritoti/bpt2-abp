# MDV — Matriz de Decisão e Verificação

Estados: PASSA, NÃO PASSA, DECIDIDO, NÃO DECIDIDO, ADIADO.

| ID | Questão | Estado |
|---|---|---|
| ARCH-001 | ABP 10.6 baseline | DECIDIDO |
| ARCH-002 | Modular Monolith | DECIDIDO |
| ARCH-003 | app-nolayers / evitar classic layered | DECIDIDO |
| MOD-001 | Cross-module via Contracts/events | PASSA / DECIDIDO |
| MOD-002 | Implementation-to-implementation entre módulos | NÃO PASSA / PROIBIDO |
| DATA-001 | PostgreSQL | PASSA / DECIDIDO |
| DATA-002 | DbContext por módulo, sem merged host DbContext no baseline | PASSA / DECIDIDO no Gate 01 |
| DATA-003 | Fresh database -> migrations atuais | PASSA / DECIDIDO |
| DATA-004 | Schema PostgreSQL separado por módulo | NÃO DECIDIDO |
| DATA-005 | FK física cross-module | NÃO DECIDIDO |
| TX-001 | ABP Unit of Work como mecanismo | PASSA / DECIDIDO |
| TX-002 | Atomicidade multi-módulo no mesmo PostgreSQL/UoW | PASSA / DECIDIDO no Gate 01 |
| CON-001 | Optimistic concurrency disponível | DECIDIDO como mecanismo |
| CON-002 | Optimistic concurrency em Listing | PASSA / DECIDIDO no Gate 01 e Plan 0004 |
| AUTH-001 | Seller ownership enforcement | PASSA / DECIDIDO no Gate 01 e Plan 0004 |
| AUTH-002 | Público nunca vê Draft/private | PASSA / DECIDIDO no Gate 01 e Plan 0004 |
| AUTH-003 | Login Seller no browser: Authorization Code + PKCE | PASSA / DECIDIDO no Plan 0004 |
| UI-001 | Public frontend desacoplado do host ABP | PASSA / DECIDIDO em ADR-0004 |
| UI-002 | Primeiro public web em Next.js 16 Active LTS / App Router | PASSA / DECIDIDO no Plan 0003; boundary HTTP reversível |
| UI-003 | Primeira UI Seller no `public-web` existente sob `/vender` | PASSA / DECIDIDO no Plan 0004; composição reversível atrás de HTTP/OIDC |
| SELLER-001 | Seller Profile + My Listings + Draft/Edit/Vehicle | PASSA no Plan 0004 |
| SELLER-002 | Upload/preview privado/attach/remove/reorder de fotos sem storage provider no cliente | PASSA no Plan 0004 |
| SELLER-003 | Publish/Pause/Archive preservando visibilidade pública correta | PASSA no Plan 0004 |
| CONTACT-001 | Primeiro contato Buyer → Seller por WhatsApp público já modelado | PASSA / DECIDIDO no Plan 0003; estrutura de Lead existe, mas o fluxo WhatsApp não ativa registro/analytics/CRM |
| GATE-001 | Vertical Slice 01: arquitetura + host + fresh migration + comportamento crítico | PASSA / DECIDIDO |
| INFRA-001 | Antes de experimentar/construir nova capacidade de infraestrutura, avaliar soluções maduras aplicáveis | DECIDIDO em ADR-0010 |
| INFRA-002 | Adoção de solução existente ou construção customizada de infraestrutura exige decisão durável documentada | DECIDIDO em ADR-0010 |
| LOCK-001 | Distributed locking | ADIADO até caso real |
| JOB-001 | Background jobs | ADIADO até caso real |
| SEARCH-001 | PostgreSQL vs engine externo | NÃO DECIDIDO; benchmark futuro |

## Evidência do Gate 01

Execução em GitHub Actions com ABP 10.6, .NET 10 e PostgreSQL 17:

- arquitetura: checker positivo e ataques negativos passaram;
- host: template oficial ABP 10.6 gerado, cinco módulos wired e build Release passou;
- fresh migration: banco vazio recebeu migrations do host e dos módulos;
- `G01_PUBLIC_DRAFT: PASS`;
- `G01_OWNERSHIP: PASS`;
- `G01_CONCURRENCY: PASS`;
- `G01_MULTI_MODULE_ROLLBACK: PASS`.

Classe da evidência comportamental: **B — observado/reproduzido no CI do BPT2**.

A decisão TX-002 vale para múltiplos DbContexts participantes do mesmo ABP Unit of Work sobre o mesmo PostgreSQL. Não implica atomicidade com APIs externas, object storage, outro banco ou outro processo.

## Evidência do primeiro consumidor público

- ADR-0004 fixa a separação entre public web e host ABP.
- `Sellers.Contracts` expõe `SellerPublicContactDto` com `DisplayName` + `WhatsAppNumber`; a projeção pública de Listing preserva esse contrato.
- `SellerProfile` normaliza WhatsApp para 8–15 dígitos incluindo country code, e o lifecycle HTTP comprovou a propagação do valor canônico até a resposta pública.
- O Public Web Gate comprovou lint, typecheck e production build do cliente independente.
- O Public Buyer HTTP Gate sobe banco vazio, host ABP e Next.js e comprovou Draft invisível, Publish, listagem, detalhe com Seller/Vehicle, foto pública, metadata e CTA `wa.me` para o número canônico.
- O primeiro run end-to-end revelou HTTP 204 para detalhe não publicável; o cliente foi corrigido para tratar 204/404 como ausência pública e o run subsequente passou.

Classe da evidência comportamental do fluxo Buyer: **B — observado/reproduzido no CI do BPT2**.

UI-002 é uma decisão de implementação do cliente público, isolada pela fronteira HTTP. Não altera os boundaries dos módulos do backend nem classifica outros frameworks SSR como tecnicamente incapazes.

## Evidência da fronteira Seller/OIDC

- O host semeia `BomPraTi_SellerWeb` como cliente público dedicado de Authorization Code e exige Proof Key for Code Exchange.
- `public-web` expõe `/vender` e `/vender/callback` usando um cliente OIDC browser; senha não é coletada pelo frontend BPT2.
- O Seller Auth HTTP Gate executou em banco PostgreSQL vazio e comprovou discovery, PKCE obrigatório e redirect ao Account login.
- O Seller Shell HTTP Gate executou Account login real, troca do authorization code por access token, Profile, My Listings e logout.
- O primeiro Seller Auth run detectou um contributor `[UnitOfWork]` selado incompatível com proxy do ABP/Autofac; a correção mínima tornou classe/método interceptáveis e o run subsequente passou.

Classe da evidência do boundary Seller: **B — observado/reproduzido no CI do BPT2**.

## Evidência do Seller Self-Service completo

- O Seller Draft Edit HTTP Gate comprovou Vehicle canônico, criação Draft, owned read, ocultação para segundo Seller, update com rotação de `ConcurrencyStamp`, stale 409 e reread do estado canônico.
- O Seller Photos Publish HTTP Gate executa PostgreSQL fresco, host ABP real, login `BomPraTi_SellerWeb` por Authorization Code + PKCE e Next.js de produção.
- Media upload, attach, reorder e remove passaram; o gate valida que o retorno de Media não expõe storage key/provider e que a ordem remanescente é normalizada pelo backend.
- A galeria Seller carrega bytes da foto por leitura autenticada e ownership-safe; `SELLER_PUBLISH_PRIVATE_PHOTO: PASS` comparou a foto Draft do owner byte a byte com o upload, enquanto o segundo Seller recebeu 404 para a mesma leitura privada.
- A rota HTTP observada no Swagger para essa leitura é `GET /api/app/seller-listing-query/mine-photo?listingId=...&photoId=...`; o cliente foi alinhado ao contrato gerado, sem criar rota artificial no backend.
- Segundo Seller recebeu 403 ao tentar Publish e attach no Listing do owner.
- Draft permaneceu ausente da API pública e do Next; Publish tornou o anúncio e a foto visíveis; Pause ocultou; republish restaurou; Archive ocultou novamente.
- A foto pública foi comparada byte a byte com o upload original.
- Publish/Pause/Archive permanecem commands do backend; o frontend não codifica matriz própria de transições.

Classe da evidência do fluxo Seller: **B — observado/reproduzido no CI do BPT2**.

## Princípio de seleção de infraestrutura

ADR-0010 define uma regra transversal para qualquer nova capacidade de infraestrutura:

`necessidade comprovada -> avaliação de soluções maduras -> experimento mínimo se ainda necessário -> decisão adopt/build documentada`.

A avaliação deve considerar opções nativas da plataforma/framework, OSS/self-hosted e gerenciadas/comerciais quando aplicáveis. Isso não cria preferência automática por SaaS nem proíbe construção própria; impede que custom build seja o experimento padrão sem antes verificar soluções maduras e seus trade-offs.

A decisão final de adoção ou construção deve registrar necessidade, alternativas, rationale, boundary/ownership, consequências operacionais e estratégia de reversibilidade/saída. Decisões atualmente adiadas, como distributed locking, background jobs e engine externa de busca, continuam adiadas; ADR-0010 governa o processo quando alguma delas for aberta.

## Regra de decisão

Para regra de domínio/aplicação: documentação/código/standard -> capacidade comprovada -> teste mínimo se a decisão específica do BPT não estiver resolvida -> PASS/FAIL -> decisão registrada.

Para nova infraestrutura: necessidade/constraints comprovados -> avaliação de soluções maduras -> experimento/benchmark mínimo somente se necessário -> decisão adopt/build documentada.

Inferência, popularidade de mercado ou preferência não vira requisito arquitetural sem evidência.

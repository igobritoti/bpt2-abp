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
| CON-002 | Optimistic concurrency em Listing | PASSA / DECIDIDO no Gate 01 |
| AUTH-001 | Seller ownership enforcement | PASSA / DECIDIDO no Gate 01 |
| AUTH-002 | Público nunca vê Draft/private | PASSA / DECIDIDO no Gate 01 |
| AUTH-003 | Mecanismo de login Seller no browser: Authorization Code + PKCE | PASSA no boundary protocolar / DECIDIDO no Plan 0004; jornada de login/logout real ainda em execução |
| UI-001 | Public frontend desacoplado do host ABP | PASSA / DECIDIDO em ADR-0004 |
| UI-002 | Primeiro public web em Next.js 16 Active LTS / App Router | PASSA / DECIDIDO no Plan 0003; boundary HTTP reversível |
| UI-003 | Primeira UI Seller no `public-web` existente sob `/vender` | PASSA no spike / DECIDIDO no Plan 0004; composição reversível atrás de HTTP/OIDC |
| CONTACT-001 | Primeiro contato Buyer → Seller por WhatsApp público já modelado | PASSA / DECIDIDO no Plan 0003; Lead persistido ainda não exigido |
| GATE-001 | Vertical Slice 01: arquitetura + host + fresh migration + comportamento crítico | PASSA / DECIDIDO |
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
- O Seller Auth HTTP Gate executou em banco PostgreSQL vazio, aplicou migrations/seed e comprovou `SELLER_AUTH_DISCOVERY: PASS`, `SELLER_AUTH_PKCE_REQUIRED: PASS`, `SELLER_AUTH_LOGIN_REDIRECT: PASS` e `SELLER AUTH HTTP SPIKE: PASSED`.
- No mesmo head corrigido passaram Harness, Host, Public Web, Listing Lifecycle, Listing Photo, Product API e Public Buyer HTTP.
- O primeiro run detectou um contributor `[UnitOfWork]` selado incompatível com proxy do ABP/Autofac; a correção mínima tornou a classe/método interceptáveis e o run subsequente passou.

Classe da evidência do boundary Seller: **B — observado/reproduzido no CI do BPT2**.

AUTH-003 ainda não declara a jornada completa de login/logout do usuário como concluída; isso será elevado para PASSA integral quando o Seller shell provar sessão real e consumo autenticado das APIs.

## Regra de decisão

Documentação/código/standard -> capacidade comprovada -> teste mínimo se a decisão específica do BPT não estiver resolvida -> PASS/FAIL -> decisão registrada.

Inferência ou preferência não vira requisito arquitetural sem evidência.

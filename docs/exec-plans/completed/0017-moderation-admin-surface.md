# Execution Plan 0017 — Moderation Admin Surface

Status: **COMPLETO**

## Objetivo

Fechar a primeira superfície operacional visual de moderação reutilizando a inbox read-only já comprovada no Plan 0012:

`admin login no host → /moderacao → reports persistidos read-only`

## Evidência que abriu o slice

- `PRODUCT.md` mantinha administração/moderação como capacidades centrais e frontend/painel administrativo como gap aberto.
- o Plan 0012 já entregava `IModerationListingReportQuery`, DTO mínimo, role `admin` e prova HTTP real, mas não havia superfície visual para o operador.
- Promoções e Buyer Alerts não possuíam implementação parcial no repo.
- JSON-LD automotivo continuava semanticamente possível, mas a documentação oficial corrente do Google registra a retirada de Vehicle Listing structured data dos resultados e do Search Console em 2025; isso não sustentava prioridade de produto.
- o host já continha ABP MVC, Account Web, LeptonXLite e autenticação; a documentação ABP corrente recomenda Razor Pages para UI MVC/Razor e autorização declarativa com `[Authorize]`.
- portanto a página interna no próprio host reutiliza autenticação existente e não cria novo frontend, cliente OIDC ou regra de domínio.

## Escopo entregue

- `/moderacao` como Razor Page no host ABP;
- acesso restrito à role `admin`;
- leitura exclusivamente por `IModerationListingReportQuery`;
- renderização de report id, listing id, título, status corrente e instante UTC do report;
- nenhuma identidade/PII Buyer renderizada;
- anônimo redirecionado para Account Login;
- usuário autenticado sem role `admin` bloqueado pelo fluxo de AccessDenied do cookie auth;
- admin autenticado pelo Account Web real recebe HTTP 200 e vê report persistido;
- report histórico permanece na página após Pause, refletindo o status corrente;
- prova incorporada ao Buyer Favorites HTTP Gate já existente.

## Fora de escopo

- aprovar/rejeitar report;
- pausar/remover/suspender Listing por ação de moderação;
- motivo, taxonomia ou texto livre;
- workflow/status de moderação;
- scoring, priorização e notificações;
- PII/perfil Buyer;
- shell administrativo genérico ou menu de administração;
- novo cliente OIDC/admin SPA;
- UI de Ingestion, Promoções ou Buyer Alerts.

## Critérios de aceite

1. [x] `/moderacao` existe no host e anônimo não obtém a inbox.
2. [x] usuário autenticado sem role `admin` não obtém a inbox.
3. [x] admin autenticado pelo Account Web real recebe HTTP 200 e vê o report persistido.
4. [x] página usa somente a projeção read-only existente e não expõe PII Buyer.
5. [x] mudança não cria backend/domain/schema/migration nem novo cliente OIDC.
6. [x] build e doze workflows aplicáveis passam no head funcional.
7. [x] docs finais preservam política/ações de moderação como NÃO DECIDIDAS.

## Evidência executada

Head funcional comprovado: `baa4b62790e21125ddf506a19a988e0d122eb195`.

`BPT2 Buyer Favorites HTTP Gate`, run `32741693910`, job `97477413143`, usando PostgreSQL fresco, host ABP real e Account Web real:

- `FRESH MIGRATION GATE: PASSED`
- build Release: `0 Warning(s)` / `0 Error(s)`
- `MODERATION_REPORT_ROUTES: PASS`
- `MODERATION_REPORT_ANONYMOUS_BLOCKED: PASS`
- `MODERATION_PAGE_ANONYMOUS_BLOCKED: PASS`
- `MODERATION_REPORT_NON_ADMIN_BLOCKED: PASS`
- `MODERATION_PAGE_NON_ADMIN_BLOCKED: PASS`
- `MODERATION_REPORT_ADMIN_VISIBLE: PASS`
- `MODERATION_REPORT_BUYER_PII_HIDDEN: PASS`
- `MODERATION_PAGE_ADMIN_VISIBLE: PASS`
- `MODERATION_PAGE_BUYER_PII_HIDDEN: PASS`
- `MODERATION_REPORT_HISTORY_PRESERVED: PASS`
- `MODERATION_PAGE_HISTORY_PRESERVED: PASS`
- `MODERATION REPORT INBOX HTTP: PASSED`

No mesmo head, os doze workflows aplicáveis concluíram `success`: Harness, Host, Product API, Listing HTTP Lifecycle, Listing Photo, Public Buyer, Public Discovery, Buyer Favorites, Seller Auth, Seller Draft/Edit, Seller Shell e Seller Photos/Publish.

Classe da evidência: **B — comportamento observado/reproduzido no CI do BPT2**.

## Falhas observadas e correções focais

1. O primeiro Harness Gate falhou porque o execution plan ativo não tinha a seção obrigatória `## Progress log`. A correção adicionou somente a seção exigida; nenhum código funcional mudou.
2. A primeira prova da página esperava HTTP 403 bruto para um usuário cookie-auth autenticado sem role `admin`. O comportamento observado do Account Web foi `Forbid → 302` para `AccessDenied`, enquanto a API bearer continuou retornando 403. A prova foi corrigida para exigir 403 ou redirect explícito para AccessDenied; `[Authorize(Roles = "admin")]` e o código da página permaneceram inalterados.

## Decision log

- **DECIDIDO:** a primeira UI de moderação vive no host ABP já autenticado; não existe cliente OIDC/admin frontend novo neste slice.
- **DECIDIDO:** a superfície é estritamente read-only e consome `IModerationListingReportQuery` como única projeção.
- **DECIDIDO:** a página não expõe identidade/PII Buyer e preserva reports históricos com status corrente do Listing.
- **NÃO DECIDIDO:** política/ações de moderação, taxonomia, workflow, scoring, notificações e shell admin genérico.

## Progress log

- 2026-08-24: `main` remoto confirmado em `96b52538c9805fb19035ea374f8b2e79c642f04f` após o Plan 0016.
- 2026-08-24: auditoria rejeitou JSON-LD como prioridade corrente e encontrou a inbox de moderação como maior implementação parcial sem UI.
- 2026-08-24: branch `feat/moderation-admin-surface` e draft PR #36 abertos.
- 2026-08-24: Razor Page `/moderacao` e prova HTTP adicionadas sem backend/domain/schema novo.
- 2026-08-24: Harness corrigido somente pela estrutura obrigatória do plan.
- 2026-08-24: expectativa de 403 da UI alinhada ao AccessDenied redirect observado do cookie auth, sem alterar autorização.
- 2026-08-24: head funcional `baa4b62790e21125ddf506a19a988e0d122eb195` comprovado com 12/12 workflows aplicáveis verdes.

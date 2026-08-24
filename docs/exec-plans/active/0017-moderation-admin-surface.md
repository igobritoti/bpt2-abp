# Execution Plan 0017 — Moderation Admin Surface

Status: **ATIVO**

## Objetivo

Fechar a primeira superfície operacional visual de moderação reutilizando a inbox read-only já comprovada no Plan 0012:

`admin login no host → /moderacao → reports persistidos read-only`

## Evidência que abriu o slice

- `PRODUCT.md` mantém administração/moderação como capacidades centrais e frontend/painel administrativo como gap aberto.
- o Plan 0012 já entrega `IModerationListingReportQuery`, DTO mínimo, role `admin` e prova HTTP real, mas não há superfície visual para o operador.
- Promoções e Buyer Alerts não possuem implementação parcial no repo.
- JSON-LD automotivo permanece semanticamente possível, mas Google retirou Vehicle Listing structured data dos resultados e do Search Console em 2025; isso não sustenta prioridade de produto agora.
- o host já contém ABP MVC, Account Web, LeptonXLite e autenticação; a documentação ABP atual recomenda Razor Pages para UI MVC/Razor e autorização declarativa com `[Authorize]`.
- portanto a página interna no próprio host reutiliza autenticação existente e não cria novo frontend, cliente OIDC ou regra de domínio.

## Escopo

- criar `/moderacao` como Razor Page no host ABP;
- restringir a página à role `admin`;
- carregar exclusivamente `IModerationListingReportQuery`;
- renderizar report id, listing id, título, status corrente e instante do report;
- não expor identidade/PII Buyer;
- provar anônimo bloqueado, usuário autenticado sem admin bloqueado e admin vendo report real;
- reutilizar o Buyer Favorites HTTP Gate/fixture de moderação existentes.

## Fora de escopo

- aprovar/rejeitar report;
- pausar/remover/suspender Listing;
- motivo, taxonomia ou texto livre;
- workflow/status de moderação;
- scoring, priorização e notificações;
- PII/perfil Buyer;
- shell administrativo genérico ou menu de administração;
- novo cliente OIDC/admin SPA;
- UI de Ingestion, Promoções ou Buyer Alerts.

## Critérios de aceite

1. [ ] `/moderacao` existe no host e anônimo não obtém a inbox.
2. [ ] usuário autenticado sem role `admin` não obtém a inbox.
3. [ ] admin autenticado pelo Account Web real recebe HTTP 200 e vê o report persistido.
4. [ ] página usa somente a projeção read-only existente e não expõe PII Buyer.
5. [ ] mudança não cria backend/domain/schema/migration nem novo cliente OIDC.
6. [ ] build e workflows aplicáveis passam no head funcional.
7. [ ] docs finais preservam política/ações de moderação como NÃO DECIDIDAS.

## Checkpoints

- [x] `main` remoto confirmado em `96b52538c9805fb19035ea374f8b2e79c642f04f`.
- [x] auditar gaps abertos e implementação parcial.
- [x] rejeitar JSON-LD como prioridade por evidência Google atual.
- [x] confirmar viabilidade do host Razor/Account Web existente.
- [x] criar branch `feat/moderation-admin-surface`.
- [ ] abrir draft PR.
- [ ] implementar página read-only.
- [ ] ampliar somente o smoke de moderação existente.
- [ ] corrigir apenas falhas observadas.
- [ ] fechar docs, exigir CI fresco, review/base refresh e merge verde.

## Decision log

- **DECIDIDO para este slice:** a primeira UI de moderação vive no host ABP já autenticado; não haverá cliente OIDC/admin frontend novo.
- **DECIDIDO para este slice:** superfície é estritamente read-only e consome `IModerationListingReportQuery`.
- **NÃO DECIDIDO:** política/ações de moderação, taxonomia, workflow, scoring, notificações e shell admin genérico.

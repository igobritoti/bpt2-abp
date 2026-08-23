# Current work

Last verified: **2026-08-23**

Este arquivo é um snapshot curto do trabalho corrente. Não é histórico, changelog nem inventário de CI.

## Active outcome

Execution Plan 0004 ativo. O objetivo corrente é fechar o primeiro fluxo operacional real do Seller sobre a superfície autenticada já existente:

`Seller login → Seller profile → My Listings → Draft/Edit → Vehicle selection → Photos → Publish → Public Listing`

A fronteira de UI/auth foi provada: a primeira experiência Seller vive no `public-web` existente sob `/vender`, usa o cliente público OpenIddict `BomPraTi_SellerWeb`, Authorization Code + PKCE e continua isolada do backend por HTTP/API. O password grant não é permitido para esse cliente.

A auditoria anterior já confirmou perfil, My Listings, comandos de Listing, Vehicle search, Media upload e mutações de foto. O gap mínimo de backend continua sendo uma leitura autenticada de detalhe/galeria para reabrir a edição de um Listing próprio.

Próximo acceptance target: implementar o Seller shell mínimo sobre a autenticação já provada — leitura/upsert do próprio perfil e página `Meus anúncios` consumindo a query autenticada existente, sem criar regras de domínio no frontend.

## Active plan

[`../exec-plans/active/0004-seller-self-service.md`](../exec-plans/active/0004-seller-self-service.md)

## Source of runtime truth

- Estado de branch/PR/checks: Git e GitHub Actions do commit corrente.
- Fatos estruturais/versões/counters derivados: [`../generated/repository-facts.md`](../generated/repository-facts.md).
- Decisões congeladas: [`../MDV.md`](../MDV.md) e [`../adr/`](../adr/).

Não copie SHAs, número de testes/checks ou “runtime ready” para este arquivo; consulte as fontes executáveis quando a tarefa depender deles.

## Open blockers

Nenhum blocker de repositório conhecido. O código donor do BPT1 não está disponível nas fontes GitHub acessíveis nesta auditoria; isso limita transplantar UX/código antigo, mas não bloqueia o Plan 0004 porque o backend BPT2 necessário já está majoritariamente exposto.

## Update rule

Atualize este snapshot somente quando mudar o outcome ativo, plano ativo, próximo acceptance target ou blocker real. História vai para o execution plan concluído/ADR, não para baixo deste arquivo.

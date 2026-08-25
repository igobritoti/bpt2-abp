# Execution Plan 0027 — MVP Readiness Audit

Status: **COMPLETO**

## Objetivo

Auditar o estado funcional atual do BPT2 e classificar gaps restantes por evidência em somente duas classes operacionais:

- **BLOQUEIA MVP** — impede o ciclo central do marketplace ou o controle operacional mínimo necessário para disponibilizá-lo;
- **PÓS-MVP** — melhora alcance, escala, automação, enriquecimento ou experiência, mas não impede o ciclo central já comprovado.

Nenhuma feature é promovida a blocker apenas porque aparece no produto-alvo.

## Contexto congelado

A auditoria parte do `main` em `29e4d5fde05f8dd1a84a3146d789a5e2e7efbf87`, depois do merge do Plan 0026.

Fluxos já comprovados por HTTP/CI e portanto não reabertos neste bloco:

- Seller login/profile → Draft/Edit → photos → Publish/Pause/Archive;
- descoberta pública → detalhe → foto → WhatsApp;
- Lead persistido → inbox Seller → marcar atendido;
- Buyer favorites;
- Buyer reporta Listing público;
- admin consulta reports e candidates de ingestion;
- SEO técnico mínimo, Vehicle Hub, Seller Hub e metadata social já documentados nos planos concluídos.

## Escopo

- confrontar o ciclo central já provado com dependências necessárias em banco fresco;
- identificar superfícies operacionais que hoje dependem exclusivamente de fixture/teste ou acesso direto a persistência;
- separar blockers de melhorias deliberadamente adiáveis;
- definir a ordem dos próximos slices sem inventar infraestrutura ou política não sustentada por evidência.

## Fora de escopo

- implementar qualquer blocker neste plano;
- escolher fornecedor de storage, search, geocoding ou connector;
- definir ranking, taxonomia editorial, catálogo externo ou política automática de moderação;
- tratar deploy/produção sem requisito de topologia e operação definido.

## Critérios de aceite

1. [x] capacidades centrais já comprovadas foram separadas de gaps ainda abertos;
2. [x] cada gap material restante foi classificado como `BLOQUEIA MVP` ou `PÓS-MVP`;
3. [x] blockers possuem evidência direta do repositório, não preferência;
4. [x] o próximo acceptance target foi reduzido ao primeiro blocker independente;
5. [x] nenhum novo requisito de infraestrutura foi criado por antecipação.

## Resultado da auditoria

### BLOQUEIA MVP

| Ordem | Gap | Evidência | Por que bloqueia |
|---|---|---|---|
| 1 | **Carga operacional do catálogo canônico** | `VehicleCatalogAppService` é somente leitura. O bootstrap canônico cria schema + Identity/OpenIddict, mas os gates Seller/Buyer precisam executar `tests/BomPraTi.HttpLifecycleFixture` para inserir `Brand → Model → Generation → Version → Vehicle` e exportar `BPT_FIXTURE_VEHICLE_ID` antes de criar Listing. | Um ambiente novo não possui caminho suportado pelo produto para criar a identidade automotiva exigida por todo Listing. O fluxo Seller está comprovado apenas dado um Vehicle pré-existente. |
| 2 | **Ação mínima de moderação pelo operador** | Plans 0011/0012/0017 comprovam sinalização Buyer e fila admin read-only; eles preservam explicitamente suspensão/remoção/decisão fora de escopo. Publish/Pause/Archive existentes pertencem ao Seller owner. | O operador consegue detectar um Listing denunciado, mas não consegue retirar a oferta por uma autoridade administrativa do produto. Isso deixa o controle operacional mínimo incompleto. |

### PÓS-MVP

| Área | Gaps adiáveis | Motivo da classificação |
|---|---|---|
| Descoberta | ranking/sort avançado, facets, autocomplete, cor normalizada, engine externa | busca pública, filtros, paginação e visibilidade já funcionam sem essas extensões. |
| Localização | geocoding, raio/distância, bairro/CEP, proximidade, landing pages locais | City/StateCode já permitem descoberta localizada sem nova autoridade geográfica. |
| Catálogo/Vehicle Hub | specs, equipamentos, consumo, preço de mercado, editorial, imagens enriquecidas, slugs semânticos | não impedem criar/publicar/encontrar/contatar uma oferta quando a identidade canônica existe. |
| Ingestion | connector concreto, matching automático, confidence threshold, background jobs | ingestion manual/reconciliation existe; automação não é necessária para fechar o bootstrap manual mínimo do catálogo. |
| Moderação | motivo/taxonomia, texto livre, scoring, workflow multiestado, notificações, suspensão automática | o blocker exige somente autoridade humana mínima para retirar/restaurar visibilidade; política sofisticada pode evoluir depois. |
| SEO/social | JSON-LD, social image dedicada, estratégia editorial/conteúdo, analytics | canonical, sitemap/robots e metadata social mínima já existem. |
| Admin | dashboard, métricas, menu global/tema, permissões granulares, frontend admin separado | `/admin`, `/moderacao` e `/ingestao` já provam entrada operacional; novas superfícies podem permanecer no host atual. |
| Leads/Buyer | CRM, scoring, notas, resolução de PII/perfil Buyer | WhatsApp → Lead → inbox Seller → atendido já fecha o ciclo mínimo. |
| Infra | search externo, distributed lock, background jobs, object storage específico, Redis/Kubernetes | nenhuma necessidade executada exige essas escolhas. `BPT_MEDIA_ROOT` permite storage local configurável; topologia de produção ainda não justifica fornecedor novo. |
| Promoções | promoção/boost comercial | monetização/boost não é pré-condição para o ciclo marketplace básico comprovado. |

## Evidência adicional

### Cadastro de usuário

Não foi classificado como blocker. O BPT2 usa o Account Web do ABP e não desabilita self-registration. A documentação oficial atual do ABP 10.6 declara `/Account/Register` e `AccountSettingNames.IsSelfRegistrationEnabled = true` por padrão. Um E2E BPT2 dedicado pode aumentar a força da prova, mas não há evidência atual de falha funcional que justifique bloquear o MVP.

### Mídia

`LocalMediaBlobStore` persiste em filesystem sob `BPT_MEDIA_ROOT` configurável e protege escape de path. Isso é suficiente para uma topologia MVP de instância única com volume persistente. Object storage distribuído só vira requisito quando uma topologia real o exigir; promovê-lo agora seria hipótese de infraestrutura.

## Decisões abertas necessárias

Nenhuma para esta auditoria. Os blockers podem ser atacados mantendo as decisões existentes:

1. criar uma superfície admin mínima para inserir identidade canônica usando os aggregates atuais, sem connector/importador novo;
2. criar uma ação admin mínima de moderação sobre Listing, mantendo decisão humana e sem taxonomia/workflow prematuro.

## Decision log

- **DECIDIDO por evidência:** ausência de carga operacional do catálogo canônico bloqueia o MVP.
- **DECIDIDO por evidência:** fila de moderação sem autoridade de intervenção bloqueia o MVP operacional mínimo.
- **DECIDIDO:** os demais gaps listados acima são pós-MVP até nova evidência alterar sua necessidade.
- **NÃO DECIDIDO:** fonte externa inicial do catálogo, automação de ingestão, ranking, search externo e topologia de storage.
- **ADIADO:** E2E específico de self-registration enquanto não houver falha observada ou mudança nessa configuração.

## Progress log

- 2026-08-24: `main` remoto confirmado em `29e4d5fde05f8dd1a84a3146d789a5e2e7efbf87`; Plan 0026 concluído e nenhum execution plan ativo.
- 2026-08-24: auditoria confirmou que o Catalog expõe leitura, enquanto o fluxo Seller em banco fresco depende de `BPT_FIXTURE_VEHICLE_ID` criado por fixture de teste.
- 2026-08-24: bootstrap local/CI confirmado como schema + Identity/OpenIddict; não existe etapa de carga canônica de Vehicle fora da fixture.
- 2026-08-24: moderação confirmada como report + inbox admin read-only; nenhuma ação administrativa sobre visibilidade do Listing está implementada.
- 2026-08-24: self-registration mantido fora dos blockers com suporte da configuração BPT2 e documentação oficial ABP 10.6.
- 2026-08-24: gaps restantes classificados e próximo target reduzido ao blocker de catálogo canônico.
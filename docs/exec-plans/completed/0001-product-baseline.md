# Execution Plan 0001 — Product Baseline

Status: **CONCLUÍDO**

## Objetivo

Transformar o chassis validado pelo Gate 01 em um primeiro baseline funcional de produto, executável pela API real e pronto para evolução incremental, sem reabrir decisões arquiteturais já comprovadas.

Fluxo-alvo inicial:

`Seller → Vehicle → Listing → Publish → Public Listing Query`

Media/fotos entra imediatamente depois que o fluxo principal estiver consolidado.

## Contexto congelado

- ABP 10.6 `app-nolayers`, .NET 10, PostgreSQL.
- Modular monolith.
- Módulos atuais: Catalog, Sellers, Marketplace, Media, Ingestion.
- Cross-module somente via Contracts/eventos apropriados; implementação→implementação proibida.
- DbContext por módulo no baseline; mesmo PostgreSQL/ABP UoW já provou rollback multi-módulo.
- Listing ownership, visibilidade pública e optimistic concurrency já foram provados no Gate 01 e pelo HTTP real.
- Infra extra não entra sem necessidade demonstrada.

## Escopo executado

### Fase 1 — API de produto mínima

- contrato de Seller necessário ao anúncio consolidado;
- criação/leitura do Vehicle canônico necessária ao anúncio consolidada;
- Listing create/read/update/archive/publish exposto pela API real;
- `ConcurrencyStamp` mantido no caminho de leitura/escrita relevante;
- ownership resolvido no servidor;
- public query estruturalmente limitada a estados publicáveis.

### Fase 2 — Media/fotos

- upload validado por bytes/tipo real;
- associação de `MediaAssetId` a ListingPhoto;
- ordenação/capa mínima comprovada;
- Marketplace permanece sem dependência de storage key/provider.

### Fase 3 — experiência pública mínima de backend

- detalhe público contém fatos de Seller + Vehicle + fotos;
- listagem pública usa paginação com `totalCount/items` via `PagedResultDto<T>`;
- filtros existentes foram preservados sem expandir contrato antes do primeiro consumidor real.

## Fora de escopo preservado

- frontend final;
- Favorites;
- Leads/chat;
- promoções/pagamentos;
- moderação completa;
- ingestão/reconciliation de fontes externas;
- background jobs sem caso atual;
- distributed locks sem disputa demonstrada;
- external search/cache/broker;
- Kubernetes/microservices;
- schema PostgreSQL por módulo e FK física cross-module, enquanto permanecem abertos na MDV.

## Critérios de aceite

1. [x] Host versionado executa e builda com os módulos atuais.
2. [x] API real permite criar/atualizar/publicar Listing por Seller autorizado.
3. [x] Seller não autorizado recebe rejeição; não há override por `SellerId` vindo do cliente.
4. [x] Update stale falha explicitamente por optimistic concurrency.
5. [x] Draft/private não é retornado pela superfície pública.
6. [x] Vehicle referenciado pelo Listing é resolvido pelo contrato canônico do Catalog.
7. [x] Tipo falso/arquivo inválido não passa pela validação de Media.
8. [x] Mudanças de schema têm migrations aplicáveis em banco vazio.
9. [x] Architecture checker continua bloqueando implementação→implementação.
10. [x] Documentação canônica permanece coerente com o comportamento implementado.

## Checkpoints

- [x] Gate 01 arquitetural/comportamental concluído.
- [x] Host ABP 10.6 materializado/versionado.
- [x] Consolidar API real Seller/Catalog/Listing.
- [x] Executar regressões focadas de ownership/public/concurrency pelo caminho HTTP/application service final.
- [x] Integrar Media/ListingPhoto.
- [x] Validar detalhe/listagem pública mínima.
- [x] Revisar necessidade de MDV/ADR — nenhuma decisão arquitetural nova surgiu; nenhuma atualização necessária.
- [x] Encerrar plano com resultado e pendências explícitas.

## Progress log

- 2026-08-22: chassis e Gate 01 validados; documentação operacional formalizada antes de continuar feature work.
- 2026-08-23: API real Seller/Catalog/Listing/Public Listing comprovada no host; endpoints protegidos retornam 401/403 em `/api/**` e superfícies públicas permanecem anônimas.
- 2026-08-23: lifecycle autenticado de Listing comprovado por HTTP real: criação em Draft, Draft invisível, ownership negado com 403, Publish público, update válido com rotação de `ConcurrencyStamp` e update stale rejeitado com 409.
- 2026-08-23: Media/ListingPhoto comprovado pelo caminho HTTP real: upload autenticado, validação do tipo real pelos bytes, criação de MediaAsset sem vazamento de storage internals, ownership negado com 403, reorder com capa mínima em `SortOrder == 0`, foto de Draft rejeitada com 404, projeção pública ordenada após Publish e conteúdo público servido byte-for-byte com `Content-Type: image/png`.
- 2026-08-23: Fase 3 validada no backend: o contrato HTTP gerado para `PublicListingDto` contém Seller + Vehicle + Photos; a listagem pública retorna envelope paginado `totalCount/items`, preservando `Skip/Take` e ordenação determinística.
- 2026-08-23: critérios finais revisados contra evidência existente; nenhuma nova decisão arquitetural foi necessária e o plano foi encerrado.

## Decision log

- Nenhuma decisão arquitetural nova foi criada por este plano além das decisões já registradas em `../../MDV.md` e `../../adr/`.
- A configuração de transport security segue a opção documentada do ABP/OpenIddict apenas para Development quando `AuthServer:RequireHttpsMetadata=false`; produção continua exigindo HTTPS.
- A paginação pública usa o DTO padrão `PagedResultDto<T>` do ABP para expor itens e total; não foram adicionados filtros, sorting ou infraestrutura de busca.

## Resultado e evidência final

O Product Baseline foi concluído até a experiência pública mínima de backend:

`Seller → Vehicle → Listing → Publish → Public Listing Query → Media/ListingPhoto → detalhe/listagem pública mínima`

A evidência executada no GitHub Actions cobriu os gates de arquitetura, host, fresh migration, Gate 01, Product API, Listing lifecycle, Listing Photo e harness nos heads integrados durante o plano. O fechamento não exige nova regressão funcional porque não altera runtime; o Harness Gate deve continuar validando a coerência estrutural/documental antes da integração deste fechamento.

## Pendências explícitas após o baseline

Estas lacunas são produto futuro ou decisões adiadas, não falhas do baseline concluído:

- definir e comprovar o primeiro consumidor real da experiência pública;
- completar o ciclo Buyer → contato/lead;
- frontend, Favorites, moderação/administração, SEO, promoções e Vehicle Hub;
- ingestão/reconciliation de fontes externas;
- provider final de object storage quando houver necessidade demonstrada;
- estratégia final de busca somente quando benchmark/requisito real exigir;
- schema PostgreSQL por módulo e FK física cross-module permanecem não decididos na MDV;
- distributed locks e background jobs permanecem adiados até caso real.

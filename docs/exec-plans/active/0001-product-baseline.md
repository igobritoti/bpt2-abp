# Execution Plan 0001 — Product Baseline

Status: **ATIVO**

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

## Escopo

### Fase 1 — API de produto mínima

- confirmar/fechar contrato de Seller necessário ao anúncio;
- confirmar/fechar criação/leitura do Vehicle canônico necessária ao anúncio;
- completar Listing create/read/update/archive/publish conforme lifecycle atual;
- expor application services pela API real do host;
- manter `ConcurrencyStamp` no caminho de leitura/escrita relevante;
- manter ownership resolvido no servidor;
- manter public query estruturalmente limitada a estados publicáveis.

### Fase 2 — Media/fotos

- upload validado por bytes/tipo real conforme boundary já implementado;
- associação de `MediaAssetId` a ListingPhoto;
- ordenação/capa mínima necessária ao detalhe público;
- nenhuma dependência do Marketplace em storage key/provider.

### Fase 3 — experiência pública mínima de backend

- detalhe público do anúncio com fatos de Seller + Vehicle + fotos necessárias;
- listagem pública paginada correta;
- filtros mínimos somente quando requisito do primeiro consumidor estiver definido.

## Fora de escopo deste plano

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

1. Host versionado executa e builda com os módulos atuais.
2. API real permite criar/atualizar/publicar Listing por Seller autorizado.
3. Seller não autorizado recebe rejeição; não há override por `SellerId` vindo do cliente.
4. Update stale falha explicitamente por optimistic concurrency.
5. Draft/private não é retornado pela superfície pública.
6. Vehicle referenciado pelo Listing é resolvido pelo contrato canônico do Catalog.
7. Quando Media entrar, tipo falso/arquivo inválido não passa pela validação pertinente.
8. Mudanças de schema têm migrations aplicáveis em banco vazio.
9. Architecture checker continua bloqueando implementação→implementação.
10. Documentação canônica permanece coerente com o comportamento implementado.

## Checkpoints

- [x] Gate 01 arquitetural/comportamental concluído.
- [x] Host ABP 10.6 materializado/versionado na branch de implementação.
- [x] Consolidar API real Seller/Catalog/Listing.
- [x] Executar regressões focadas de ownership/public/concurrency pelo caminho HTTP/application service final.
- [x] Integrar Media/ListingPhoto.
- [x] Validar detalhe/listagem pública mínima.
- [ ] Atualizar MDV/ADRs apenas se surgir decisão arquitetural nova.
- [ ] Encerrar plano com resultado e pendências explícitas.

## Decisões abertas permitidas durante o plano

Resolver somente quando bloquearem um critério de aceite:

- forma exata dos DTOs públicos;
- paginação/filtros mínimos do primeiro consumidor;
- provider de storage quando Media precisar sair do storage local;
- estratégia de autenticação/seed necessária para ambiente de desenvolvimento e teste do host.

Nenhuma dessas decisões autoriza automaticamente mudança de chassis, busca externa, broker ou distribuição.

## Progress log

- 2026-08-22: chassis e Gate 01 validados; documentação operacional formalizada antes de continuar feature work.
- 2026-08-23: API real Seller/Catalog/Listing/Public Listing comprovada no host; endpoints protegidos retornam 401/403 em `/api/**` e superfícies públicas permanecem anônimas.
- 2026-08-23: lifecycle autenticado de Listing comprovado por HTTP real: password-grant/Identity seed, criação em Draft, Draft invisível, ownership negado com 403, Publish público, update válido com rotação de `ConcurrencyStamp` e update stale rejeitado com 409. O teste também revelou e corrigiu a configuração HTTP de OpenIddict somente em Development e a exceção de ownership que antes vazava como 500.
- 2026-08-23: Media/ListingPhoto comprovado pelo caminho HTTP real: upload autenticado, validação do tipo real pelos bytes, criação de MediaAsset sem vazamento de storage internals, ownership negado com 403, reorder com capa mínima em `SortOrder == 0`, foto de Draft rejeitada com 404, projeção pública ordenada após Publish e conteúdo público servido byte-for-byte com `Content-Type: image/png`.
- 2026-08-23: Fase 3 validada no backend: o contrato HTTP gerado para `PublicListingDto` contém fatos de Seller + Vehicle + Photos; a listagem pública retorna envelope paginado `totalCount/items` via `PagedResultDto`, preservando `Skip/Take` e ordenação determinística. Product API, Listing lifecycle, Listing Photo, migration, host e architecture gates permaneceram verdes.

## Decision log

- Nenhuma decisão arquitetural nova neste checkpoint. A configuração de transport security segue a opção documentada do ABP/OpenIddict apenas para Development quando `AuthServer:RequireHttpsMetadata=false`; produção continua exigindo HTTPS.
- A paginação pública usa o DTO padrão `PagedResultDto<T>` do ABP para expor itens e total; não foram adicionados filtros, sorting ou infraestrutura de busca.
- Decisões arquiteturais anteriores permanecem em `../../MDV.md` e `../../adr/`.

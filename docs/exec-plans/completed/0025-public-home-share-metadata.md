# Execution Plan 0025 — Public Home Share Metadata

Status: **COMPLETO**

## Objetivo

Fechar a metadata social mínima da home pública já existente:

`/ → title/description atuais → Open Graph/Twitter → link compartilhável coerente`

## Evidência que abriu o slice

- `public-web/app/layout.tsx` já definia o título público padrão `Bom Pra Ti` e a descrição `Encontre veículos e fale diretamente com o vendedor.`.
- A home `/` já era a entrada pública da descoberta e já estava no sitemap.
- Listing, Vehicle Hub e Seller Hub já possuíam padrões comprovados de Open Graph/Twitter.
- `public-web/lib/site-url.ts` já era a autoridade para URL pública absoluta via `BPT_PUBLIC_BASE_URL`.
- Sort/ranking exigiria semântica de produto nova; JSON-LD exigiria escolha de vocabulário/schema; sitemap completo do Vehicle Hub exigiria enumeração canônica independente das ofertas. A metadata social da home era o menor gap com regra e infraestrutura já provadas.

## Escopo entregue

- `public-web/app/page.tsx` publica Open Graph somente para `/` com `type=website`;
- título social reutiliza `Bom Pra Ti` e descrição social reutiliza `Encontre veículos e fale diretamente com o vendedor.`;
- `og:url` usa `publicUrl("/")`, portanto a autoridade absoluta continua em `BPT_PUBLIC_BASE_URL`;
- Twitter usa `summary`, com o mesmo título e descrição;
- nenhuma `og:image` ou `twitter:image` é declarada sem asset canônico dedicado;
- a metadata não foi promovida ao root layout;
- `scripts/public-seo-http-smoke.sh` valida o HTML real da home e prova que `/favoritos` não recebe metadata social da home;
- nenhum workflow novo foi criado.

## Fora de escopo preservado

- imagem social dedicada;
- JSON-LD/schema.org;
- metadata social genérica de rotas utilitárias/autenticadas;
- landing pages ou páginas agregadas novas;
- keywords/conteúdo editorial;
- Search Console/analytics;
- ranking/sort;
- backend, contrato, schema, migration ou endpoint novo.

## Critérios de aceite

1. [x] home continua publicando o mesmo title e description normais.
2. [x] home publica `og:type=website`, `og:title`, `og:description` e `og:url` absoluto.
3. [x] home publica `twitter:card=summary`, `twitter:title` e `twitter:description`.
4. [x] home não publica `og:image` nem `twitter:image` inventados.
5. [x] metadata permanece na home e não vaza para `/favoritos` via root layout.
6. [x] smoke SEO real e os 9 workflows aplicáveis passaram no head funcional corrigido; merge condicionado a CI fresco no head documental final.

## Evidência executada

Head funcional corrigido: `03f95e765552609835b668465a9352f76ca65d58`.

Public Buyer HTTP Gate:

- run `32783100691`;
- job `97609208968`;
- conclusão: `success`.

Marcadores novos observados no log:

- `PUBLIC_SEO_HOME_SHARE_METADATA: PASS`
- `PUBLIC_SEO_HOME_SHARE_METADATA_NO_IMAGE: PASS`
- `PUBLIC_SEO_HOME_SHARE_METADATA_SCOPED: PASS`

O mesmo job manteve verdes Public Buyer, Seller Hub, Vehicle Hub, sitemap/canonical existentes e authenticated Lead forwarding. Builds .NET observados no gate: `0 Warning(s)`, `0 Error(s)`.

No head funcional corrigido, os 9 workflows aplicáveis concluíram `success`:

- BPT2 Harness Gate
- BPT2 Public Web Gate
- BPT2 Public Buyer HTTP Gate
- BPT2 Public Discovery HTTP Gate
- BPT2 Buyer Favorites HTTP Gate
- BPT2 Seller Auth HTTP Gate
- BPT2 Seller Draft Edit HTTP Gate
- BPT2 Seller Shell HTTP Gate
- BPT2 Seller Photos Publish HTTP Gate

Classe de evidência: **B** — comportamento reproduzido em CI com banco fresco, host real e Next real.

## Correção focada registrada

O primeiro head funcional `29a1f1d19c2003c8c14048586d509e3f244e9484` falhou somente no início do smoke SEO, depois de Public Buyer, Seller Hub e Vehicle Hub já passarem. A causa foi o próprio harness: a variável de arquivo temporário foi nomeada `HOME`, sobrescrevendo o diretório home do runner e fazendo `dotnet build` abortar antes das assertions de metadata.

A correção renomeou somente essa variável para `HOME_HTML`. O código de produto permaneceu inalterado. O head corrigido `03f95e765552609835b668465a9352f76ca65d58` passou o gate focal e 9/9 workflows.

## Decision log

- **DECIDIDO:** a metadata social pertence à home `/`, não ao root layout inteiro.
- **DECIDIDO:** título e descrição sociais reutilizam os valores públicos já existentes; não existe copy paralela.
- **DECIDIDO:** sem asset canônico da home, Twitter usa `summary` e nenhuma imagem social é declarada.
- **NÃO DECIDIDO:** imagem dedicada, JSON-LD, conteúdo/keywords, analytics, landing pages, ranking/sort e metadata social de futuras páginas agregadas.

## Progress log

- 2026-08-24: `main` remoto confirmado em `f5652d860217e690cd01f514b832f7697587fc58`, merge do Plan 0024, sem execution plan ativo ou blocker.
- 2026-08-24: auditoria comparou metadata social da home, sitemap completo do Vehicle Hub, JSON-LD e sort/ranking; metadata social da home foi selecionada como menor gap com regra e infraestrutura já provadas.
- 2026-08-24: branch `feat/public-home-share-metadata` criada e draft PR #44 aberto antes do código.
- 2026-08-24: home recebeu Open Graph/Twitter local à rota; smoke SEO passou a provar metadata, ausência de imagem e ausência de vazamento para `/favoritos`.
- 2026-08-24: primeiro head revelou colisão da variável de teste `HOME`; correção ficou restrita ao harness (`HOME_HTML`).
- 2026-08-24: head funcional corrigido `03f95e765552609835b668465a9352f76ca65d58` fechou 9/9 workflows aplicáveis em `success`.

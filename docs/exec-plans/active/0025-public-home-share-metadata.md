# Execution Plan 0025 — Public Home Share Metadata

Status: **ATIVO**

## Objetivo

Fechar a metadata social mínima da home pública já existente:

`/ → title/description atuais → Open Graph/Twitter → link compartilhável coerente`

## Evidência que abriu o slice

- `public-web/app/layout.tsx` já define o título público padrão `Bom Pra Ti` e a descrição `Encontre veículos e fale diretamente com o vendedor.`.
- A home `/` já é a entrada pública canônica da descoberta e está presente no sitemap.
- Listing, Vehicle Hub e Seller Hub já possuem padrões comprovados de Open Graph/Twitter em slices anteriores.
- `public-web/lib/site-url.ts` já é a autoridade para URL pública absoluta via `BPT_PUBLIC_BASE_URL`.
- O gap de metadata social da home permaneceu explicitamente aberto; sort/ranking exigiria semântica nova, JSON-LD exigiria escolha de vocabulário/schema e sitemap completo do Vehicle Hub exigiria enumeração canônica independente das ofertas.

## Escopo

- adicionar Open Graph somente à home `/`, com `type=website`;
- reutilizar o título e a descrição públicos já existentes;
- usar `publicUrl("/")` como URL social absoluta;
- adicionar Twitter card `summary` com o mesmo título e descrição;
- não declarar imagem social enquanto não existir asset canônico dedicado;
- ampliar o smoke SEO existente para validar o HTML real da home;
- não criar workflow novo.

## Fora de escopo

- imagem social dedicada;
- JSON-LD/schema.org;
- metadata social de rotas utilitárias/autenticadas;
- landing pages e páginas agregadas novas;
- keywords/conteúdo editorial;
- Search Console/analytics;
- ranking/sort;
- backend, contrato, schema, migration ou endpoint novo.

## Critérios de aceite

1. [ ] home continua publicando o mesmo title e description normais.
2. [ ] home publica `og:type=website`, `og:title`, `og:description` e `og:url` absoluto.
3. [ ] home publica `twitter:card=summary`, `twitter:title` e `twitter:description`.
4. [ ] home não publica `og:image` nem `twitter:image` inventados.
5. [ ] metadata não é promovida ao root layout, evitando autoridade social genérica sobre rotas utilitárias.
6. [ ] smoke SEO real e workflows aplicáveis passam no head funcional e novamente no head documental final.

## Decision log

- **DECIDIDO para este slice:** a metadata social é da home `/`, não do root layout inteiro.
- **DECIDIDO para este slice:** título e descrição sociais reutilizam os valores públicos já existentes; não se cria copy paralela.
- **DECIDIDO para este slice:** sem asset canônico de home, Twitter usa `summary` e nenhuma imagem social é declarada.
- **NÃO DECIDIDO:** imagem dedicada, JSON-LD, conteúdo/keywords, analytics, landing pages, ranking/sort e metadata social de futuras páginas agregadas.

## Progress log

- 2026-08-24: `main` remoto confirmado em `f5652d860217e690cd01f514b832f7697587fc58`, merge do Plan 0024, sem execution plan ativo ou blocker.
- 2026-08-24: auditoria comparou metadata social da home, sitemap completo do Vehicle Hub, JSON-LD e sort/ranking; metadata social da home foi selecionada como menor gap com regra e infraestrutura já provadas.
- 2026-08-24: branch `feat/public-home-share-metadata` criada diretamente do `main` verificado.

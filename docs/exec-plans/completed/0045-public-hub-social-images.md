# Execution Plan 0045 — Public Hub Social Images

Status: **CONCLUÍDO**

## Objetivo

Fechar uma inconsistência concreta de SEO/social: Seller Hub e Vehicle Hub já exibem fotos de Listings publicados, mas seus metadados Open Graph/Twitter não reutilizam essas fotos, enquanto o Listing detail já usa a primeira foto pública como social preview.

Vertical proof:

`Listing publicado com foto → Seller Hub / Vehicle Hub → og:image + twitter:image → mesma foto pública já exibida`

## Contexto

Base remota atualizada: `e8d03ab743b402ab6339e4a413889bd4f61574bb`, após o Plan 0044 reconciliar o estado canônico de produto.

Evidência:

- `PRODUCT.md` consolidado registra metadata social de Listing, Vehicle Hub, Seller Hub e home como capacidade entregue;
- Listing detail já inclui sua primeira foto pública em `openGraph.images` e `twitter.images`;
- Seller Hub já carrega o primeiro Listing público em `generateMetadata`, mas não usava sua foto;
- Vehicle Hub exibe fotos dos Listings públicos, mas não carregava uma oferta para metadata;
- reutilizar a foto pública já exibida fecha a inconsistência sem criar asset, branding, crop ou regra editorial.

## Escopo

- Seller Hub reutiliza a primeira foto do primeiro Listing público já carregado;
- Vehicle Hub carrega somente um Listing público para selecionar sua primeira foto;
- `summary_large_image` quando houver foto; `summary` sem imagem quando não houver;
- canonical/title/description/robots preservados;
- um smoke HTTP focal cria um Listing com foto e prova Seller Hub + Vehicle Hub;
- após Pause, Vehicle Hub continua existente e volta ao estado sem imagem;
- Public Buyer HTTP Gate existente executa a prova.

## Fora de escopo

- imagem social gerada/branded/dedicada;
- crop, resize, CDN ou processamento de imagem;
- escolha editorial de foto;
- schema/migration/infra;
- alteração de contratos backend;
- novo workflow.

## Critérios de aceite

1. [ ] Seller Hub com Listing público fotografado emite `og:image` e `twitter:image` com a URL pública da foto.
2. [ ] Vehicle Hub com Listing público fotografado emite `og:image` e `twitter:image` com a mesma URL pública.
3. [ ] ambos usam `summary_large_image` quando a imagem existe.
4. [ ] Vehicle Hub sem oferta pública fotografada preserva `summary` sem inventar imagem.
5. [ ] canonical/title/description/robots permanecem inalterados.
6. [ ] nenhum asset, schema, infra ou regra editorial nova é criado.

## Decision log

- **DECIDIDO por evidência:** reutilizar a foto pública existente em vez de gerar imagem dedicada sem direção visual definida.
- **DECIDIDO:** o mesmo padrão de primeira foto já usado no Listing detail é a regra mínima coerente para os hubs.
- **DECIDIDO:** ausência de foto não gera fallback artificial.
- **DECIDIDO por teste:** um smoke focal cobre os dois hubs; smokes maduros existentes continuam cobrindo seus demais contratos e estados sem foto.
- **DECIDIDO:** o Plan 0044 pertence à reconciliação documental mergeada externamente; este slice foi renumerado para 0045 após detectar o drift de `main`.

## Progress log

- 2026-08-25: slice originalmente iniciado sobre `329303692e061864a3f9540812e46e55a06f125a`.
- 2026-08-25: `main` avançou para `e8d03ab743b402ab6339e4a413889bd4f61574bb` via PR #63/Plan 0044; branch foi reposicionada sobre essa base e o slice renumerado para 0045.
- 2026-08-25: Seller Hub passou a reutilizar a primeira foto do primeiro Listing público em OG/Twitter metadata.
- 2026-08-25: Vehicle Hub passou a consultar somente um Listing público para metadata e reutilizar sua primeira foto.
- 2026-08-25: `scripts/public-hub-social-images-http-smoke.sh` criado e ligado ao Public Buyer HTTP Gate existente.
- 2026-08-25: Public Buyer HTTP Gate passou integralmente no banco descartável local; Buyer flow, Seller Hub, Vehicle Hub e hub social images verdes, com Vehicle Hub JSON-LD validado pela asserção estrutural e reutilização da foto pública sem fallback inventado.

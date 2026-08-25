# Execution Plan 0044 — Public Hub Social Images

Status: **ATIVO**

## Objetivo

Fechar uma inconsistência concreta do gap pós-MVP de SEO/social registrado no Plan 0027: Seller Hub e Vehicle Hub já exibem fotos de Listings publicados, mas seus metadados Open Graph/Twitter não expõem imagem, enquanto o Listing detail já usa a primeira foto pública como social preview.

Vertical proof:

`Listing publicado com foto → Seller Hub / Vehicle Hub → og:image + twitter:image apontam para a mesma foto pública já exibida`

## Contexto

Base remota verificada: `329303692e061864a3f9540812e46e55a06f125a`, após o merge do Plan 0043.

Evidência atual:

- Plan 0027 mantém `social image dedicada` como gap SEO/social pós-MVP;
- Listing detail já usa a primeira foto pública do anúncio em `openGraph.images` e `twitter.images`;
- Seller Hub carrega o primeiro Listing publicado em `generateMetadata`, mas omite `images` e usa `twitter.card = summary`;
- Vehicle Hub exibe fotos dos Listings publicados na página, mas `generateMetadata` não carrega uma imagem e também omite `images`;
- reutilizar a primeira foto pública já exibida evita asset, branding, crop ou regra editorial nova.

## Escopo

- Seller Hub: usar a primeira foto do primeiro Listing público já carregado para `og:image`/`twitter:image`;
- Vehicle Hub: carregar somente um Listing público para selecionar a primeira foto disponível para metadata;
- usar `summary_large_image` quando houver imagem e preservar `summary` quando não houver;
- manter canonical/title/description/robots atuais;
- provar por HTTP real que os dois hubs emitem a URL da foto pública quando existe;
- preservar comportamento sem imagem quando nenhum Listing com foto estiver disponível;
- reutilizar o Public Buyer HTTP Gate existente.

## Fora de escopo

- geração de imagem social dedicada/branded;
- crop, resize, CDN ou processamento de imagem;
- escolha editorial de foto;
- schema/migration/infra;
- alteração do contrato de Listing/Vehicle/Seller;
- novo workflow.

## Critérios de aceite

1. [ ] Seller Hub publicado com foto emite `og:image` e `twitter:image` com URL pública da primeira foto disponível.
2. [ ] Vehicle Hub publicado com foto emite `og:image` e `twitter:image` com URL pública da primeira foto disponível.
3. [ ] ambos usam `summary_large_image` quando há imagem.
4. [ ] páginas sem foto continuam válidas sem inventar imagem fallback.
5. [ ] canonical/title/description/robots permanecem inalterados.
6. [ ] nenhum asset, schema, infra ou regra editorial nova é criado.

## Decision log

- **DECIDIDO por evidência:** reutilizar foto pública já exibida em vez de criar imagem social dedicada sem direção visual definida.
- **DECIDIDO:** primeira foto disponível do primeiro Listing público é suficiente porque o mesmo padrão já é usado no Listing detail e no card visual do hub.
- **DECIDIDO:** sem foto, preservar metadata sem `images`; não inventar fallback.

## Progress log

- 2026-08-25: `main` remoto confirmado em `329303692e061864a3f9540812e46e55a06f125a`.
- 2026-08-25: Listing detail confirmado com `og:image`/`twitter:image` pela primeira foto pública.
- 2026-08-25: Seller Hub e Vehicle Hub confirmados sem imagem social apesar de exibirem fotos de Listings publicados.

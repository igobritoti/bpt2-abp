# Benchmark funcional externo reproduzível — refresh 2026-08-27

Status: **CHECKPOINT / INVENTÁRIO**, não autorização de implementação.

## Objetivo

Repetir o benchmark de portais automotivos com comportamento público observável na data corrente e cruzar somente capacidades verificáveis com o estado atual do BPT2, buscando gaps novos sem transformar paridade de mercado em requisito.

Regra de evidência:

`comportamento público reproduzível > código BPT2 > documentação atual > evidência histórica > inferência`

## Fontes reproduzidas

### Webmotors

Página pública de estoque/busca observada em 2026-08-27. A superfície corrente expõe, entre outros:

- localização e raio;
- marca, modelo e versão;
- intervalo de ano;
- usado/0 km;
- tipo de vendedor: concessionária, loja e pessoa física;
- preço e filtro abaixo da FIPE;
- quilometragem;
- sinais como vistoriado e visão 360°.

Referência observada: página pública `webmotors.com.br/carros-usados/...` e variantes de estoque, crawled em 2026-08-25/26 pelo benchmark atual.

### OLX Autos

Página pública de carros, vans e utilitários observada em 2026-08-27. A superfície corrente expõe, entre outros:

- marca, modelo e versão;
- motor;
- aceita trocas;
- quilometragem;
- ano e preço;
- abaixo da FIPE;
- câmbio;
- combustível;
- carroceria/tipo;
- cor;
- opcionais;
- documentação/conservação;
- tipo de anunciante particular/profissional;
- ordenação por mais recentes e preço;
- sinais de histórico/vistoria.

Referência observada: `olx.com.br/autos-e-pecas/carros-vans-e-utilitarios/busca/carros-novos-e-usados`, crawled em 2026-08-26.

### iCarros

O benchmark anterior continua útil como evidência histórica, mas este refresh não depende dele para promover nenhum gap: as convergências relevantes abaixo já são reproduzidas por Webmotors e/ou OLX atuais.

### Carros na Web

**NÃO REPRODUZÍVEL como fonte corrente.** O acesso direto continua respondendo 502 no probe atual. Conteúdo antigo/indexado não é usado como denominador nem como prova de funcionalidade atual.

## Cruzamento com BPT2

### 1. Cor — novo gap testável

**Evidência externa:** OLX expõe filtro categórico de cor; Webmotors também documenta cor entre seus filtros de busca.

**Evidência BPT2:** `Listing` já persiste `Color` e o DTO público devolve `color`, mas `PublicListingSearchInput` e o public web não possuem critério de cor.

**Classificação:** `GAP REAL — TESTAR ANTES`.

Não há dependência de provider, dataset de mercado, geocoding ou enrichment externo para testar a hipótese. Há, porém, uma questão semântica real: `Listing.Color` é texto livre, não taxonomia canônica.

Hipótese falsificável:

> Um critério de cor normalizado sobre o dado já persistido consegue refinar a busca sem criar taxonomia falsa nem quebrar Saved Search/matching.

Teste mínimo antes de implementação funcional:

1. fixture com Listings públicos de cores equivalentes em variações de caixa/espaço e uma cor distinta;
2. definir explicitamente se a primeira semântica é igualdade normalizada de texto ou conjunto canônico — não inferir sinonímia;
3. provar que filtro por cor retorna somente Listings públicos correspondentes;
4. provar composição com Brand/Model/preço/localização;
5. provar query-string round-trip;
6. se promovido, incluir `Color` na identidade semântica de Saved Search e no matching de nova oferta; caso contrário, reprovar o slice por inconsistência entre busca e busca salva.

### 2. Seleção guiada de versão — parcial, não gap de backend puro

**Evidência externa:** Webmotors e OLX expõem seleção explícita de versão.

**Evidência BPT2:** a busca backend já aceita `VehicleId`, e a projeção pública possui Brand/Model/Generation/Version. No public web, porém, `vehicleId` aparece apenas como estado oculto quando já está presente; o formulário visível oferece Brand e Model, não um seletor canônico de versão.

**Classificação:** `PARCIAL — INVESTIGAR UX/CONTRATO`, não promover automaticamente.

Antes de qualquer implementação deve ser provado que existe contrato público adequado para resolver Brand → Model → Generation/Version → Vehicle sem duplicar catálogo no frontend e que a seleção melhora um problema real além da busca textual já existente.

### 3. Ordenação por recência — gap observado, pré-condição temporal ausente

**Evidência externa:** OLX oferece `Mais Recentes`.

**Evidência BPT2:** a busca pública aceita apenas ordenação por preço; a ordem padrão atual é `Listing.Id`. O agregado `Listing` não registra timestamp canônico de criação/publicação no contrato observado.

**Classificação:** `BLOQUEADO PARA PROMOÇÃO` até definir qual instante significa “recente” (criação, primeira publicação ou republicação) e persistir/provar essa semântica.

Não ordenar por UUID nem derivar recência de eventos auxiliares.

### 4. Tipo de vendedor — gap de mercado, mas modelo BPT2 não possui taxonomia

Webmotors diferencia concessionária/loja/pessoa física e OLX diferencia particular/profissional. `SellerProfile` BPT2 possui somente `DisplayName` e `WhatsAppNumber`.

**Classificação:** `ADIADO / VALIDAR ANTES`.

Paridade externa não define qual taxonomia BPT2 deve possuir. Reabrir somente com necessidade de Buyer/Seller e regra verificável de classificação.

### 5. Câmbio, combustível, carroceria/motor/opcionais

São refinamentos reproduzíveis em OLX e aparecem no benchmark de mercado, mas o BPT2 atual não publica esses campos no contrato estrutural consumido pela busca.

**Classificação:** permanece `BLOQUEADO POR ENRICHMENT/CONTRATO`, alinhado ao blocker já existente de Vehicle Knowledge. Não criar campos paralelos no Marketplace para contornar o Podium/Catalog.

### 6. Abaixo da FIPE / contexto de preço

Webmotors e OLX expõem filtro abaixo da FIPE.

**Classificação:** permanece `BLOQUEADO` pelo gap já registrado de dataset/licença/metodologia/provenance de preço de mercado.

### 7. Raio/proximidade

Webmotors expõe raio.

**Classificação:** permanece `BLOQUEADO` pela ausência de autoridade geográfica e contrato de distância no BPT2.

### 8. Vistoria/histórico/confiança

Webmotors e OLX exibem sinais de vistoria/histórico/documentação.

**Classificação:** permanece `BLOQUEADO` pelo mesmo provider/privacy/legal/validity contract já registrado para Trust.

### 9. Aceita troca, financiamento e serviços comerciais

Existem no mercado, mas não foi encontrada nova evidência de problema BPT2 que justifique promoção.

**Classificação:** `ADIADO` conforme tese comercial/serviços complementares já documentada.

## Resultado

O refresh não destravou os blockers conhecidos, mas encontrou um delta funcional novo e autocontido:

**Discovery → filtro por cor: `GAP REAL — TESTAR ANTES`.**

Também refinou dois deltas que não devem ser confundidos com implementação pronta:

- seletor guiado de versão: `PARCIAL` porque `VehicleId` já existe no contrato, mas a UI pública não oferece seleção canônica visível;
- ordenação por recência: gap externo observado, porém bloqueado por ausência de semântica temporal canônica no Listing.

Nenhum outro item do benchmark é promovido neste checkpoint.

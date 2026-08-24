# Execution Plan 0015 — Public Vehicle Hub

Status: **ATIVO**

## Objetivo

Abrir a primeira fatia real de Vehicle Hub reutilizando integralmente o catálogo canônico e a busca pública já existentes:

`Listing público → Vehicle canônico → Hub público do Vehicle → Listings publicados desse Vehicle`

O slice deve criar uma página pública estável para um `Vehicle` canônico sem duplicar autoridade, sem inventar enrichment/specs ausentes e sem alterar o schema.

## Evidência que abriu o slice

- `PRODUCT.md` mantém Vehicle Hub como capacidade central.
- Catalog já modela `Brand → Model → Generation → Version → Vehicle` e `VehicleRefDto` já projeta essa identidade.
- `IVehicleCatalogAppService.GetAsync(id)` já expõe o Vehicle canônico por HTTP.
- `PublicListingSearchInput.VehicleId` e `PublicListingQuery` já filtram Listings públicos pelo Vehicle exato.
- o public web já possui SSR, metadata/canonical, cards de Listing e helper de busca pública.
- Promoções não possuem aggregate/contrato equivalente já modelado; um Vehicle Hub mínimo exige menos decisão nova e nenhuma infraestrutura adicional.

## Escopo

- adicionar helper read-only no public web para carregar `VehicleRefDto` pelo Catalog HTTP existente;
- criar `/veiculos/[id]` como página pública SSR;
- exibir Brand, Model, Generation quando houver, Version e ModelYear vindos exclusivamente do Catalog;
- listar somente Listings atualmente públicos cujo `VehicleId` corresponda exatamente ao Vehicle do Hub;
- linkar o detalhe público do anúncio ao Hub do Vehicle canônico;
- publicar metadata/canonical do Hub;
- provar por HTTP real que Vehicle existente sem depender de Listing continua tendo Hub, Published aparece e Pause remove o Listing sem remover o Hub;
- reutilizar o Public Buyer HTTP Gate existente.

## Fora de escopo

- specs técnicas, equipamentos, segurança, consumo, preço de mercado, editorial ou imagens enriquecidas ainda não modelados;
- páginas agregadas por Brand/Model/Generation/Version;
- sitemap de todo o catálogo, até existir paginação/enumerabilidade adequada do Catalog;
- reviews, comparativos, FIPE, histórico, scoring ou conteúdo editorial;
- promoções;
- mudança de schema, migration, módulo, cache, search engine ou infraestrutura nova.

## Critérios de aceite

1. [ ] `/veiculos/{vehicleId}` retorna 200 para Vehicle canônico existente e 404 para id inexistente.
2. [ ] Hub mostra somente identidade proveniente do Catalog canônico.
3. [ ] detalhe de Listing publicado contém link para o Hub do seu `vehicleId`.
4. [ ] Listing Draft não aparece no Hub.
5. [ ] Listing Published do Vehicle aparece no Hub com link ao detalhe.
6. [ ] após Pause, o Listing deixa de aparecer no Hub.
7. [ ] o Hub do Vehicle continua 200 depois do Pause.
8. [ ] metadata inclui title e canonical absoluto do Hub existente; id inexistente é noindex.
9. [ ] build/public HTTP/harness aplicáveis passam no head final.
10. [ ] docs fecham somente a fatia comprovada, sem transformar enrichment futuro em requisito.

## Checkpoints

- [x] refetch do `main` remoto em `4057a770c77d42146a7679d103846a9ec009699d`.
- [x] auditar Promoções, Vehicle Hub e capabilities já modeladas.
- [x] confirmar que Catalog GET + filtro público por `VehicleId` já cobrem os dados necessários.
- [ ] abrir draft PR.
- [ ] implementar helper + Hub + link do detalhe.
- [ ] ampliar a prova HTTP existente somente com assertions do Hub.
- [ ] corrigir apenas falhas observadas.
- [ ] self-review e fechamento documental.
- [ ] exigir CI fresco no head final e merge somente verde.
- [ ] verificar `main` pós-merge e zero planos ativos.

## Decisões abertas necessárias

Nenhuma decisão arquitetural nova. Conteúdo/enrichment do Vehicle Hub, estratégia de URLs semânticas e enumeração em sitemap permanecem abertas até existir dados e caso real.

## Decision log

- **DECIDIDO para este slice:** identidade do Hub é o `Vehicle` canônico por `id`; não haverá cópia de dados automotivos no Marketplace/public web.
- **DECIDIDO para este slice:** disponibilidade comercial é derivada da projeção pública existente filtrada por `VehicleId`; Draft/Pause/Archive continuam invisíveis estruturalmente.
- **DECIDIDO para este slice:** a primeira URL é `/veiculos/{id}` para não inventar slug policy antes de haver necessidade.
- **NÃO DECIDIDO:** enrichment, páginas agregadas, slug final, sitemap completo do catálogo e conteúdo editorial.

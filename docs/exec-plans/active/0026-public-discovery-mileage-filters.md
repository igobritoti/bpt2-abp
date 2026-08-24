# Execution Plan 0026 — Public Discovery Mileage Filters

Status: active

## Outcome

Fechar o menor gap comprovado na descoberta pública usando somente dados já persistidos e projetados:

`Listing.MileageKm → MinMileageKm/MaxMileageKm → busca pública SSR → paginação preserva filtro`

## Evidence

- `PublicListingDto` já entrega `MileageKm`.
- `PublicListingSearchInput` ainda não aceita quilometragem.
- `PublicListingQuery` já aplica ranges para preço e ano, mas não para `MileageKm`.
- A home pública já usa query string como estado canônico e já possui infraestrutura de campos numéricos e preservação na paginação.
- O smoke de discovery já cria `MileageKm` nos fixtures, porém todos recebem o mesmo valor e portanto não provam filtragem.

## Boundary

Implementar somente:

- `MinMileageKm` e `MaxMileageKm` no contrato público de busca;
- range inclusivo sobre `Listing.MileageKm` quando o valor estiver presente;
- range invertido retorna página vazia, seguindo o comportamento já existente de preço/ano;
- serialização e query string no public web;
- dois campos numéricos na home;
- paginação preservando quilometragem;
- smoke HTTP com quilometragens distintas e prova de Draft invisível.

Fora do slice:

- filtro de cor;
- normalização/vocabulário de cores;
- ordenação/ranking;
- facets/autocomplete;
- geocoding/proximidade;
- engine de busca externa;
- schema/migration novo.

## Acceptance

PASSA somente se:

1. filtro mínimo seleciona Listings públicos com `MileageKm >= MinMileageKm`;
2. filtro máximo seleciona Listings públicos com `MileageKm <= MaxMileageKm`;
3. range combinado é inclusivo;
4. range invertido retorna vazio;
5. Listings com `MileageKm = null` não entram quando algum limite é informado;
6. Draft permanece invisível;
7. query string/paginação preservam os limites;
8. regressões existentes continuam verdes.

## Workflow

Branch → draft PR → checks aplicáveis → correção somente por evidência → documentação final → CI fresco → review/base refresh → merge somente verde → verificação pós-merge.

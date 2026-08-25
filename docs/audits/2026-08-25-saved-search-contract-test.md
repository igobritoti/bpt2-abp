# Saved Search / Alerts — contract test

Data: 2026-08-25

Status: auditoria do Plan 0046; candidata nova de produto, não transplantada automaticamente do BPT1.

## Evidência

### Mercado

A OLX mantém buscas salvas derivadas de texto/filtros e pode notificar novos anúncios ou mudanças de preço que correspondam à busca.

### Donor BPT1

Foi localizada entrega de retenção para `PRICE_DROP`, `WEEKLY_REPORT` e `LEAD_STAGNATION`, com claiming, retry e idempotência. Até este checkpoint não foi comprovada uma entidade/contrato de `SavedSearch` equivalente ao comportamento de mercado.

Leitura: Saved Search é candidata **nova** para BPT2. O donor pode fornecer casos negativos de entrega, mas não define o contrato da busca salva.

### BPT2

`PublicListingSearchInput` já contém os critérios de discovery:

- `VehicleId`;
- `SellerId`;
- `Brand`;
- `Model`;
- `City`;
- `StateCode`;
- faixa de ModelYear;
- faixa de preço;
- faixa de quilometragem;
- `Query` textual;
- `Sort`;
- `Skip`/`Take`.

## Resultado do teste de desenho

**Não persistir `PublicListingSearchInput` inteiro como Saved Search.**

`Skip` e `Take` são estado de paginação, não intenção estável da busca. `Sort` pode ser preferência de apresentação, mas não deve alterar semanticamente quais Listings satisfazem o alerta.

## Recomendação proativa

Classificação: **ADICIONAR + EDITAR CONTRATO**.

Definir, se promovido, um contrato conceitual separado de `SavedSearchCriteria` composto apenas pelos filtros que definem membership do conjunto de resultados.

Nome é ilustrativo; não implica classe/schema aprovado.

### Critérios candidatos

- VehicleId quando a busca for por Vehicle específico;
- Brand/Model;
- City/StateCode enquanto estes forem a autoridade geográfica atual;
- Min/MaxModelYear;
- Min/MaxPrice;
- Min/MaxMileageKm;
- Query textual normalizada.

### Fora do matching

- Skip;
- Take;
- página corrente;
- estado visual da UI;
- Sort, salvo se futuramente houver uma razão explícita de produto para persistir como preferência, mas nunca como critério de match.

## Hipótese falsificável

> Os critérios estáveis da busca pública podem ser serializados, persistidos e reexecutados de forma determinística, produzindo o mesmo conjunto lógico de Listings públicos independentemente de página/ordenação.

## Testes necessários antes de implementation plan

1. round-trip dos filtros públicos → critério salvo → filtros públicos;
2. duas URLs que diferem apenas em paginação devem normalizar para a mesma busca salva;
3. mudança de ordenação não deve criar alerta semanticamente diferente;
4. Draft/private nunca gera match;
5. Listing que deixa de ser público deixa de ser candidato a novos alertas, sem apagar histórico de notificações já geradas;
6. deduplicação por `SavedSearch + Listing + TriggerKind + TriggerVersion` ou semântica equivalente;
7. price-drop precisa comparar valor anterior/novo e regra do usuário, não apenas reexecutar a busca;
8. opt-in/opt-out e frequência são obrigatórios antes de entrega real;
9. nenhum canal de entrega (email/push/etc.) deve ser escolhido antes do contrato de matching estar provado.

## Relação com Favorites

Favorite é vínculo explícito do Buyer com um Listing específico. Saved Search é uma intenção persistida sobre um conjunto potencial de Listings. Não unir os dois modelos por conveniência.

Um alerta de queda de preço pode futuramente existir tanto para Favorite quanto para Saved Search, mas os triggers e a semântica de membership devem permanecer explícitos.

## Estado

`CANDIDATO FORTE PARA TESTE`, ainda não `TRAZER`.

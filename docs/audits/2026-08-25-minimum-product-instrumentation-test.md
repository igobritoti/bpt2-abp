# Instrumentação mínima de produto — decision-first test

Data: 2026-08-25

Status: auditoria do Plan 0046; não define fornecedor nem infraestrutura de analytics.

## Problema

O BPT1 possui EventLog/analytics amplo e mistura métricas de produto, attribution, delivery de retenção e eventos de features específicas. Copiar esse desenho criaria eventos para funcionalidades que ainda não existem e poderia confundir estado de domínio com telemetria.

## Princípio testado

**Nenhum evento de analytics entra sem uma pergunta de produto que ele ajude a responder.**

Estado persistente de domínio deve continuar sendo autoridade para fatos de domínio. Analytics serve para comportamento/experimento, não para reconstruir a verdade operacional quando ela já existe no domínio.

## Perguntas atuais que justificam instrumentação

### Comparador

Pergunta: usuários que usam comparação avançam para uma oferta/contato?

Eventos candidatos mínimos, somente quando a feature existir:

- comparison_viewed / comparison_started;
- comparison_listing_selected ou CTA equivalente;
- associação ao conjunto/cardinalidade sem registrar conteúdo sensível desnecessário.

Lead gerado continua sendo fato do domínio Marketplace; analytics apenas associa a jornada quando a metodologia permitir.

### Saved Search / alerts

Perguntas:

- a busca salva é utilizada?
- alertas gerados são úteis sem excesso de notificações?

Fatos persistentes como SavedSearch criada e Delivery gerada devem existir em seus próprios contratos quando a feature for implementada. Analytics pode medir interação, por exemplo abertura/click, mas não deve ser a única prova de que o alerta existiu.

### Promotions

Pergunta: promoção aumenta exposição/contato em relação ao baseline comparável?

Eventos mínimos:

- promoted impression;
- promoted click/selection;
- vínculo metodologicamente explícito com Lead quando possível.

Impressão orgânica necessária para denominador/baseline deve ter semântica consistente; não comparar promoted CTR contra métrica orgânica definida de modo diferente.

### Discovery/search

Pergunta atual: existe uma decisão que exige medir cada query executada?

Resultado: **NÃO demonstrado ainda**. Não registrar texto integral de busca por default apenas porque é tecnicamente possível.

Se uma futura hipótese de search exigir análise de query, definir antes retenção, normalização, privacidade e finalidade.

### CRM

Contacted/Closed/Outcome são fatos de domínio. Não criar evento de analytics como fonte primária desses estados.

Analytics só é necessário se uma pergunta adicional exigir comportamento de UI/jornada.

## Resultado do teste

**REPROVADO copiar o EventLog amplo do BPT1.**

**PROMOVIDA PARA DESENHO** uma instrumentação mínima orientada a decisões, mas ainda não para implementation plan independente.

## Recomendação proativa

Classificação: **SUBSTITUIR**.

Substituir `analytics module/dashboard` como primeira meta por um contrato enxuto, extensível e desacoplado de dashboard.

### Separações obrigatórias

- domain state/event ≠ product analytics event;
- operational delivery ≠ product analytics event;
- observability/log/trace ≠ product analytics event;
- marketing attribution ≠ identidade de usuário;
- dashboard ≠ requisito para começar a medir.

## Testes do futuro contrato

1. cada evento deve referenciar uma pergunta/hipótese documentada;
2. payload mínimo e finalidade explícita;
3. evento repetido não pode inflar métrica quando a semântica exige unicidade;
4. denominadores definidos antes do cálculo de CTR/conversion;
5. timestamps em UTC e versão de schema/evento quando necessário;
6. PII não entra por conveniência;
7. domain IDs só entram quando necessários para agregação/attribution definida;
8. eventos de features inexistentes são proibidos;
9. dashboard só é criado quando houver operador/pergunta recorrente que o justifique.

## Consequência para a ordem do roadmap

Instrumentação deixa de ser um grande slice anterior a todas as features. Em vez disso:

- definir o contrato mínimo antes do primeiro experimento que precise dele;
- implementar apenas os eventos necessários junto ou imediatamente antes da capability mensurada;
- manter agregação/dashboard posterior e proporcional à necessidade.

Isso reduz a chance de construir uma plataforma analítica sem perguntas de produto reais.

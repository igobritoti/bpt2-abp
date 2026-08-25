# Promotions — ranking separation test

Data: 2026-08-25

Status: auditoria do Plan 0046; não autoriza monetização ainda.

## Pergunta

O BPT2 deve transplantar o mecanismo de `HighlightScore` do BPT1 para implementar Promotions?

## Evidência donor

O BPT1 calcula um score único combinando:

- classificação de preço (`bestPurchase`);
- similaridade;
- upgrade signal;
- popularidade;
- recência;
- plano do usuário;
- promotion paga.

A promoção possui tipos como `ORGANIC`, `DESTAQUE`, `PATROCINADO`, `DIAMANTE` e adiciona bônus ao score final.

## Problema observado

O score mistura dimensões semanticamente diferentes:

- relevância/qualidade orgânica;
- comportamento/popularidade;
- hipótese de recomendação;
- plano comercial;
- pagamento por destaque.

Isso dificulta:

- explicar por que um resultado aparece acima de outro;
- medir lift causado especificamente pela promoção;
- manter baseline orgânico comparável;
- garantir que pagamento não seja interpretado como qualidade/confiança;
- alterar uma dimensão sem recalibrar todo o score.

## Evidência de mercado

Webmotors e OLX oferecem planos/destaques/turbinar/patrocinados como mecanismos comerciais identificáveis. A observação de mercado comprova que monetização por visibilidade é uma superfície real; não prova que um score único seja a implementação correta.

## Resultado

**REPROVADO transplantar `HighlightScore` do donor.**

A capability Promotions continua candidata, mas o algoritmo de ranking legado é classificado como detalhe técnico a excluir.

## Recomendação proativa

Classificação: **MANTER capability + SUBSTITUIR implementação + EXCLUIR score legado**.

Testar arquitetura conceitual com duas dimensões explícitas:

1. **organic eligibility/order** — definido por regras próprias e mensuráveis;
2. **sponsored placement/boost** — aplicado apenas a Listings elegíveis, identificado como promovido e mensurado separadamente.

Não é obrigatório que sponsored seja uma faixa separada; o requisito é que a política seja determinística, auditável e distinguível da relevância orgânica.

## Invariantes antes de implementação

- somente Listing atualmente público pode ser promovido;
- promotion nunca contorna moderação/visibilidade;
- expiração remove efeito comercial automaticamente;
- paid status não cria selo de confiança ou qualidade;
- promoted impression/click/Lead são medidos separadamente;
- baseline orgânico deve permanecer reconstruível para experimento;
- promoção sem impressão não pode ser contabilizada como exposição;
- impression precisa de definição objetiva de render/visibilidade antes de virar métrica;
- credits/payment não entram até o modelo comercial exigir.

## Hipótese falsificável

> Uma política comercial explícita consegue aumentar exposição de Listings elegíveis e medir lift sem tornar o ranking orgânico opaco nem misturar pagamento com confiança/qualidade.

## Teste de desenho

1. fixture com Listings públicos e não públicos;
2. baseline orgânico determinístico;
3. aplicar promoção a subconjunto elegível;
4. provar que Draft/private/moderated-out não aparecem;
5. provar expiração;
6. calcular distribuição orgânica antes/depois sem perder baseline;
7. medir promoted impression/click/Lead com denominadores explícitos;
8. reprovar desenho se não for possível explicar separadamente efeito orgânico e efeito pago.

## Consequência para o roadmap

Promotions permanece candidata comercial forte, mas o trabalho futuro começa por política/experimento de exposição, não por portar o scoring do BPT1.

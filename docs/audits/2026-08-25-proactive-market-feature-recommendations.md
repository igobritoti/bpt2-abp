# Recomendações proativas de produto — benchmark de mercado

Data: 2026-08-25

Status: evidência do Plan 0046; nenhuma recomendação autoriza implementação isoladamente.

## 1. Buscas salvas + alertas — ADICIONAR COMO CANDIDATA FORTE

### Evidência observada

A OLX mantém favoritos, buscas salvas e alertas de novos anúncios/mudança de preço. A busca salva preserva filtros e pode notificar quando surge resultado compatível.

O BPT2 já possui Favorites e busca pública com query string compartilhável, mas não possui busca salva/alerta.

### Recomendação

**ADICIONAR** ao roadmap uma capability explícita `Saved Search / Inventory Alerts`, separada de Favorite.

Primeiro slice candidato deve reutilizar o contrato de filtros público existente em vez de criar uma DSL nova.

### Hipótese falsificável

> Persistir a consulta pública canônica e reavaliá-la contra novos/alterados Listings consegue gerar alertas determinísticos sem duplicação e sem expor Listings privados.

### Testes mínimos

- round-trip entre query string pública e busca persistida;
- somente Listing público pode gerar match;
- idempotência/deduplicação por busca + Listing + evento;
- mudança de preço só gera alerta quando a regra configurada for satisfeita;
- opt-in e desligamento explícitos;
- frequência/rate-limit definidos antes de entrega real.

## 2. Contexto de preço de mercado — ADICIONAR, MAS DEPENDENTE DE DADOS

### Evidência observada

A Webmotors apresenta referência FIPE e referência própria de mercado, filtro de oportunidades abaixo da FIPE e, para alguns modelos, tendência de valorização/desvalorização. A própria plataforma declara considerar dados de mercado, anúncios, região, quilometragem, oferta/demanda e histórico de preço em suas avaliações.

O BPT2 ainda não possui base própria comprovada com volume suficiente para afirmar preço de mercado.

### Recomendação

**ADICIONAR COMO CANDIDATA**, mas **ADIAR implementação** até existir uma fonte contratualmente utilizável ou massa de dados BPT suficiente para benchmark reproduzível.

Separar três conceitos:

- referência externa licenciada/oficial, quando existir;
- estatística observada em anúncios BPT;
- preço pedido do Listing individual.

Nunca rotular preço como `justo`, `bom negócio` ou equivalente sem regra mensurável e auditável.

### Hipótese falsificável

> Uma estatística de preço com amostra, recorte temporal/geográfico e Vehicle comparável explícitos reduz incerteza sem criar falsa precisão.

## 3. Sinais de confiança / histórico veicular — ADICIONAR PARA PESQUISA, NÃO PARA IMPLEMENTAÇÃO IMEDIATA

### Evidência observada

A OLX oferece Histórico Veicular por parceiros que consultam fontes oficiais e também selo `Vistoriado` derivado de vistoria presencial por empresas credenciadas. A Webmotors expõe filtro para veículos `Vistoriado`.

O produto BPT2 declara confiança como parte do núcleo, mas hoje a moderação trata Listing/report e não certificação/histórico do veículo físico.

### Recomendação

**ADICIONAR** uma linha de pesquisa `Vehicle Trust Signals`, mantendo-a separada de moderação.

Possíveis sinais a investigar:

- laudo/vistoria válido e data de validade;
- histórico veicular fornecido por parceiro;
- identidade/documentação verificada sem expor dados pessoais;
- provenance do selo e expiração.

### Restrições

- não armazenar/expor placa, RENAVAM, CPF/CNPJ ou dados pessoais por conveniência;
- não inferir `vistoriado` a partir de descrição do vendedor;
- não construir integração antes de revisar contrato, privacidade, base legal, retenção e responsabilidade sobre dados de terceiros;
- selo deve carregar emissor, data e validade.

### Hipótese falsificável

> Um sinal de confiança verificável e temporalmente válido melhora decisão do comprador sem ser confundido com garantia do BPT sobre o estado total do veículo.

## 4. Qualidade/completude do anúncio — EDITAR COMO SINAL, NÃO COMO RANKING OPACO

### Evidência observada

A OLX declara que anúncios incompletos, desatualizados ou sem fotos perdem relevância na ordenação `Mais relevantes`. Webmotors orienta preenchimento de dados, opcionais e fotos como parte do anúncio.

### Recomendação

**EDITAR** a candidata `qualidade/completude do anúncio como sinal de ranking` para começar como **score operacional explicável ao Seller**, não como ranking público automático.

Primeiro uso sugerido:

- indicar campos/fotos úteis ausentes;
- medir completude;
- testar correlação com contato/Lead;
- só depois avaliar se deve afetar ranking.

### Hipótese falsificável

> Um score de completude transparente ajuda o Seller a melhorar o Listing e apresenta associação mensurável com engajamento, sem precisar alterar ranking público no primeiro experimento.

## 5. Promotions — MANTER, MAS SEPARAR DE CONFIANÇA E QUALIDADE

Planos/destaques são comuns em Webmotors e OLX, porém `pago`, `vistoriado` e `anúncio completo` representam conceitos diferentes.

### Recomendação

**MANTER Promotions**, mas proibir semanticamente que pagamento implique selo de qualidade/confiança do BPT. O produto deve distinguir:

- promoted/sponsored;
- verified/trust signal;
- completeness/quality signal;
- organic relevance.

Misturar essas dimensões degrada medição e pode induzir interpretação errada pelo comprador.

## Prioridade de pesquisa derivada

1. Vehicle Enrichment / reconciliation — bloqueio atual do Comparador;
2. Saved Search / alerts — forte encaixe com busca/favorites já entregues;
3. instrumentação mínima — necessária para medir efeitos;
4. CRM mínimo — operação Seller;
5. Promotions — monetização mensurável;
6. Vehicle Trust Signals — pesquisar contrato/privacy/parceiros;
7. market-price context — aguardar autoridade/volume de dados adequado;
8. listing completeness — testar como ferramenta Seller antes de ranking.

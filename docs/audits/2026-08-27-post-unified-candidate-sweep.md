# Post-unified functional candidate sweep

Data: 2026-08-27

Status: **CHECKPOINT**

## Objetivo

Usar a matriz unificada de cobertura funcional para testar os poucos candidatos ainda elegíveis a investigação sem reabrir capability já entregue ou contornar blocker explícito.

Regra:

`teste/código executado > código existente > documentação atual > issue/PR > inferência`

Este checkpoint não autoriza implementação por si só.

## 1. Attribution de marketing

### Estado observado no BPT2

A matriz unificada classifica attribution como `GAP REAL`, mas exige antes uma pergunta concreta de aquisição e contrato de privacidade.

Busca no `main` atual por sinais mínimos de implementação/captura não encontrou ocorrências de:

- `utm`;
- `referrer`;
- `campaign`.

O Lead atual preserva `UserId?`, `Channel`, lifecycle e outcome operacional, mas isso não equivale a attribution de aquisição.

### Evidência donor

A auditoria BPT1 registrou `source`, `medium`, `campaign`, `content`, `term`, `referrer` e `sessionId`, além de analytics derivados.

A existência desses campos no donor comprova capacidade anterior, não necessidade atual no BPT2.

### Resultado

**NÃO PROMOVER.**

Motivos verificáveis:

1. nenhuma pergunta de produto/operação atual exige distinguir campanha/origem;
2. não existe contrato atual de retenção/privacidade/uso desses sinais;
3. não há consumidor operacional ou experimento corrente cujo resultado dependa de attribution;
4. criar eventos/campos agora seria plataforma sem pergunta mensurável.

### Gatilho de reabertura

Reabrir somente quando houver pergunta concreta, por exemplo: comparar conversão de Leads entre duas origens/campanhas reais, com definição explícita de unidade, denominador, retenção e tratamento de identidade.

## 2. Workflow adicional de Leads

### Estado observado

O BPT2 já representa:

`novo → contatado → fechado Won/Lost`

com ownership server-side, idempotência e histórico após Pause/Archive.

A matriz donor já descartou o pipeline de cinco estados como desenho inicial e exige ação/SLA/fila real antes de adicionar estados como `NEGOCIACAO`.

### Resultado

**NÃO PROMOVER.**

Nenhuma evidência nova mostra decisão operacional impossível de representar com `ContactedAtUtc` + `Won/Lost`.

### Gatilho de reabertura

Uma fila, SLA ou ação real que exija distinguir um estado intermediário e que não possa ser derivada deterministicamente do lifecycle atual.

## 3. Compra Assistida

### Evidência donor

O donor BPT1 possui superfície e implementação de Compra Assistida; a busca no head auditado retorna múltiplos artefatos relacionados.

Porém a definição de produto do próprio donor classifica Compra Assistida como camada complementar e afirma explicitamente que o produto não deve ser, neste estágio, um produto principal de Compra Assistida. Também orienta priorizar autoridade de dados quando houver escolha entre expansão visível e fortalecimento de dados canônicos.

### Estado BPT2

Discovery, detalhe, Favorites, Saved Search, Leads, Vehicle Hub e Seller/Buyer flows já cobrem o núcleo de descoberta e contato. Comparator e enrichment permanecem bloqueados por pré-condição de dados, não por ausência de fluxo assistido humano.

### Resultado

**NÃO PROMOVER.**

A existência no donor não prova um problema incremental atual que Compra Assistida resolva melhor que discovery, detalhe, Saved Search, Comparator futuro ou contato Seller.

### Gatilho de reabertura

Evidência de uma etapa concreta da jornada em que usuários não conseguem decidir/avançar usando as capacidades atuais e em que assistência humana tenha outcome mensurável distinto.

## Conclusão

Nenhum dos candidatos atualmente não bloqueados ganhou evidência suficiente para abrir execution plan funcional:

| Candidato | Resultado |
|---|---|
| Attribution de marketing | NÃO PROMOVER |
| Estado adicional de Lead/CRM | NÃO PROMOVER |
| Compra Assistida | NÃO PROMOVER |

Portanto permanece correto manter **nenhum execution plan funcional ativo**.

Os próximos gatilhos materialmente válidos continuam externos ou de pré-condição:

- deployment/locking reproduzível para runner de Saved Search;
- enrichment técnico publicado suficiente para Comparator/Vehicle Hub enriquecido;
- corpus + baseline + métrica para discovery avançado/recomendações;
- dataset/licença/metodologia/provenance para inteligência de mercado;
- evidência operacional/provider/legal para trust/moderação avançada;
- tese/parceria comercial concreta para complementares;
- inventário externo reproduzível quando necessário para benchmark funcional.

Não abrir feature apenas para manter fluxo de implementação. Ausência de próximo slice elegível é resultado válido da auditoria.
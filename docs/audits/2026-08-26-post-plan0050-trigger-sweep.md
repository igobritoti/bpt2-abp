# Post-Plan 0050 trigger sweep

Status: **CHECKPOINT**

## Objetivo

Reavaliar os gatilhos de reabertura registrados após o fechamento do Plan 0049, sem promover capability sem precondições verificáveis.

## Resultado

### Favorite price-drop

**REPROVADO no retry funcional.**

O PR #77 reconstruiu o experimento do PR #75 a partir do `main` atual e corrigiu o erro mecânico do smoke Bash (`username: unbound variable`). O gate então exerceu o contrato funcional:

- syntax do smoke: PASS;
- Fresh Migration: PASS;
- Buyer Favorites regressivo: PASS;
- Draft decrease ignored: PASS;
- primeiro match esperado após Buyer já ter favoritado e Listing publicada cair de 195000 para 180000: FAIL;
- ledger observado: vazio.

O PR #77 foi fechado sem merge. A causa raiz não foi inferida como fato; qualquer novo retry deve começar com probe focado na persistência/UoW do detector, não com mudança ampla.

### Saved Search runner

**CONTINUA BLOQUEADO.**

ABP 10.6 possui Background Jobs com execução sequencial/parallel claim e distributed lock. Em deployment com múltiplas instâncias, a documentação exige provider de distributed lock real para garantia cross-instance. O BPT2 não possui hoje configuração/provider de distributed lock nem uso de Background Jobs/Workers. Portanto escolher job/worker + provider agora adicionaria infraestrutura/deploy decision sem requisito operacional fechado.

### Comparator / enrichment

**CONTINUA BLOQUEADO.**

Podium `main` avançou, mas nova busca por consumer read contract de enrichment técnico (power/torque/consumption/dimensions/equipment/safety) não encontrou contrato publicado suficiente para destravar o Comparador. Identity continua insuficiente para ficha comparável.

### Discovery avançado

**CONTINUA ADIADO.**

Nenhum corpus, query log, relevance baseline ou métrica de ranking/autocomplete/similaridade foi encontrado no BPT2. Não promover algoritmo sem baseline mensurável.

### Trust / moderação avançada

**CONTINUA ADIADO.**

Nenhuma evidência nova de SLA operacional, taxonomy deficit, provider de trust signal, attachment/evidence requirement ou privacy/legal contract foi encontrada.

### Inteligência de mercado

**CONTINUA BLOQUEADA.**

Nenhum dataset/licença/metodologia/provenance de market-price foi encontrado no repo.

### Carros na Web

**CONTINUA BLOQUEADO PARA INVENTÁRIO.**

Busca pública não retornou páginas utilizáveis e o acesso direto atual respondeu 502. Não calcular cobertura nem inventar denominador.

## Próximos gatilhos

Reabrir apenas quando houver pelo menos um:

1. probe focado que explique a persistência vazia do Favorite price-drop;
2. decisão operacional de deployment/locking para runner de alertas;
3. consumer enrichment contract publicado pelo Podium;
4. corpus + métrica de discovery;
5. dataset/licença/metodologia de market-price;
6. evidência operacional/provider/legal para trust/moderação;
7. inventário Carros na Web reproduzível.

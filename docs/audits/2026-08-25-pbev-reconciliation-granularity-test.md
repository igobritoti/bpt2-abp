# PBEV → BPT2 — reconciliation granularity test

Data: 2026-08-25

Status: evidência do Plan 0046; não autoriza alteração de schema por si só.

## Pergunta

A linha oficial do PBEV/Inmetro pode ser reconciliada diretamente para o agregado canônico `Vehicle` do BPT2 sem inferência adicional?

## Evidência A — PBEV/Inmetro

A tabela PBEV 2026 expõe, por linha, identidade e atributos como:

- categoria;
- marca;
- modelo;
- versão;
- motor;
- tipo de propulsão;
- transmissão;
- combustível;
- consumo;
- emissões;
- consumo energético;
- autonomia elétrica quando aplicável;
- classificação PBE.

A tabela é publicada por ciclo/ano do programa. Na tabela inspecionada, `ModelYear` não aparece como chave/coluna de identidade da linha.

O próprio Inmetro informa que o PBE possui recurso em CSV no Portal Brasileiro de Dados Abertos, portanto a fonte é candidata a ingestão estruturada; scraping de HTML/PDF não é requisito arquitetural.

## Evidência A — BPT2

`Vehicle` é identificado por:

- `BrandId`;
- `ModelId`;
- `GenerationId?`;
- `VersionId`;
- `ModelYear?`.

`VehicleVersion` é identificado por Model/Generation + nome normalizado de versão.

O `IngestionRecord` atual preserva source/external id/raw identity/confidence/provenance, mas sua reconciliação final é apenas `ReconciledVehicleId`.

## Resultado do teste

**REPROVADO para reconciliação automática direta PBEV → Vehicle por igualdade textual.**

Motivo: a fonte observada não fornece evidência suficiente para selecionar com segurança um `Vehicle` quando existem múltiplos anos-modelo para a mesma combinação marca/modelo/versão.

Isso não reprova PBEV como fonte de enrichment. Reprova apenas a hipótese de que a granularidade atual de reconciliação pode ser sempre `Vehicle`.

## Recomendação proativa

Classificação: **EDITAR / VALIDAR DESENHO**.

Testar um contrato de ingestão/enrichment em dois estágios:

1. `SourceObservation`: preservar a linha oficial, ciclo/data da fonte e seus atributos sem afirmar ainda a identidade canônica final;
2. reconciliação para o nível canônico que a evidência suporta (`VehicleVersion` ou `Vehicle`), com promoção para `Vehicle` apenas quando ano/geração forem comprováveis.

O nome `SourceObservation` é ilustrativo; não é requisito de implementação.

### Não fazer agora

- não remover `ModelYear` de `Vehicle` para acomodar a fonte;
- não copiar o nome da versão e assumir que vale para todos os anos;
- não propagar uma observação PBEV a todos os Vehicles da versão sem regra temporal comprovada;
- não alterar `IngestionRecord` antes de um experimento demonstrar a necessidade exata do novo target;
- não usar Webmotors/OLX/Carros na Web como autoridade para resolver a ambiguidade.

## Próximo experimento falsificável

Selecionar pelo menos três linhas PBEV com perfis distintos e tentar reconciliá-las contra Vehicles/Versions canônicos conhecidos:

- uma combinação com match único;
- uma versão que possa existir em mais de um ModelYear;
- uma versão cujo texto da fonte difira do nome canônico.

Registrar para cada linha:

- candidatos encontrados;
- regra usada;
- ambiguidades;
- necessidade de normalização;
- se a evidência suporta `Version` ou `Vehicle`;
- se revisão humana é necessária.

A hipótese de um target mais flexível será rejeitada se todos os casos representativos puderem ser reconciliados deterministicamente para `Vehicle` usando apenas dados oficiais já presentes na fonte e no catálogo.
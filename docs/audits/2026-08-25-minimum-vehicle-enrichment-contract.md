# Minimum Vehicle Enrichment — contrato candidato

Data: 2026-08-25

Status: recomendação de auditoria do Plan 0046; não é schema aprovado.

## Problema

O Comparador BPT2 foi reprovado para implementação imediata porque o Catalog atual contém Structure, mas não enrichment técnico suficiente. O BPT1 tinha uma matriz ampla, porém transplantar seus campos sem garantir autoridade/cobertura das fontes repetiria o erro de fazer o schema seguir o donor.

## Evidência oficial observada

A tabela PBEV/Inmetro 2026 fornece, em nível de marca/modelo/versão dentro do ciclo publicado, campos adequados para um primeiro conjunto técnico, entre eles:

- categoria;
- marca;
- modelo;
- versão;
- motor/descritivo de motorização;
- tipo de propulsão;
- transmissão;
- combustível;
- consumo urbano/rodoviário quando aplicável;
- consumo energético;
- autonomia elétrica quando aplicável;
- emissões;
- classificação PBE/eficiência.

O Inmetro mantém ciclos históricos do PBEV e informa recurso CSV no Portal Brasileiro de Dados Abertos.

A Senatran publica estatísticas agregadas de frota por marca/modelo, combustível, potência, município e outros recortes. Esses dados são úteis para inteligência de mercado agregada, mas o relatório agregado não prova potência de uma versão individual.

## Recomendação proativa

Classificação: **EDITAR/SIMPLIFICAR o primeiro enrichment**.

### Grupo A — candidato ao primeiro experimento

Somente atributos que uma fonte oficial estruturada já consegue sustentar sem adivinhação:

- propulsion type;
- fuel;
- transmission;
- engine descriptor;
- city consumption;
- highway consumption;
- energy consumption;
- electric range;
- PBE efficiency classification;
- emissions relevantes quando semanticamente comparáveis.

Cada valor deve carregar provenance/ciclo/fonte suficiente para auditoria e não deve ser promovido para `Vehicle` quando a reconciliação de ano for ambígua.

### Grupo B — adiar até fonte primária individual comprovada

- potência;
- torque;
- cilindrada estruturada se não puder ser derivada sem ambiguidade do contrato da fonte;
- peso;
- dimensões;
- porta-malas;
- tanque;
- portas;
- tração;
- 0–100 km/h;
- velocidade máxima;
- equipamentos de série/opcionais.

Esses atributos podem ser acrescentados posteriormente via documentação oficial de fabricante ou outra fonte com identidade/reconciliação suficiente. Existência no BPT1 não é evidência de fonte para BPT2.

### Grupo C — domínio separado

Não misturar no mesmo contrato técnico por conveniência:

- preço de mercado/referência;
- oferta ativa;
- tempo médio de venda;
- volume de frota;
- posição de mercado;
- opinião/editorial;
- recomendações.

Esses dados têm origem, temporalidade e semântica diferentes e devem ser avaliados em contratos próprios.

## Hipótese falsificável

> O Grupo A é suficiente para produzir uma primeira superfície de comparação tecnicamente útil e correta para Vehicles reconciliados, sem depender de ficha textual do Listing e sem inventar valores ausentes.

## Teste proposto

1. selecionar amostra com pelo menos 4 Vehicles/Versions compatíveis com PBEV;
2. reconciliar cada linha com evidência explícita e registrar ambiguidades;
3. formar matrizes 2x, 3x e 4x usando apenas Grupo A;
4. distinguir `não aplicável`, `não informado` e valor conhecido;
5. executar `only differences` sobre valores normalizados;
6. avaliar se pelo menos um conjunto de diferenças úteis permanece visível sem Grupo B;
7. reprovar o primeiro enrichment como suficiente se a matriz resultar trivial, enganosa ou exigir fallback de Listing.

## Consequência para o roadmap

- Vehicle Enrichment mínimo passa a ser o experimento anterior ao Comparador;
- o Comparador continua com cardinalidade variável escolhida pelo usuário, de 2 até 4 Vehicles no teto inicial;
- a matriz não precisa esperar todos os campos históricos do BPT1 para ser testada;
- por outro lado, nenhum campo do Grupo B entra por conveniência apenas para deixar a tela mais rica.

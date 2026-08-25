# Vehicle Enrichment — source authority audit

Data: 2026-08-25

Status: evidência para Plan 0046; não é autorização de implementação.

## Objetivo

Definir quais tipos de dados de enrichment possuem fonte externa com autoridade suficiente para um experimento BPT2, evitando selecionar atributos apenas porque existiam no BPT1 ou em portais concorrentes.

## Fontes verificadas

### INMETRO — PBE Veicular

Autoridade: fonte governamental oficial brasileira para o Programa Brasileiro de Etiquetagem veicular.

A tabela 2026 do PBE Veicular é atualizada durante o ano e reúne veículos leves autorizados a ostentar a ENCE. Em agosto de 2026, o Inmetro informou cobertura de 43 marcas e 959 modelos/versões, incluindo dados de consumo energético, emissões e eficiência.

Uso defensável no BPT2:

- consumo/eficiência energética;
- emissões quando aplicável;
- classificação de eficiência;
- identificação de modelo/versão apenas como chave de reconciliação, nunca como autoridade automática do catálogo BPT sem matching validado.

O Inmetro também informa disponibilidade da base PBE em CSV via dados.gov.br, o que torna esse domínio um bom candidato a ingestão/reconciliação reproduzível em vez de scraping visual.

### SENATRAN / Ministério dos Transportes

Autoridade: fonte governamental oficial de trânsito/frota.

Os dados públicos de frota 2026 incluem recortes por:

- ano de fabricação/modelo;
- combustível;
- potência;
- marca/modelo;
- localização.

A documentação institucional da Senatran também distingue conceitualmente marca, modelo e versão; versão diferencia veículos dentro de uma família por acabamento, portas, motorização e equipamentos.

Uso defensável no BPT2:

- apoio semântico/estatístico para marca/modelo/versão e recortes de frota;
- potencial dado agregado de mercado/frota;
- não usar agregado de frota como ficha técnica de uma versão individual sem chave/resolução apropriada.

### Fabricante oficial

Autoridade esperada: fonte primária para especificação técnica e equipamento de uma versão comercializada.

Para atributos mecânicos/dimensionais/equipamentos que não sejam cobertos por uma base governamental estruturada suficiente, a fonte preferencial de um experimento deve ser documentação oficial do fabricante por modelo/ano/versão.

A autoridade é por dado e por versão; o nome do fabricante não elimina a necessidade de provenance, data de captura e reconciliação com o Vehicle canônico.

### Portais de mercado

Webmotors, OLX, Carros na Web e similares são úteis para provar que uma superfície existe e quais atributos são apresentados ao usuário. Não devem ser autoridade canônica de ficha técnica do BPT2 por existência do portal.

## Consequência para o conjunto mínimo

Ainda não existe evidência para escolher uma ficha ampla de dezenas de campos.

Existe, porém, evidência suficiente para testar primeiro um enrichment pequeno em duas classes:

1. **Eficiência/consumo**, porque há fonte governamental estruturada e atual (PBEV);
2. **Especificações primárias de versão**, somente quando houver fonte oficial de fabricante claramente reconciliável.

## Critério de inclusão de atributo no experimento

Um atributo só entra no fixture de enrichment se satisfizer todos:

1. tem pergunta de produto associada (Vehicle Hub ou comparação);
2. possui tipo/unidade inequívocos;
3. há fonte primária/autoritativa identificável;
4. é possível reconciliar a fonte com um `Vehicle` BPT2 sem inferência textual ambígua;
5. ausência de valor pode ser representada sem virar falsamente `zero`/`não possui`;
6. o mesmo contrato pode ser consumido sem dependência Catalog → Marketplace.

## Proposta de primeiro dataset de teste

Não é schema final. É um dataset para falsificar a hipótese de enrichment mínimo.

Para 3 Vehicles com identidade canônica validada, tentar obter:

- consumo urbano;
- consumo rodoviário;
- combustível/propulsão necessário para interpretar consumo;
- classificação/eficiência do PBE quando aplicável;
- potência somente se houver fonte oficial individual da versão claramente reconciliada.

A inclusão de torque, cilindrada, dimensões, peso, porta-malas, equipamentos e segurança fica condicionada à mesma prova de fonte/reconciliação, não ao fato de o BPT1 ou a Webmotors exibirem esses campos.

## Hipótese falsificável

> Um pequeno conjunto de dados oficiais/reconciliados consegue enriquecer três Vehicles canônicos e produzir valor reutilizável no Vehicle Hub e em uma matriz comparativa, sem depender de Listing nem de fonte não rastreável.

## Critérios de reprovação

Reprovar o experimento se ocorrer qualquer um:

- fonte não diferencia versão/ano de modo suficiente;
- matching exige inferência não determinística sem revisão explícita;
- unidade/semântica do atributo não pode ser normalizada com segurança;
- conflito entre fontes não possui regra documentável;
- dado só pode ser obtido copiando conteúdo proprietário de portal;
- implementação exige acoplamento do Catalog ao Marketplace.

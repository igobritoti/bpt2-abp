# Benchmark externo — checkpoint CP3

Data: 2026-08-25

Status: evidência de mercado do Plan 0046. Portais concorrentes não são autoridade canônica de dados do BPT2.

## Webmotors — verificado

Superfícies observadas atualmente:

- Comparador público com até 4 veículos;
- seleção livre dos veículos e possibilidade de reposicioná-los;
- comparação de mais de 80 itens, incluindo mecânica, consumo, conforto e tecnologia;
- compartilhamento do resultado;
- filtros de discovery por versão, ano, preço, quilometragem e localização;
- filtro `Abaixo da Fipe`;
- filtro `Vistoriado`;
- referência FIPE + referência própria de mercado;
- anúncios com planos de maior visibilidade/turbinar;
- Favorites e histórico de buscas recentes.

Leitura BPT2:

- reforça teto inicial de 4 no Comparador, sem transformar 4 em cardinalidade fixa;
- reforça que riqueza técnica é necessária para o Comparador ser útil;
- reforça pesquisas separadas de preço de mercado, trust signals e promotions;
- não autoriza copiar dados, ranking ou modelo comercial.

## OLX — verificado

Superfícies observadas atualmente:

- Favorites;
- buscas salvas;
- alertas para novos anúncios e mudança de preço;
- localização por CEP/estado/cidade/bairro;
- ranking `Mais relevantes` e outras ordenações;
- histórico veicular por parceiro com dados derivados de fontes oficiais;
- selo `Vistoriado` derivado de vistoria presencial por parceiro credenciado;
- destaques/patrocinados com duração e retorno ao topo.

Leitura BPT2:

- Saved Search / alerts sobe de ideia plausível para candidata forte de teste;
- trust signal deve ser separado de moderação e de promotion;
- localização avançada continua candidata, mas requer autoridade geográfica própria antes de radius/CEP virar requisito;
- completude pode ser testada primeiro como ferramenta Seller antes de influenciar ranking público.

## Carros na Web — não verificado neste checkpoint

A superfície direta não ficou acessível de forma reproduzível durante esta auditoria. Resultado: **sem conclusão atual**.

Não interpretar falha de acesso como ausência de feature. Conhecimento histórico do portal não será usado como evidência corrente.

## iCarros — substituto verificável para ampliar benchmark

Superfícies observadas:

- discovery com localização por cidade/CEP e raio;
- preço, condição, quilometragem, ano, marca/modelo e tipo de vendedor;
- filtros adicionais históricos como câmbio/combustível/cor;
- catálogo 0km com ficha técnica rica por versão/ano, incluindo potência, torque, consumo, dimensões e outros atributos;
- financiamento como camada complementar.

Leitura BPT2:

- reforça valor de geo/radius e ficha técnica rica como superfícies maduras de mercado;
- não torna iCarros fonte canônica de specs;
- potência/torque/dimensões permanecem fora do primeiro enrichment PBEV até fonte primária adequada ser definida;
- financiamento permanece complementar e adiado.

## Convergências de mercado observadas

| Capability | Webmotors | OLX | iCarros | Leitura BPT2 |
|---|---|---|---|---|
| filtros por localização | sim | sim | sim | candidato forte; BPT2 hoje só City/StateCode |
| radius/proximidade | não usado como autoridade neste checkpoint | proximidade/localização | sim | VALIDAR, não implementar sem geo authority |
| favoritos | sim | sim | não necessário para conclusão | já existe BPT2 |
| buscas salvas/alertas | buscas recentes/favorites; não usado como prova equivalente | sim, explícito | não comprovado | candidata forte por OLX + fit BPT2 |
| comparador técnico | sim, até 4 | não usado como prova | ficha técnica rica, não comparador comprovado | candidato forte após enrichment |
| ficha técnica rica | sim | não usada como prova | sim | mercado valoriza conteúdo técnico; fonte deve ser própria/primária |
| preço/contexto de mercado | FIPE + própria | não usado como prova | preço/ofertas | pesquisar; dependente de dados/contrato |
| trust/vistoria | filtro Vistoriado | histórico + Vistoriado | não usado como prova | nova linha de pesquisa |
| promotion/boost | sim | sim | super ofertas | candidato comercial, medir separadamente |
| financiamento | sim | não usado aqui | sim | complementar; continua adiado |

## Conclusão CP3

O benchmark externo está **suficiente para orientar os testes atuais**, com Webmotors e OLX diretamente verificados e iCarros usado como terceiro portal verificável diante da indisponibilidade reproduzível do Carros na Web.

Isso não fecha decisões de implementação. Fecha apenas a etapa de observação comparativa necessária para CP3, mantendo limitações explícitas.
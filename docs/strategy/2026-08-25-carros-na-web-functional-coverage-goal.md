# Meta estratégica — cobertura funcional Carros na Web

Data: 2026-08-25

Status: **META DE PRODUTO; inventário ainda não concluído**

## Intenção

O Bom Pra Ti deve mirar cobertura de **pelo menos 90% das capacidades funcionais úteis** observáveis no `carrosnaweb.com.br`, com ambição de chegar a **100%** quando cada capacidade restante for tecnicamente, juridicamente, economicamente e operacionalmente justificável.

A porcentagem mede **capabilities auditadas**, não páginas, URLs, componentes visuais ou cópia literal de implementação.

## Regra de interpretação

Esta meta NÃO significa:

- copiar código, conteúdo protegido, textos, layout ou identidade visual;
- implementar toda função encontrada sem validação;
- copiar dados cuja licença, provenance ou autoridade não estejam comprovadas;
- reproduzir arquitetura ou escolhas técnicas do portal;
- considerar uma função automaticamente boa só porque existe no benchmark.

Esta meta significa:

1. construir um inventário funcional verificável do portal;
2. classificar cada capability como `JÁ EXISTE`, `ADICIONAR`, `EDITAR/SIMPLIFICAR`, `SUBSTITUIR`, `ADIAR` ou `EXCLUIR`;
3. medir cobertura do Bom Pra Ti contra o inventário elegível;
4. estimar custo/risco/benefício antes de promover implementação;
5. registrar explicitamente por que qualquer capability elegível ficou de fora.

## Denominador da cobertura

O denominador deve conter somente capabilities que sejam:

- observadas/reproduzidas no benchmark atual;
- semanticamente distintas;
- aplicáveis ao mercado/produto Bom Pra Ti;
- reproduzíveis sem violar propriedade intelectual/licença/privacidade;
- tecnicamente possíveis com fonte de dados e operação identificáveis.

Capabilities puramente editoriais, conteúdo proprietário, dados sem direito de uso ou funções que contrariem a estratégia do produto podem ser classificadas como `EXCLUIR JUSTIFICADO` e não devem inflar artificialmente a dívida funcional.

## Métricas

Para cada capability registrar:

- existência/estado no BPT2;
- valor para Buyer/Seller/Admin/SEO/monetização;
- dependências de dados;
- dependências de provider/licença;
- complexidade de implementação;
- custo operacional recorrente;
- risco de manutenção;
- risco legal/privacy;
- necessidade de moderação/observabilidade;
- teste falsificável de valor/correção;
- decisão atual.

Métricas agregadas:

- `coverage_eligible = capabilities_equivalentes_ou_melhores / capabilities_elegiveis`;
- `coverage_total_observed = capabilities_equivalentes_ou_melhores / capabilities_observadas`;
- custo estimado por bloco funcional;
- quantidade de capabilities bloqueadas por dados/provider/licença;
- quantidade excluída justificadamente.

## Regra 90% / 100%

- **90%** é o objetivo mínimo estratégico de cobertura das capabilities elegíveis.
- **100%** é a ambição, não obrigação cega.
- O Bom Pra Ti pode substituir uma capability por solução diferente e contar como cobertura quando resolver o mesmo problema de forma equivalente ou superior e isso estiver testado.
- Uma capability não deve ser implementada apenas para aumentar percentual se custo/risco superar valor demonstrável.

## Evidência atual

No checkpoint de 25/08/2026, tentativas de pesquisa pública do Carros na Web não retornaram uma superfície suficientemente verificável para construir inventário confiável. Portanto nenhuma lista histórica/memorizada deve ser tratada como inventário atual.

A meta fica congelada agora; o inventário será executado como trilha própria quando houver navegação/superfícies reproduzíveis suficientes.

## Relação com BPT1 e Podium 7

- BPT1 continua donor de comportamentos, não chassis.
- Carros na Web é benchmark de **cobertura funcional**, não donor técnico.
- Podium 7 é knowledge producer/feed do catálogo e pode satisfazer dependências de dados de algumas futuras capabilities, mas não transforma automaticamente essas capabilities em requisito.

## Critério para abrir implementação

Nenhuma capability Carros na Web entra em código apenas por estar no inventário. Ela deve atravessar:

`inventário → gap BPT2 → dependências → custo/risco → teste/hipótese → decisão → execution plan`

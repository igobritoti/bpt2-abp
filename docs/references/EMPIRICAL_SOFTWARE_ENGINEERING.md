# Referências — pesquisa empírica e reprodutibilidade em engenharia de software

Este documento registra a base metodológica externa usada para calibrar recomendações técnicas, benchmarks, experimentos e alegações empíricas no BPT2. Ele **não** substitui `ENGINEERING.md` nem `QUALITY.md`; as regras operacionais canônicas vivem nesses arquivos.

## ACM SIGSOFT Empirical Standards for Software Engineering

Fonte oficial: https://www2.sigsoft.org/EmpiricalStandards/

Repositório dos standards: https://github.com/acmsigsoft/EmpiricalStandards

Os ACM SIGSOFT Empirical Standards são standards de evidência para condução e relato de pesquisa em engenharia de software. Eles são específicos por método e incluem, entre outros, standards para engineering research, benchmarking, experimentos, data science, repository mining e replication.

Aplicação ao BPT2:

- escolher o método de avaliação conforme a pergunta, em vez de aplicar um checklist genérico a qualquer decisão;
- declarar objetivo/pergunta ou hipótese antes de interpretar resultados;
- explicitar desenho, objetos estudados, critérios de inclusão/exclusão, variáveis/métricas e procedimento;
- distinguir observação direta de inferência e limitar a conclusão ao que o estudo efetivamente mede;
- discutir limitações e ameaças à validade relevantes para o desenho usado;
- evitar generalizar uma observação local, sintética ou de amostra estreita para produção sem justificativa de representatividade.

Uso no protocolo: uma sugestão técnica apresentada como superior, necessária, mais simples, mais rápida, mais segura ou mais sustentável precisa de evidência compatível com a natureza da afirmação. Quando a evidência ainda não existe, a saída admissível é uma hipótese testável ou proposta de experimento, não uma recomendação factual.

## ACM Artifact Review and Badging — reprodutibilidade

Fonte oficial: https://www.acm.org/publications/policies/artifact-review-and-badging-current

A política de Artifact Review and Badging da ACM separa propriedades como disponibilidade, funcionalidade, reusabilidade e resultados reproduzidos/replicados. O ponto relevante para o BPT2 é que disponibilizar código ou descrever um procedimento não equivale a reproduzir um resultado.

Aplicação ao BPT2:

- preservar artefatos necessários para repetir a avaliação: código, comandos, configuração, versões, dados/fixtures permitidos e parâmetros materiais;
- registrar resultado bruto suficiente para rechecagem quando uma métrica sustentar decisão;
- não classificar uma conclusão como reproduzida apenas porque o código compila ou o artefato está disponível;
- preferir automação e ambientes declarativos quando reduzirem graus de liberdade ocultos da execução;
- distinguir reprodução do mesmo procedimento/artefato de replicação independente com novo desenho ou implementação.

## Regra de interpretação

Os standards metodológicos não transformam automaticamente qualquer benchmark em requisito de produto. Eles qualificam **como** uma afirmação empírica deve ser produzida e relatada.

Para recomendações de engenharia no BPT2:

1. identificar a afirmação que está sendo feita;
2. escolher evidência/método capaz de medir essa afirmação;
3. predefinir métricas e regra de decisão quando sua escolha puder ser influenciada pelo resultado observado;
4. executar ou apontar evidência reproduzível suficiente;
5. registrar limitações e ameaças à validade proporcionais ao risco;
6. classificar como hipótese/inferência tudo que exceder a evidência observada.

A prioridade canônica de fontes continua definida em `ENGINEERING.md`. Literatura, standards e guias metodológicos calibram o desenho da prova; a decisão sobre o BPT2 continua exigindo evidência local quando a alegação depende do comportamento ou workload do próprio sistema.

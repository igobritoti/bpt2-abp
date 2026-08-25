# Referências — avaliação e migração baseada em evidência

Este documento registra fontes externas usadas para calibrar o protocolo BPT1 → BPT2. Ele **não** substitui `ENGINEERING.md` nem `QUALITY.md`; as regras operacionais canônicas vivem nesses arquivos.

## ISO/IEC/IEEE 42030:2019 — Architecture evaluation framework

Fonte oficial: https://www.iso.org/standard/73436.html

Aplicação ao BPT2:

- avaliação arquitetural deve ser organizada e registrada;
- deve verificar se a arquitetura atende preocupações dos stakeholders e ao propósito pretendido;
- deve identificar riscos e oportunidades;
- deve apoiar decisão, não apenas descrever uma solução.

Uso no protocolo: uma capacidade do donor não é promovida só porque existe. A alternativa precisa ser avaliada contra necessidades, riscos, qualidade e propósito do BPT2.

## Microsoft Azure Well-Architected — Architecture Decision Records

Fonte oficial: https://learn.microsoft.com/en-us/azure/well-architected/architect-role/architecture-decision-record

Aplicação ao BPT2:

- decisões materiais registram problema/contexto, opções consideradas, resultado, trade-offs, consequências e confiança;
- decisões difíceis de reverter ou que alteram atributos importantes de qualidade devem ser rastreáveis;
- uma decisão alterada deve ser superada por novo registro em vez de apagar o histórico.

Uso no protocolo: transplantes que alterem arquitetura ou atributos de qualidade relevantes exigem ADR; feature simples e reversível não deve gerar ADR por ritual.

## ISO/IEC/IEEE CD 29119-14 — Data migration testing

Fonte oficial: https://www.iso.org/standard/88837.html

Status consultado em 2026-08-25: **Committee Draft**, não norma internacional publicada. Portanto é referência técnica de baixa autoridade normativa em relação a standards publicados, e não deve ser citada como requisito obrigatório.

O draft descreve explicitamente uma abordagem baseada em risco para teste de migração de dados e relaciona os riscos de migração com níveis, tipos, práticas e técnicas de teste.

Uso no protocolo: quando um slice realmente migrar dados, identificar risco de perda, duplicação, transformação semântica, referência e recuperação antes de escolher os testes. O BPT2 adota o princípio por coerência com sua política já existente de validação proporcional ao risco, não porque o Committee Draft imponha obrigação normativa.

## Regra de interpretação

Fontes externas informam a decisão, mas não substituem evidência local. A prioridade canônica continua:

`teste/código reproduzível → documentação oficial atual → standard publicado → evidência externa confiável → inferência → preferência`

Se uma referência estiver em draft, desatualizada, tratar outro contexto ou não medir o risco em questão, registrar essa limitação explicitamente.

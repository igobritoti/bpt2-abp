# Documentação BPT2 — mapa e fontes de verdade

Este diretório é a base de conhecimento versionada do projeto. O objetivo é permitir que uma pessoa ou agente novo entenda **o que estamos construindo, por que as decisões existem, o que ainda está aberto e como verificar mudanças**, sem depender de histórico de chat.

## Mapa

| Documento | Papel canônico |
|---|---|
| `../AGENTS.md` | mapa operacional curto para agentes e colaboradores |
| `PRODUCT.md` | produto, escopo, não objetivos e comportamento esperado |
| `../ARCHITECTURE.md` | mapa arquitetural atual e ownership dos módulos |
| `MDV.md` | estado de decisões e evidências |
| `adr/` | decisões arquiteturais aceitas/superseded e suas razões |
| `ENGINEERING.md` | política de evidência, mudança e autonomia |
| `SECURITY.md` | threat model e guardrails de segurança |
| `QUALITY.md` | definição de pronto e checks mínimos por risco |
| `PLANS.md` | política para execution plans |
| `exec-plans/active/` | planos complexos em andamento |
| `exec-plans/completed/` | histórico de planos concluídos |
| `references/` | fontes externas oficiais usadas para fundamentar o modo de trabalho |

## O que é fonte de verdade para cada coisa

- **Intenção de produto:** `PRODUCT.md` e specs futuras.
- **Arquitetura atual:** `ARCHITECTURE.md` + ADRs aceitos.
- **Estado da decisão:** `MDV.md`.
- **Comportamento executável:** código + testes + CI.
- **Trabalho em andamento:** execution plan ativo.
- **Regras para agentes:** `AGENTS.md`, que deve apontar para documentos canônicos em vez de repetir tudo.

Documentação não deve fingir que substitui o comportamento executável. Se código/testes e docs divergirem, isso é um defeito de consistência: não assumir automaticamente que um lado está certo; resolver com evidência e atualizar a fonte canônica.

## Política de mudança

1. Não criar documento novo se um documento canônico existente já comporta o assunto.
2. Evitar regras duplicadas; usar links.
3. Toda decisão arquitetural congelada deve aparecer na MDV e, quando material, em ADR.
4. Toda mudança que torne documentação falsa deve atualizar a documentação no mesmo PR.
5. Planos complexos são artefatos versionados; decisões tomadas durante execução devem ficar registradas.
6. Checks mecânicos têm preferência sobre lembretes em prosa quando uma regra puder ser automatizada.

## Estado atual

A fundação arquitetural e o Gate 01 estão decididos. O trabalho ativo é transformar a fundação validada em produto funcional, conforme `exec-plans/active/0001-product-baseline.md`.

## Fundamentação do modelo documental

O layout segue, de forma adaptada e não literal, aprendizados publicados pela OpenAI sobre engenharia com Codex: repositório como sistema de registro, `AGENTS.md` curto como mapa, documentação estruturada, progressive disclosure, planos versionados e invariantes reforçados mecanicamente. A rastreabilidade das fontes e o que foi ou não adotado está em `references/OPENAI_ENGINEERING_GUIDANCE.md`.

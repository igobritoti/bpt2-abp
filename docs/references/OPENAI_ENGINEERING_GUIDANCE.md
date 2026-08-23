# OpenAI engineering guidance — fontes e adoção no BPT2

Data de revisão: **2026-08-22**.

Este documento existe para evitar dois erros opostos:

1. decidir por gosto pessoal quando existe orientação/evidência disponível;
2. transformar um exemplo ou prática interna publicada pela OpenAI em requisito universal que a própria fonte não afirma.

Abaixo, cada fonte é registrada com **o que ela sustenta** e **o que o BPT2 decidiu adotar**.

## 1. Harness engineering: leveraging Codex in an agent-first world

Fonte oficial:
https://openai.com/index/harness-engineering/

Publicado pela OpenAI em 2026-02-11.

### Evidência relevante

A OpenAI relata, a partir de um produto novo construído com Codex, que:

- progresso inicial foi prejudicado por ambiente subespecificado;
- o repositório passou a ser sistema de registro do conhecimento acessível ao agente;
- um `AGENTS.md` monolítico grande falhou; o time passou a usar um `AGENTS.md` curto como mapa para documentação estruturada;
- planos complexos passaram a ser artefatos versionados;
- regras importantes passaram a ser reforçadas por linters/testes estruturais, não só por prosa;
- progressive disclosure foi preferido a despejar todo contexto de uma vez.

### Adoção BPT2

**ADOTADO como princípio:** repo-local/versionado como fonte de contexto; `AGENTS.md` curto; docs estruturados; plans versionados; invariantes mecânicos quando possível.

### Não é requisito BPT2 por causa desta fonte

- exatamente 100 linhas de `AGENTS.md`;
- exatamente os mesmos nomes/pastas usados no exemplo da OpenAI;
- código 100% escrito por agente;
- mesma filosofia de merge/throughput da experiência interna da OpenAI.

Esses itens são detalhes do experimento publicado, não requisitos universais demonstrados para o BPT2.

## 2. Unrolling the Codex agent loop

Fonte oficial:
https://openai.com/index/unrolling-the-codex-agent-loop/

Publicado pela OpenAI em 2026-01-23.

### Evidência relevante

A descrição do Codex documenta que:

- instruções de projeto podem ser agregadas de `AGENTS.md`/`AGENTS.override.md` ao longo da árvore;
- instruções mais específicas podem ser aplicadas em diretórios mais profundos;
- o sandbox descrito para a ferramenta de shell não deve ser presumido como proteção automática de ferramentas externas/MCP;
- contexto cresce ao longo da sessão, portanto contexto estável e bem organizado importa para eficiência e legibilidade.

### Adoção BPT2

**ADOTADO:** `AGENTS.md` raiz como mapa; possibilidade de `AGENTS.md` específico apenas quando uma subárvore realmente precisar de regras próprias; não assumir sandbox de shell como proteção de conectores/MCP.

## 3. OpenAI model guidance — define autonomy and approval boundaries

Fonte oficial:
https://developers.openai.com/api/docs/guides/latest-model

Conteúdo revisado em 2026-08-22.

### Evidência relevante

A orientação atual recomenda explicitar o nível de autonomia autorizado:

- tarefas de responder/revisar/diagnosticar/planejar não implicam implementação;
- tarefas de mudar/construir/corrigir podem realizar mudanças em escopo e validação não destrutiva;
- ações externas, destrutivas, custosas ou que ampliem materialmente o escopo devem parar para confirmação.

### Adoção BPT2

**ADOTADO:** política de autonomia em `AGENTS.md` e `ENGINEERING.md`.

## 4. A practical guide to building agents — guardrails

Fonte oficial:
https://openai.com/business/guides-and-resources/a-practical-guide-to-building-ai-agents/

### Evidência relevante

A OpenAI recomenda:

- defesa em profundidade com múltiplos guardrails especializados;
- combinar guardrails com autenticação/autorização, acesso estrito e segurança de software tradicional;
- avaliar risco das ferramentas por fatores como leitura/escrita, reversibilidade, permissões e impacto financeiro;
- human intervention para ações de alto risco e quando thresholds de falha são excedidos.

### Adoção BPT2

**ADOTADO como princípio de segurança:** least privilege, camadas, testes negativos, confirmação de ações de alto risco e segurança tradicional além de prompts.

## 5. Prompt injection guidance

Fontes oficiais:
https://openai.com/safety/prompt-injections/
https://openai.com/index/designing-agents-to-resist-prompt-injection/

### Evidência relevante

A OpenAI trata prompt injection como risco de engenharia social em conteúdo de terceiros e recomenda limitar acesso, manter o usuário no controle, usar instruções explícitas e impedir ações/transmissões sensíveis silenciosas.

### Adoção BPT2

**ADOTADO:** conteúdo externo é dado não confiável; instrução embutida não amplia escopo; escrita/transmissão externa consequente deve corresponder à intenção explícita do usuário.

## 6. Using skills

Fonte oficial:
https://openai.com/academy/skills/

Publicado pela OpenAI em 2026-04-10.

### Evidência relevante

Skills são descritas como workflows reutilizáveis para tarefas repetíveis, normalmente com `SKILL.md`, entradas, passos, formato de saída e checks finais.

### Decisão BPT2 atual

**NÃO CRIAR Skill ainda.** O modo de trabalho do projeto está sendo estabilizado agora. Regra geral, arquitetura e segurança pertencem aos documentos canônicos/checks, não a uma Skill genérica.

Criar Skill futura somente quando houver um workflow repetível já claro — candidatos possíveis, se a repetição aparecer: revisão de evidência/ADR ou checklist de PR BPT2.

## Regra de uso destas fontes

- Estas fontes fundamentam o **harness de engenharia e o comportamento do agente**, não decidem automaticamente arquitetura de negócio/infra do BPT2.
- Framework ABP, PostgreSQL, EF Core e decisões de domínio continuam exigindo suas próprias fontes oficiais/testes e registro na MDV/ADRs.
- Se a OpenAI atualizar material relevante, esta referência deve ser revisada antes de tratar orientação antiga como atual.

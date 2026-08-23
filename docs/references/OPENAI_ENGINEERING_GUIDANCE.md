# OpenAI guidance adopted by the BPT2 harness

Reviewed: **2026-08-23**

Este documento registra a base normativa externa do harness. Ele não decide arquitetura de negócio do BPT2.

## Fontes oficiais atuais

1. **Harness engineering: leveraging Codex in an agent-first world**  
   https://openai.com/index/harness-engineering/  
   Adotado: repositório como system of record; `AGENTS.md` como mapa curto; progressive disclosure; planos/dívida versionados; invariantes mecânicos; agentes fechando o loop de implementação/CI.

2. **Custom instructions with AGENTS.md**  
   https://developers.openai.com/codex/guides/agents-md  
   Adotado: instruções de projeto são descobertas por árvore e escopo; regras especializadas devem ficar próximas da subárvore somente quando necessário; manter instruções concisas e verificações de formatação/estrutura no CI.

3. **Model guidance — autonomy and approval boundaries**  
   https://developers.openai.com/api/docs/guides/latest-model  
   Adotado: política compacta que distingue leitura/análise de mudança; mudanças em escopo podem prosseguir com validação; ações destrutivas/custosas/externas de maior risco exigem approval. O BPT2 explicita em `ENGINEERING.md` que GitHub de desenvolvimento é parte do fluxo autorizado para tarefas de implementação.

4. **How OpenAI uses Codex**  
   https://openai.com/business/guides-and-resources/how-openai-uses-codex/  
   Adotado: prompts de implementação outcome-first, semelhantes a GitHub Issues, com contexto específico quando útil em vez de repetir o manual do repositório.

5. **Build skills**  
   https://developers.openai.com/codex/skills  
   Adotado: skills usam progressive disclosure e devem representar workflows reutilizáveis. O BPT2 não cria uma skill genérica de “seguir as regras do projeto”, porque isso duplicaria `AGENTS.md`/docs; criar skill somente para workflow específico e estável.

6. **Codex security / agent approvals**  
   https://developers.openai.com/codex/security  
   Adotado em `SECURITY.md`: least privilege, separação de ações de alto risco e tratamento explícito de conteúdo externo.

## O que não é copiado literalmente

- nomes/pastas exatos do exemplo interno da OpenAI;
- número exato de linhas do `AGENTS.md`;
- filosofia de merge de outro repositório;
- exigência de código 100% agent-generated;
- qualquer decisão de ABP/PostgreSQL/domínio sem evidência própria.

## Freshness

`python3 scripts/check-harness.py` exige que esta revisão não fique indefinidamente stale. Quando a janela expirar, revalidar as fontes oficiais antes de apenas trocar a data.

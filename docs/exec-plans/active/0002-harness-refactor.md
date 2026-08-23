# Execution Plan 0002 — Harness documental agent-first

Status: **ATIVO**

## Objetivo

Alinhar o harness do BPT2 ao padrão oficial atual da OpenAI para Codex/harness engineering, reduzindo contexto recorrente e aumentando autonomia verificável.

## Contexto congelado

- O repositório é o system of record.
- Decisões de produto/arquitetura já registradas não serão reabertas por esta missão.
- Nenhum login no Codex nem chamada real a modelo faz parte desta missão.

## Escopo

- tornar `AGENTS.md` um mapa curto;
- criar estado corrente curto;
- definir uma fonte canônica por política recorrente;
- formalizar loop autônomo, approval boundary, Git/PR/CI/merge, done e stopping rules;
- versionar dívida técnica e planos concluídos;
- gerar fatos computáveis;
- adicionar gate mecânico do knowledge base;
- validar o repositório usando o novo caminho de navegação.

## Fora de escopo

- mudar arquitetura de produto;
- criar infra de runtime;
- chamar Codex/modelo real;
- criar skill genérica que duplique política canônica.

## Critérios de aceite

1. `AGENTS.md` é mapa curto e aponta para o estado corrente.
2. `docs/` declara fonte canônica única por assunto.
3. `CURRENT-WORK` não acumula histórico/counters.
4. autonomia, Git, done, evidence e stopping rules são descobríveis sem prompt longo.
5. estrutura, links, freshness, planos e fatos gerados têm enforcement mecânico.
6. o gate novo passa e os gates existentes relevantes não regredem.
7. PR/CI é conduzido até merge ou blocker externo real.

## Checkpoints

- [x] Auditoria documental e normativa.
- [x] Refatorar knowledge base.
- [x] Adicionar tooling e CI.
- [ ] Executar self-review/validação.
- [ ] Integrar e mover este plano para `completed/`.

## Decisões abertas

Nenhuma decisão arquitetural de produto. Ajustes do harness devem preferir a estrutura existente a copiar literalmente a árvore publicada pela OpenAI.

## Progress log

- 2026-08-23: auditados AGENTS, docs canônicos, ADRs, scripts, workflows e fontes oficiais atuais da OpenAI.
- 2026-08-23: knowledge base refatorada; gerador de fatos e harness checker adicionados; próximo passo é validação no CI.

## Decision log

- Manter PRODUCT/ARCHITECTURE/MDV/ADR/ENGINEERING/SECURITY/QUALITY/PLANS como fontes canônicas existentes.
- Não criar repo skill nesta missão: o fluxo geral pertence ao harness e aos scripts; skill só será criada quando houver workflow específico, repetível e estável que não duplique política.

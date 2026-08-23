# Execution Plan 0002 — Harness documental agent-first

Status: **CONCLUÍDO**

## Objetivo

Alinhar o harness do BPT2 ao padrão oficial atual da OpenAI para Codex/harness engineering, reduzindo contexto recorrente e aumentando autonomia verificável.

## Contexto congelado

- O repositório é o system of record.
- Decisões de produto/arquitetura já registradas não foram reabertas por esta missão.
- Nenhum login no Codex nem chamada real a modelo fez parte desta missão.

## Escopo executado

- `AGENTS.md` reduzido a mapa curto com progressive disclosure.
- `docs/agent/CURRENT-WORK.md` criado como snapshot corrente sem histórico/counters.
- Fonte canônica única por assunto explicitada em `docs/README.md`.
- Autonomia, approval boundary, task contract, Git/PR/CI/merge e stopping rules centralizados em `ENGINEERING.md`.
- Testes, evidência executada e Definition of Done centralizados em `QUALITY.md`.
- Dívida técnica e planos concluídos ganharam artefatos versionados próprios.
- Fatos computáveis passaram a ser gerados por tooling.
- Estrutura, links, freshness, planos e facts receberam enforcement mecânico no CI.

## Fora de escopo preservado

- nenhuma mudança de arquitetura de produto;
- nenhuma infra de runtime nova;
- nenhum login/chamada real ao Codex/modelo;
- nenhuma skill genérica duplicando política do harness.

## Critérios de aceite

1. [x] `AGENTS.md` é mapa curto e aponta para o estado corrente.
2. [x] `docs/` declara fonte canônica única por assunto.
3. [x] `CURRENT-WORK` não acumula histórico/counters.
4. [x] autonomia, Git, done, evidence e stopping rules são descobríveis sem prompt longo.
5. [x] estrutura, links, freshness, planos e fatos gerados têm enforcement mecânico.
6. [x] o gate novo passa e os gates existentes relevantes não regrediram.
7. [x] PR/CI foi conduzido até estado integrável; merge segue a política/permissão do GitHub.

## Checkpoints

- [x] Auditoria documental e normativa.
- [x] Refatorar knowledge base.
- [x] Adicionar tooling e CI.
- [x] Executar self-review/validação.
- [x] Encerrar o plano como histórico.

## Decisões abertas

Nenhuma decisão arquitetural de produto criada por este plano.

## Progress log

- 2026-08-23: auditados AGENTS, docs canônicos, ADRs, scripts, workflows e fontes oficiais atuais da OpenAI.
- 2026-08-23: knowledge base refatorada; gerador de fatos e harness checker adicionados.
- 2026-08-23: o Harness Gate detectou duas transcrições semanticamente incorretas da versão ABP durante desenvolvimento; o gerador foi corrigido em vez de o gate ser relaxado.
- 2026-08-23: self-review removeu duplicação residual da approval policy em `SECURITY.md`.

## Decision log

- PRODUCT/ARCHITECTURE/MDV/ADR/ENGINEERING/SECURITY/QUALITY/PLANS permanecem as fontes canônicas existentes, com responsabilidades explicitadas.
- Não criar repo skill nesta missão: workflow geral pertence ao harness/scripts; skill futura só para fluxo específico, repetível e estável que não duplique política.
- Readiness e counters de CI não são mantidos manualmente em estado corrente; são consultados/derivados das fontes executáveis.

## Resultado e evidência final

A navegação mínima `AGENTS.md → CURRENT-WORK → fonte especializada` foi usada para selecionar e executar validação real do repositório. No head validado antes deste fechamento, passaram:

- BPT2 Harness Gate;
- BPT2 Architecture Gate;
- BPT2 Host Gate;
- BPT2 Fresh Migration Gate;
- BPT2 Gate 01;
- BPT2 Product API Gate.

O fechamento deste plano é documental e deve manter os mesmos gates verdes antes da integração.

# BPT2 knowledge base

`docs/` é o **system of record** versionado do projeto. O objetivo é progressive disclosure: comece por `../AGENTS.md` e `agent/CURRENT-WORK.md`, depois abra somente a fonte canônica necessária à tarefa.

## Fonte canônica por assunto

| Assunto | Fonte de verdade |
|---|---|
| Estado corrente e próximo acceptance target | [`agent/CURRENT-WORK.md`](agent/CURRENT-WORK.md) |
| Desenvolvimento local e bootstrap reproduzível | [`LOCAL-DEVELOPMENT.md`](LOCAL-DEVELOPMENT.md) |
| Produto, escopo e não objetivos | [`PRODUCT.md`](PRODUCT.md) |
| Arquitetura e ownership de módulos | [`../ARCHITECTURE.md`](../ARCHITECTURE.md) |
| Estado formal de decisões/evidência | [`MDV.md`](MDV.md) |
| Razões de decisões arquiteturais | [`adr/`](adr/) |
| Evidência, autonomia, task contract e Git/GitHub | [`ENGINEERING.md`](ENGINEERING.md) |
| Testes, evidência executada e Definition of Done | [`QUALITY.md`](QUALITY.md) |
| Segurança e ações de alto risco | [`SECURITY.md`](SECURITY.md) |
| Política de execution plans | [`PLANS.md`](PLANS.md) |
| Planos ativos | [`exec-plans/active/`](exec-plans/active/) |
| Planos concluídos | [`exec-plans/completed/`](exec-plans/completed/) |
| Dívida técnica | [`exec-plans/tech-debt-tracker.md`](exec-plans/tech-debt-tracker.md) |
| Fatos derivados do repositório | [`generated/repository-facts.md`](generated/repository-facts.md) |
| Fontes normativas externas | [`references/`](references/) |

## Estrutura

```text
docs/
├── agent/
│   └── CURRENT-WORK.md
├── adr/
├── exec-plans/
│   ├── active/
│   ├── completed/
│   └── tech-debt-tracker.md
├── generated/
│   └── repository-facts.md
├── references/
├── ENGINEERING.md
├── LOCAL-DEVELOPMENT.md
├── MDV.md
├── PLANS.md
├── PRODUCT.md
├── QUALITY.md
└── SECURITY.md
```

Não crie um novo documento quando uma fonte canônica existente comportar o assunto. História de execução pertence a planos concluídos/ADRs; estado corrente pertence apenas a `agent/CURRENT-WORK.md`; fatos computáveis pertencem a `generated/` e não são transcritos manualmente.

## Atualização e freshness

- Mudou produto: atualize `PRODUCT.md`.
- Mudou arquitetura: atualize `ARCHITECTURE.md`, `MDV.md` e ADR quando material.
- Mudou bootstrap, ferramenta, porta ou procedimento local: atualize `LOCAL-DEVELOPMENT.md` no mesmo PR.
- Mudou processo recorrente: altere a fonte canônica correspondente, não `AGENTS.md` e vários docs ao mesmo tempo.
- Mudou estado de trabalho: substitua o snapshot em `agent/CURRENT-WORK.md`; não acrescente histórico.
- Mudou estrutura que alimenta fatos derivados: rode `python3 scripts/generate-repo-facts.py --write`.
- Antes de integrar mudança de harness/docs: rode `python3 scripts/check-harness.py`.

O CI valida estrutura, links locais, freshness dos snapshots, forma dos planos e sincronização dos fatos gerados.

# BPT2 / Bom Pra Ti

Repositório oficial da reconstrução BPT2 baseada em ABP.

## Baseline

- .NET 10
- ABP 10.6 `app-nolayers`
- Entity Framework Core
- PostgreSQL
- modular monolith com boundaries Contracts/implementation
- frontend público desacoplado
- sem Redis, broker, search externo, Kubernetes ou microservices por padrão

## Comece aqui

- `AGENTS.md` — mapa operacional para agentes/colaboradores.
- `docs/README.md` — índice e fontes de verdade.
- `docs/PRODUCT.md` — produto, escopo e não objetivos.
- `ARCHITECTURE.md` — arquitetura e ownership dos módulos.
- `docs/MDV.md` — decisões e evidências.
- `docs/adr/` — ADRs.
- `docs/ENGINEERING.md` — política de decisão e execução.
- `docs/SECURITY.md` — guardrails e threat model.
- `docs/QUALITY.md` — validação proporcional ao risco.
- `docs/PLANS.md` — política de execution plans.

Plano ativo: `docs/exec-plans/active/0001-product-baseline.md`.

## Regra epistemológica

Uma decisão arquitetural só é congelada quando a necessidade do BPT e evidência suficiente a sustentam. Documentação oficial/código upstream, standards aplicáveis e testes executados têm precedência sobre inferência e preferência. `PASSA` não significa automaticamente `DECIDIDO`.

## Modo de trabalho

O repositório é a fonte de contexto persistente do projeto. Decisões que existirem apenas em chat não são consideradas suficientemente preservadas até serem registradas na documentação canônica correspondente.

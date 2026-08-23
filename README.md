# BPT2 / Bom Pra Ti

Repositório oficial da reconstrução BPT2 baseada em ABP.

Baseline documentado:
- .NET 10
- ABP 10.6 `app-nolayers`
- Entity Framework Core
- PostgreSQL
- modular monolith com boundaries de Contracts/implementation
- frontend público desacoplado
- sem Redis, broker, search externo, Kubernetes ou microservices por padrão

Arquitetura e decisões: `ARCHITECTURE.md`, `docs/MDV.md` e `docs/adr/`.

Regra epistemológica: uma decisão só é congelada por documentação oficial/código upstream, standard aplicável ou teste executado no BPT2. Inferência/opinião permanece aberta até evidência suficiente.

# BPT2

Materialized from the ABP 10.6 no-layers modular-monolith bootstrap that passed the BPT2 M0/M1 evidence gates.

This directory is product code migrated from the isolated BPT2 work previously held in `igobritoti/bomprati`. BPT1 remains a donor, not the chassis.

Baseline:
- .NET 10
- ABP 10.6 `app-nolayers`
- Entity Framework Core
- PostgreSQL
- modular monolith with Contracts/implementation boundaries
- no Redis, broker, external search, Kubernetes, or microservices by default

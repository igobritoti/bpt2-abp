# BPT2 Architecture

## Baseline

BPT2 é um modular monolith ABP 10.6 em .NET 10 e PostgreSQL. O host executável é a composition root. Módulos de negócio expõem Contracts e mantêm implementação/persistência privadas.

## Ownership

### Catalog
Autoridade canônica sobre Brand, Model, Generation, Version e Vehicle. Fontes externas são inputs de ingestion/enrichment, não fonte de verdade.

### Marketplace
Owns Listing, ListingPhoto, Favorite, Lead e lifecycle de anúncio. Um endpoint público nunca pode retornar Listing que não esteja explicitamente publicável.

### Sellers
Owns perfil/estado do vendedor e contratos públicos necessários ao Marketplace.

### Media
Owns MediaAsset e metadados de storage. Marketplace referencia MediaAssetId, não storage key/provider.

### Ingestion
Owns provenance, confidence, reconciliation/import state e chama Catalog via contracts.

## Boundary rules

1. Host pode referenciar implementações dos módulos.
2. Um módulo de negócio só referencia Contracts de outro módulo.
3. Contracts não dependem de EF/Npgsql/implementações.
4. Catalog é autoridade canônica de identidade automotiva.
5. Frontend não entra nos assemblies de domínio.
6. External side effects exigem coordenação durável quando introduzidos.
7. Infra extra só entra com evidência de necessidade.
8. Antes de experimentar ou construir uma nova capacidade de infraestrutura, avaliar soluções maduras aplicáveis — nativas da plataforma/framework, OSS/self-hosted e/ou gerenciadas — conforme ADR-0010.
9. Adoção de solução existente ou construção customizada de infraestrutura exige decisão durável documentada, incluindo alternativas, boundary, consequências operacionais e estratégia de saída/migração.

O estado formal das decisões fica em `docs/MDV.md` e `docs/adr/`.

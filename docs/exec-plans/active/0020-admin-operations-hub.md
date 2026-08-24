# Execution Plan 0020 — Admin Operations Hub

Status: **ATIVO**

## Objetivo

Fechar o primeiro ponto de entrada comum para as superfícies administrativas já comprovadas no host:

`admin login no host → /admin → Moderação / Ingestão`

## Evidência que abriu o slice

- `PRODUCT.md` mantém administração como capacidade central e um shell administrativo genérico como decisão ainda aberta.
- os Plans 0017 e 0018 já entregaram duas superfícies Razor internas reais no mesmo host: `/moderacao` e `/ingestao`.
- ambas as PageModels usam exatamente `[Authorize(Roles = "admin")]` e reutilizam o Account Web do host.
- `main/BomPraTi/Pages` contém apenas essas duas superfícies operacionais e não possui ponto de entrada administrativo comum.
- Promoções, Buyer Alerts e JSON-LD continuam sem implementação parcial pesquisável; iniciá-los exigiria conceito de produto ou vocabulário novo.
- `scripts/ingestion-candidate-http-smoke.sh` já executa login Account real para anônimo, usuário sem role e admin, permitindo provar o hub sem criar workflow novo.

## Escopo

- adicionar uma Razor Page `/admin` no host existente;
- restringir a página à role `admin`, igual às superfícies que ela agrega;
- apresentar links explícitos para `/moderacao` e `/ingestao` sem consultar nem duplicar regras de negócio;
- ampliar o smoke de Ingestion já existente para provar acesso anônimo, não-admin, admin e links do hub;
- manter as superfícies de Moderação e Ingestão como autoridades dos próprios fluxos.

## Fora de escopo

- menu global do tema ABP ou `IMenuContributor`;
- layout administrativo compartilhado;
- dashboard, métricas, contadores ou novas queries;
- permissões administrativas granulares além da role `admin` atual;
- ações de moderação novas;
- autocomplete/matching/automação de Ingestion;
- novo frontend/admin SPA;
- backend, contrato, schema, migration ou infraestrutura nova.

## Critérios de aceite

1. [ ] anônimo em `/admin` é enviado ao Account Login.
2. [ ] usuário autenticado sem role `admin` é bloqueado.
3. [ ] admin autenticado recebe `/admin` 200 e vê as duas operações existentes.
4. [ ] os links apontam para `/moderacao` e `/ingestao` sem copiar lógica ou dados dessas superfícies.
5. [ ] os boundaries de autorização e comportamento das páginas existentes permanecem intactos.
6. [ ] o gate HTTP focal e os workflows aplicáveis passam no head funcional e no head documental final.
7. [ ] docs fecham somente o hub; menu/layout/dashboard/permissões granulares continuam NÃO DECIDIDOS.

## Checkpoints

- [x] `main` remoto confirmado em `36bb494145796c3ff0e5bf938b692465997cffe2` após o Plan 0019.
- [x] gaps abertos e implementação parcial revalidados.
- [x] branch `feat/admin-operations-hub` criada.
- [ ] abrir draft PR.
- [ ] implementar hub e prova HTTP focal.
- [ ] corrigir somente falhas observadas.
- [ ] fechar docs, exigir CI fresco, review/base refresh e merge verde.

## Decision log

- **DECIDIDO para este slice:** `/admin` é somente composição/navegação das superfícies administrativas existentes; não cria nova autoridade de negócio.
- **DECIDIDO para este slice:** o hub reutiliza a role `admin` já comprovada, sem inaugurar permission model paralelo.
- **NÃO DECIDIDO:** menu global, layout administrativo compartilhado, dashboard/métricas, permissões granulares e frontend admin separado.

## Progress log

- 2026-08-24: `main` remoto confirmado em `36bb494145796c3ff0e5bf938b692465997cffe2` após merge do Plan 0019.
- 2026-08-24: auditoria confirmou duas superfícies admin reais e isoladas, sem hub comum; candidatos Promoções/Alerts/JSON-LD não possuem implementação parcial equivalente.
- 2026-08-24: branch `feat/admin-operations-hub` criada a partir do `main` corrente.

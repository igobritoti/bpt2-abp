# Execution Plan 0018 — Ingestion Admin Surface

Status: **ATIVO**

## Objetivo

Fechar a primeira superfície visual operacional de Ingestion reutilizando o loop já comprovado no Plan 0014:

`candidate externo → fila pendente → admin login no host → /ingestao → reconciliar com Vehicle canônico`

## Evidência que abriu o slice

- `PRODUCT.md` mantém Ingestion como capacidade central e UI de Ingestion como decisão aberta.
- o Plan 0014 já entrega `IIngestionCandidateAppService`, fila pendente, reconciliação para Vehicle canônico e role `admin` com prova HTTP real.
- o Plan 0017 comprovou que uma Razor Page interna no host ABP pode reutilizar Account Web e role `admin` sem novo frontend/OIDC.
- Promoções e Buyer Alerts seguem sem implementação parcial equivalente; enrichment/aggregate pages do Vehicle Hub exigem decisões adicionais.
- portanto a menor extensão real é compor a API de Ingestion existente em uma superfície interna do host, sem alterar domínio ou schema.

## Escopo

- criar `/ingestao` como Razor Page no host ABP;
- restringir a página à role `admin`;
- carregar exclusivamente `IIngestionCandidateAppService.GetPendingAsync`;
- renderizar Source, ExternalId, RawIdentity, Confidence e Provenance;
- permitir informar um `VehicleId` canônico e chamar `ReconcileAsync` para o registro escolhido;
- após reconciliação bem-sucedida, o candidate deixa de aparecer na fila;
- provar anônimo bloqueado, não-admin bloqueado, admin vendo candidate real, Vehicle inexistente rejeitado e Vehicle canônico reconciliado;
- ampliar somente o smoke/workflow de Ingestion já existente.

## Fora de escopo

- connector/source real;
- scraping, polling, scheduler ou background job;
- fuzzy/automatic matching e confidence threshold;
- criação/alteração automática do Catalog;
- workflow multiestado, approval/reject/undo;
- busca/autocomplete de Vehicle na UI;
- shell administrativo genérico;
- novo frontend ou cliente OIDC;
- schema/migration.

## Critérios de aceite

1. [ ] `/ingestao` existe no host; anônimo e usuário sem `admin` não obtêm a fila.
2. [ ] admin autenticado via Account Web vê candidate pendente real e seus campos já persistidos.
3. [ ] formulário de reconcile usa `recordId` do servidor + `VehicleId` informado e não cria autoridade automotiva paralela.
4. [ ] Vehicle inexistente não reconcilia nem remove o candidate da fila.
5. [ ] Vehicle canônico existente reconcilia e o candidate deixa de aparecer na fila.
6. [ ] nenhuma mudança de domínio/schema/migration/cliente OIDC é introduzida.
7. [ ] build e workflows aplicáveis passam; docs finais preservam connector/matching/workflow como NÃO DECIDIDOS.

## Checkpoints

- [x] `main` remoto confirmado em `092475e16e046bc92e13e89aa23cecded66e12b1`.
- [x] backend e gaps de Ingestion revalidados.
- [x] branch `feat/ingestion-admin-surface` criada.
- [ ] abrir draft PR.
- [ ] implementar Razor Page e prova HTTP focal.
- [ ] corrigir somente falhas observadas.
- [ ] fechar docs, exigir CI fresco, review/base refresh e merge verde.

## Decision log

- **DECIDIDO para este slice:** a primeira UI de Ingestion vive no host ABP existente e exige role `admin`.
- **DECIDIDO para este slice:** a UI consome somente `IIngestionCandidateAppService`; Catalog continua sendo validado pelo backend como autoridade canônica.
- **NÃO DECIDIDO:** source/connector, matching automático, threshold, workflow de aprovação, background jobs, autocomplete/busca de Vehicle e shell admin genérico.

## Progress log

- 2026-08-24: `main` remoto confirmado em `092475e16e046bc92e13e89aa23cecded66e12b1` após o Plan 0017.
- 2026-08-24: auditoria confirmou `GetPendingAsync` + `ReconcileAsync` como implementação parcial suficiente e UI de Ingestion como menor gap componível sem novo subsistema.
- 2026-08-24: branch `feat/ingestion-admin-surface` criada a partir do `main` corrente.

# Execution Plan 0043 — Admin Global Navigation

Status: **ATIVO**

## Objetivo

Fechar o gap pós-MVP de `menu global/tema` explicitamente registrado no Plan 0027: disponibilizar no menu principal do host ABP um ponto de entrada para `/admin`, sem criar permissão, layout ou frontend administrativo paralelo.

Vertical proof:

`admin autenticado → menu principal LeptonXLite → Operações → /admin`

## Contexto

Base remota verificada: `9881ba486aa1536fd9680ce884b9e136e7f75874`, após o merge do Plan 0042.

Evidência atual:

- o Plan 0027 classifica `menu global/tema` como gap administrativo pós-MVP;
- o Plan 0020/0042 consolidou `/admin` como hub administrativo autoritativo, mas o host ainda não registra contributor/menu próprio;
- `BomPraTiModule` usa LeptonXLite e não configura `AbpNavigationOptions`;
- a documentação oficial atual do ABP MVC/Razor Pages define `IMenuContributor` + `AbpNavigationOptions` para contribuir ao `StandardMenus.Main`, renderizado pelo tema;
- `ICurrentUser.IsInRole(string)` existe na API atual do ABP e permite espelhar a mesma role `admin` já exigida por `/admin`, `/catalogo`, `/moderacao` e `/ingestao`.

## Escopo

- criar um `IMenuContributor` no host;
- registrar o contributor em `AbpNavigationOptions`;
- adicionar um único item `Operações` para `/admin` no `StandardMenus.Main`;
- renderizar o item somente quando `ICurrentUser.IsInRole("admin")`;
- preservar toda autorização server-side existente das páginas;
- provar por HTTP real que admin vê o link e usuário autenticado sem role admin não vê;
- reutilizar o gate HTTP administrativo existente.

## Fora de escopo

- nova permission/policy;
- submenu por Catálogo/Moderação/Ingestão;
- customização/replacement de layout;
- troca ou fork do tema LeptonXLite;
- frontend admin separado;
- permissões granulares;
- migration/schema/infra;
- novo workflow.

## Critérios de aceite

1. [ ] menu principal do host contém `Operações` → `/admin` para usuário `admin` autenticado.
2. [ ] usuário autenticado sem role `admin` não recebe o item do Bom Pra Ti no menu principal.
3. [ ] `/admin` continua protegida pela role `admin` independentemente do menu.
4. [ ] links operacionais existentes de `/admin` continuam alcançáveis.
5. [ ] implementação usa `IMenuContributor`/`AbpNavigationOptions`, sem override de layout/tema.
6. [ ] nenhuma permission, schema, infra ou autoridade nova é criada.

## Decision log

- **DECIDIDO por evidência:** usar a infraestrutura de navegação do ABP em vez de editar layout do LeptonXLite.
- **DECIDIDO:** um único item aponta ao hub `/admin`; as operações específicas continuam dentro do hub.
- **DECIDIDO:** visibilidade do menu espelha a role `admin` atual via `ICurrentUser.IsInRole("admin")`; permission granular permanece adiada.
- **DECIDIDO:** esconder o menu melhora descoberta, mas não substitui autorização server-side.

## Progress log

- 2026-08-25: `main` remoto confirmado em `9881ba486aa1536fd9680ce884b9e136e7f75874`.
- 2026-08-25: ausência de `IMenuContributor`/`AbpNavigationOptions` confirmada no repositório.
- 2026-08-25: documentação oficial atual do ABP confirmou `IMenuContributor`, `StandardMenus.Main`, `AbpNavigationOptions` e resolução de serviços pelo `MenuConfigurationContext`.
- 2026-08-25: API atual de `ICurrentUser` confirmou `IsInRole(string)`.
